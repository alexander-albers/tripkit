import Foundation

/// ÖBB Personalverkehr AG (AT)
public class OebbProvider: AbstractHafasClientInterfaceProvider {
    
    static let API_BASE = "https://fahrplan.oebb.at/bin/"
    static let PRODUCTS_MAP: [Product?] = [.highSpeedTrain, .highSpeedTrain, .highSpeedTrain, .regionalTrain, .regionalTrain, .suburbanTrain, .bus, .ferry, .subway, .tram, .highSpeedTrain, .onDemand, .highSpeedTrain]
    
    public override var supportedLanguages: Set<String> { ["de"] }
    
    private lazy var dateFormatterDate: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = timeZone
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateFormatter
    }()
    private lazy var dateFormatterTime: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        dateFormatter.timeZone = timeZone
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateFormatter
    }()
    
    public init(apiAuthorization: [String: Any]) {
        super.init(networkId: .OEBB, apiBase: OebbProvider.API_BASE, productsMap: OebbProvider.PRODUCTS_MAP)
        self.apiAuthorization = apiAuthorization
        apiVersion = "1.54"
        apiClient = ["id": "OEBB", "type": "IPH", "name": "oebbADHOC", "v": "6020300"]
        styles = [
            "WESTbahn Management GmbH|I": LineStyle(shape: .rect, backgroundColor: LineStyle.white, foregroundColor: LineStyle.parseColor("#0077b5"), borderColor: LineStyle.parseColor("#0077b5")),
        ]
    }
    
    static let PLACES = ["Wien", "Graz", "Linz/Donau", "Salzburg", "Innsbruck"]
    
    override func split(stationName: String?) -> (String?, String?) {
        guard let stationName = stationName else { return super.split(stationName: nil) }
        for place in OebbProvider.PLACES {
            if stationName.hasPrefix(place + " ") {
                return (place, stationName.substring(from: place.count + 1))
            }
        }
        return super.split(stationName: stationName)
    }
    
    override func split(poi: String?) -> (String?, String?) {
        guard let poi = poi else { return super.split(poi: nil) }
        if let m = poi.match(pattern: P_SPLIT_NAME_FIRST_COMMA) {
            return (m[0], m[1])
        }
        return super.split(poi: poi)
    }
    
    override func split(address: String?) -> (String?, String?) {
        guard let address = address else { return super.split(address: nil) }
        if let m = address.match(pattern: P_SPLIT_NAME_FIRST_COMMA) {
            return (m[0], m[1])
        }
        return super.split(address: address)
    }
    
    override func getWagonSequenceContext(line: Line, departureStop: StopEvent) -> QueryWagonSequenceContext? {
        guard let number = line.number, let stationId = extractLocationId(id: departureStop.location.id) else { return nil }
        return OebbWagonSequenceContext(trainNumber: number, date: departureStop.plannedTime, stationId: stationId)
    }
    
    fileprivate let P_HAFAS_ID = try! NSRegularExpression(pattern: ".*?@(?:L|b)=([^@]+).*@", options: [])

    public func extractLocationId(id: String?) -> String? {
        guard let id = id else { return nil }
        if let matches = id.match(pattern: P_HAFAS_ID), let res = matches[0] {
            return res
        } else {
            return id
        }
    }
    
    public override func queryWagonSequence(context: QueryWagonSequenceContext, completion: @escaping (HttpRequest, QueryWagonSequenceResult) -> Void) -> AsyncRequest {
        guard let context = context as? OebbWagonSequenceContext else {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .invalidId)
            return AsyncRequest(task: nil)
        }
        
        let urlBuilder = UrlBuilder(path: "https://live.oebb.at/backend/info", encoding: .utf8)
        urlBuilder.addParameter(key: "trainNr", value: context.trainNumber)
        urlBuilder.addParameter(key: "station", value: context.stationId)
        urlBuilder.addParameter(key: "date", value: dateFormatterDate.string(from: context.date))
        urlBuilder.addParameter(key: "time", value: dateFormatterTime.string(from: context.date))
        let httpRequest = HttpRequest(urlBuilder: urlBuilder)
        return makeRequest(httpRequest) {
            try self.queryWagonSequenceParsing(request: httpRequest, context: context, completion: completion)
        } errorHandler: { err in
            completion(httpRequest, .failure(err))
        }
    }
    
    override func queryWagonSequenceParsing(request: HttpRequest, context: QueryWagonSequenceContext, completion: @escaping (HttpRequest, QueryWagonSequenceResult) -> Void) throws {
        let json = try getResponse(from: request)
        let lineLabel = json["timeTableInfo", "renderedTrainName"].string
        
        var wagonGroups: [WagonGroup] = []
        var wagons: [Wagon] = []
        var currentDestination: String? = nil
        
        func createNewWagonGroup() {
            if wagons.count > 0 {
                wagonGroups.append(WagonGroup(designation: "", wagons: wagons, destination: currentDestination, lineLabel: lineLabel))
            }
            wagons = []
        }
        
        for jsonWagon in json["train", "wagons"].arrayValue {
            guard let kind = jsonWagon["kind"].int, let number = jsonWagon["ranking"].int, let destination = jsonWagon["destinationName"].string else {
                throw ParseError(reason: "failed to parse wagons")
            }
            let trackPositionStart = wagons.last?.trackPosition.end ?? wagonGroups.last?.wagons.last?.trackPosition.end ?? 0
            let trackPosition = StationTrackSector(sectorName: "", start: trackPositionStart, end: trackPositionStart + jsonWagon["lengthOverBuffers"].doubleValue)
            let loadFactor: LoadFactor?
            switch jsonWagon["numPassengerIcons"].intValue {
            case 1: loadFactor = .low
            case 2: loadFactor = .medium
            case 3: loadFactor = .high
            default: loadFactor = nil
            }
            
            var attributes: [WagonAttributes] = []
            let features = jsonWagon["features"].intValue
            if (features & 1) == 1 || jsonWagon["capacityBicycle"].intValue > 0 {
                attributes.append(WagonAttributes(attribute: .bikeSpace, state: .available))
            }
            if (features & 2) == 2 {
                attributes.append(WagonAttributes(attribute: .wheelchairSpace, state: .available))
            }
            if (features & 8) == 8 {
                // Info point
            }
            if (features & 16) == 16 || (features & 32) == 32 {
                attributes.append(WagonAttributes(attribute: .zoneFamily, state: .available))
            }
            if (features & 64) == 64 {
                attributes.append(WagonAttributes(attribute: .bistro, state: .available))
            }
            if (features & 128) == 128 {
                attributes.append(WagonAttributes(attribute: .zoneQuiet, state: .available))
            }
            if (features & 256) == 256 {
                // Low platform entry
            }
            let isClosed = (features & 512) == 512
            if jsonWagon["capacityCouchette"].intValue > 0 {
                // Liegewagen
            }
            if jsonWagon["capacitySleeper"].intValue > 0 {
                // Schlafwagen
            }
            
            let wagon = Wagon(number: number == 0 ? nil : number, orientation: nil, trackPosition: trackPosition, attributes: attributes, firstClass: jsonWagon["capacityBusinessClass"].intValue + jsonWagon["capacityFirstClass"].intValue > 0, secondClass: jsonWagon["capacitySecondClass"].intValue > 0, loadFactor: loadFactor, isOpen: !isClosed)
            
            if currentDestination != destination {
                currentDestination = destination
                createNewWagonGroup()
                wagons.append(wagon)
            } else if kind != 0 && wagons.count > 0 {
                currentDestination = destination
                wagons.append(wagon)
                createNewWagonGroup()
            } else {
                wagons.append(wagon)
            }
        }
        createNewWagonGroup()
        
        
        var jsonSectors = json["platform", "sectors"].arrayValue
        if json["platform", "stoppingPoint", "position"].string == "Back" {
            jsonSectors = jsonSectors.reversed()
        }
        
        var sectors: [StationTrackSector] = []
        for jsonSector in jsonSectors {
            guard let name = jsonSector["name"].string, let length = jsonSector["length"].double else {
                throw ParseError(reason: "failed to parse platform sectors")
            }
            let start = sectors.count == 0 ? 0 : sectors[sectors.count - 1].end
            sectors.append(StationTrackSector(sectorName: name, start: start, end: start + length))
        }
        
        let track = StationTrack(trackNumber: nil, start: sectors.first?.start ?? 0, end: sectors.last?.end ?? 0, sectors: sectors)
        
        let platformDirection: WagonSequence.TravelDirection = json["platform", "stoppingPoint", "position"].string == "Back" ? .right : .left
        let trainDirection: WagonSequence.TravelDirection = json["platform", "stoppingPoint", "direction"].string == "Back" ? .right : .left
        
        let travelDirection: WagonSequence.TravelDirection = platformDirection == trainDirection ? .left : .right
        completion(request, .success(wagonSequence: WagonSequence(travelDirection: travelDirection, wagonGroups: wagonGroups, track: track)))
    }
    
}

public class OebbWagonSequenceContext: QueryWagonSequenceContext {
    
    public override class var supportsSecureCoding: Bool { return true }
    
    let trainNumber: String
    let date: Date
    let stationId: String
    
    init(trainNumber: String, date: Date, stationId: String) {
        self.trainNumber = trainNumber
        self.date = date
        self.stationId = stationId
        super.init()
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let trainNumber = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.trainNumber) as String? else { return nil }
        guard let date = aDecoder.decodeObject(of: NSDate.self, forKey: PropertyKey.date) as Date? else { return nil }
        guard let stationId = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.stationId) as String? else { return nil }
        self.init(trainNumber: trainNumber, date: date, stationId: stationId)
    }
    
    public override func encode(with aCoder: NSCoder) {
        aCoder.encode(trainNumber, forKey: PropertyKey.trainNumber)
        aCoder.encode(date, forKey: PropertyKey.date)
        aCoder.encode(stationId, forKey: PropertyKey.stationId)
    }
    
    struct PropertyKey {
        static let trainNumber = "trainNumber"
        static let date = "date"
        static let stationId = "stationId"
    }
}
