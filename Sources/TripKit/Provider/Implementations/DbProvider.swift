import Foundation
import SwiftyJSON

/// Deutsche Bahn (DE)
public class DbProvider: AbstractHafasClientInterfaceProvider {
    
    static let API_BASE = "https://reiseauskunft.bahn.de/bin/"
    static let WAGON_SEQUENCE_PATH = "https://app.vendo.noncd.db.de/mob/zuglaeufe/%@/halte/by-abfahrt/%@_%@/wagenreihung"
    static let PRODUCTS_MAP: [Product?] = [
        .highSpeedTrain, // ICE-Züge
        .highSpeedTrain, // Intercity- und Eurocityzüge
        .highSpeedTrain, // Interregio- und Schnellzüge
        .regionalTrain, // Nahverkehr, sonstige Züge
        .suburbanTrain, // S-Bahn
        .bus, // Busse
        .ferry, // Schiffe
        .subway, // U-Bahnen
        .tram, // Straßenbahnen
        .onDemand, // Anruf-Sammeltaxi
        nil, nil, nil, nil]
    lazy var wagonSequenceRequestDateFormatter: DateFormatter = {
        let result = DateFormatter()
        result.locale = Locale(identifier: "en_US_POSIX")
        result.timeZone = timeZone
        result.dateFormat = "yyyy-MM-dd'T'HH:mm:ssxxx"
        return result
    }()
    lazy var correlationID: String = {
        return "\(UUID().uuidString)_\(UUID().uuidString)"
    }()
    let P_EXTRACT_STATION_ID = try! NSRegularExpression(pattern: ".*?@(?:L|b)=([^@]+).*@")
    
    public override var supportedLanguages: Set<String> { ["de", "en", "fr", "es", "it", "nl", "da", "pl", "cs"] }
    public override var supportedQueryTraits: Set<QueryTrait> { Set(Array(super.supportedQueryTraits) + [.tariffTravelerType, .tariffReductions]) }
    /// See https://reiseauskunft.bahn.de/addons/fachkonfig-utf8.cfg
    public override var tariffReductionTypes: [TariffReduction] {
        [
            TariffReduction(title: "Keine Ermäßigung", tariffClass: nil, code: 0),
            TariffReduction(title: "BahnCard 25 1. Kl.", tariffClass: 1, code: 1),
            TariffReduction(title: "BahnCard 25 2. Kl.", tariffClass: 2, code: 2),
            TariffReduction(title: "BahnCard 50 1. Kl.", tariffClass: 1, code: 3),
            TariffReduction(title: "BahnCard 50 2. Kl.", tariffClass: 2, code: 4),
            TariffReduction(title: "BahnCard 100 1. Kl.", tariffClass: 1, code: 16),
            TariffReduction(title: "BahnCard 100 2. Kl.", tariffClass: 2, code: 17),
            TariffReduction(title: "SH-Card", tariffClass: nil, code: 14),
            TariffReduction(title: "AT - VORTEILScard", tariffClass: nil, code: 9),
            TariffReduction(title: "CH - General-Abonnement", tariffClass: nil, code: 15),
            TariffReduction(title: "CH - HalbtaxAbo", tariffClass: nil, code: 10),
            TariffReduction(title: "CH - HalbtaxAbo (ohne RAILPLUS)", tariffClass: nil, code: 11),
            TariffReduction(title: "NL - 40%", tariffClass: nil, code: 12),
            TariffReduction(title: "NL - 40% (ohne RAILPLUS)", tariffClass: nil, code: 13),
        ]
    }
    
    public init(apiAuthorization: [String: Any], requestVerification: AbstractHafasClientInterfaceProvider.RequestVerification) {
        super.init(networkId: .DB, apiBase: DbProvider.API_BASE, productsMap: DbProvider.PRODUCTS_MAP)
        self.apiAuthorization = apiAuthorization
        self.requestVerification = requestVerification
        apiVersion = "1.46"
        apiClient = ["id": "DB", "type": "IPH", "name": "DB Navigator", "v": "20100000"]
        extVersion = "DB.R21.12.a"
        configJson = ["rtMode": "HYBRID"]
    }
    
    let P_SPLIT_NAME_ONE_COMMA = try! NSRegularExpression(pattern: "([^,]*), ([^,]*)")
    
    override func split(stationName: String?) -> (String?, String?) {
        guard let name = stationName else { return (nil, nil) }
        if let match = P_SPLIT_NAME_ONE_COMMA.firstMatch(in: name, options: [], range: NSMakeRange(0, name.count)) {
            let substring1 = (name as NSString).substring(with: match.range(at: 1))
            let substring2 = (name as NSString).substring(with: match.range(at: 2))
            return (substring2, substring1)
        }
        return super.split(stationName: name)
    }
    
    override func split(poi: String?) -> (String?, String?) {
        guard let name = poi else { return (nil, nil) }
        if let match = P_SPLIT_NAME_ONE_COMMA.firstMatch(in: name, options: [], range: NSMakeRange(0, name.count)) {
            let substring1 = (name as NSString).substring(with: match.range(at: 1))
            let substring2 = (name as NSString).substring(with: match.range(at: 2))
            return (substring1, substring2)
        }
        return super.split(poi: name)
    }
    
    override func split(address: String?) -> (String?, String?) {
        guard let name = address else { return (nil, nil) }
        if let match = P_SPLIT_NAME_ONE_COMMA.firstMatch(in: name, options: [], range: NSMakeRange(0, name.count)) {
            let substring1 = (name as NSString).substring(with: match.range(at: 1))
            let substring2 = (name as NSString).substring(with: match.range(at: 2))
            return (substring1, substring2)
        }
        return super.split(address: name)
    }
    
    override func getWagonSequenceContext(line: Line, departureStop: StopEvent) -> QueryWagonSequenceContext? {
        guard let lineLabel = line.name?.replacingOccurrences(of: " ", with: "_") ?? line.label, let stationId = departureStop.location.id, line.product == .highSpeedTrain else {
            return nil
        }
        return DbWagonSequenceContext(lineLabel: lineLabel, stationId: stationId, departureTime: departureStop.plannedTime)
    }
    
    public override func queryWagonSequence(context: QueryWagonSequenceContext, completion: @escaping (HttpRequest, QueryWagonSequenceResult) -> Void) -> AsyncRequest {
        guard let context = context as? DbWagonSequenceContext else {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .invalidId)
            return AsyncRequest(task: nil)
        }
        
        let path = String(format: DbProvider.WAGON_SEQUENCE_PATH, context.lineLabel, extractStationId(from: context.stationId), wagonSequenceRequestDateFormatter.string(from: context.departureTime))
        let urlBuilder = UrlBuilder(path: path, encoding: requestUrlEncoding)
        let headers = [
            "Accept": "application/x.db.vendo.mob.wagenreihung.v3+json",
            "X-Correlation-ID": correlationID
        ]
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder).setHeaders(headers)
        return makeRequest(httpRequest) {
            try self.queryWagonSequenceParsing(request: httpRequest, context: context, completion: completion)
        } errorHandler: { err in
            completion(httpRequest, .failure(err))
        }
    }
    
    private func extractStationId(from stationId: String) -> String {
        if let match = stationId.match(pattern: P_EXTRACT_STATION_ID), let first = match[0]?.emptyToNil {
            return first
        }
        return stationId
    }
    
    override func queryWagonSequenceParsing(request: HttpRequest, context: QueryWagonSequenceContext, completion: @escaping (HttpRequest, QueryWagonSequenceResult) -> Void) throws {
        guard let data = request.responseData else {
            throw ParseError(reason: "failed to parse json from data")
        }
        let json = try JSON(data: data)
        
        /*let state: WagonSequence.State
        switch json["status"].stringValue {
        case "ERROR":                   throw ParseError(reason: json["code"].stringValue)
        case "MATCHES_SCHEDULE":        state = .matchesSchedule
        case "DIFFERS_FROM_SCHEDULE":   state = .differsFromSchedule
        case "NO_SCHEDULE":             state = .noSchedule
        default: throw ParseError(reason: "unknown wagon sequence state")
        }*/
        
        let travelDirection: WagonSequence.TravelDirection?
        switch json["fahrtrichtung"].stringValue {
        case "LINKS":   travelDirection = .left
        case "RECHTS":  travelDirection = .right
        default: travelDirection = nil
        }
        
        var wagonGroups: [WagonGroup] = []
        for wagonGroupJson in json["fahrzeuggruppen"].arrayValue {
            var wagons: [Wagon] = []
            for wagonJson in wagonGroupJson["fahrzeuge"].arrayValue {
                let number = wagonJson["ordnungsnummer"].int
                let wagonOrientation: WagonOrientation?
                switch wagonJson["orientierung"].stringValue {
                case "FORWARDS":    wagonOrientation = .forward
                case "BACKWARDS":   wagonOrientation = .backward
                default:            wagonOrientation = nil
                }
                let trackPosition = try parseTrackSector(from: wagonJson["positionAmGleis"], sectorFieldName: "sektor")
                
                var attributes: [WagonAttributes] = []
                for attributeJson in wagonJson["ausstattungsmerkmale"].arrayValue {
                    let type: WagonAttributes.`Type`
                    switch attributeJson["art"].stringValue {
                    case "BISTRO":                  type = .bistro
                    case "AIR_CONDITION":           type = .airCondition
                    case "BIKE_SPACE":              type = .bikeSpace
                    case "WHEELCHAIR_SPACE":        type = .wheelchairSpace
                    case "TOILET_WHEELCHAIR":       type = .toiletWheelchair
                    case "BOARDING_AID":            type = .boardingAid
                    case "CABIN_INFANT":            type = .cabinInfant
                    case "ZONE_QUIET":              type = .zoneQuiet
                    case "ZONE_FAMILY":             type = .zoneFamily
                    case "SEATS_SEVERELY_DISABLED": type = .seatsSeverelyDisabled
                    case "SEATS_BAHN_COMFORT":      type = .seatsBahnComfort
                    default: continue
                    }
                    
                    let state: WagonAttributes.State
                    switch attributeJson["status"].stringValue {
                    case "AVAILABLE":       state = .available
                    case "NOT_AVAILABLE":   state = .notAvailable
                    case "RESERVED":        state = .reserved
                    default:                state = .undefined
                    }
                    
                    attributes.append(WagonAttributes(attribute: type, state: state))
                }
                
                var firstClass = wagonJson["fahrzeugtyp", "ersteKlasse"].boolValue
                var secondClass = wagonJson["fahrzeugtyp", "zweiteKlasse"].boolValue
                let wagonCategory = wagonJson["fahrzeugtyp", "fahrzeugkategorie"].string
                if wagonCategory == "DININGCAR", !attributes.contains(where: {$0.attribute == .bistro}) {
                    attributes.append(WagonAttributes(attribute: .bistro, state: .undefined))
                } else if wagonCategory == "HALFDININGCAR_FIRST_CLASS" {
                    firstClass = true
                    secondClass = false
                    if !attributes.contains(where: {$0.attribute == .bistro}) {
                        attributes.append(WagonAttributes(attribute: .bistro, state: .undefined))
                    }
                } else if wagonCategory == "HALFDININGCAR_ECONOMY_CLASS" {
                    firstClass = false
                    secondClass = true
                    if !attributes.contains(where: {$0.attribute == .bistro}) {
                        attributes.append(WagonAttributes(attribute: .bistro, state: .undefined))
                    }
                }
                
                wagons.append(Wagon(number: number, orientation: wagonOrientation, trackPosition: trackPosition, attributes: attributes, firstClass: firstClass, secondClass: secondClass, loadFactor: nil))
            }
            if wagons.count == 0 {
                throw ParseError(reason: "did not parse any wagons")
            }
            wagonGroups.append(WagonGroup(designation: wagonGroupJson["bezeichnung"].stringValue, wagons: wagons, destination: wagonGroupJson["fahrtreferenz", "ziel", "bezeichnung"].string, lineLabel: "\(wagonGroupJson["fahrtreferenz", "gattung"].stringValue)\(wagonGroupJson["fahrtreferenz", "fahrtnummer"].stringValue)".emptyToNil))
        }
        if wagonGroups.count == 0 {
            throw ParseError(reason: "did not parse any wagon groups")
        }
        
        let trackJson = json["gleis"]
        let stationTrackInfo = try parseTrackSector(from: trackJson)
        var sectors: [StationTrackSector] = []
        for sectorJson in trackJson["sektoren"].arrayValue {
            sectors.append(try parseTrackSector(from: sectorJson))
        }
        let stationTrack = StationTrack(trackNumber: stationTrackInfo.sectorName, start: stationTrackInfo.start, end: stationTrackInfo.end, sectors: sectors)
        
        let wagonSequence = WagonSequence(travelDirection: travelDirection, wagonGroups: wagonGroups, track: stationTrack)
        completion(request, .success(wagonSequence: wagonSequence))
    }
    
    private func parseTrackSector(from trackJson: JSON, sectorFieldName: String = "bezeichnung") throws -> StationTrackSector {
        guard let trackStart = trackJson["start"]["position"].double, let trackEnd = trackJson["ende"]["position"].double else {
            throw ParseError(reason: "failed to parse track sector")
        }
        let sectorName = trackJson[sectorFieldName].stringValue
        return StationTrackSector(sectorName: sectorName, start: trackStart, end: trackEnd)
    }
    
    public enum TrainType {
        case ICE1, ICE2, ICE3, ICE3BR406, ICE3BR407, ICE3NEOBR408, ICET, ICET_5, ICE4, ICE4_7, ICE4_XXL, IC2BOMBARDIER, IC2STADLER, ICE3EUROPE, ICE3PRIDE, ICE4GERMANY, ICE4HANDBALL, ICE4FOOTBALL
        
        public static func parse(from vehicleNumber: String) -> TrainType? {
            if vehicleNumber.hasPrefix("ICE0304") {
                return .ICE3PRIDE
            }
            if vehicleNumber.hasPrefix("ICE4601") {
                return .ICE3EUROPE
            }
            if vehicleNumber.hasPrefix("ICE9457") {
                return .ICE4GERMANY
            }
            if vehicleNumber.hasPrefix("ICE9201") {
                return .ICE4HANDBALL
            }
            if vehicleNumber.hasPrefix("ICE9212") {
                return .ICE4FOOTBALL
            }
            if vehicleNumber.hasPrefix("ICE01") {
                return .ICE1
            }
            if vehicleNumber.hasPrefix("ICE90") {
                return .ICE4
            }
            if vehicleNumber.hasPrefix("ICE92") {
                return .ICE4_7
            }
            if vehicleNumber.hasPrefix("ICE94") || vehicleNumber.hasPrefix("ICE950") {
                return .ICE4_XXL
            }
            if vehicleNumber.hasPrefix("ICK41") {
                return .IC2STADLER
            }
            if vehicleNumber.hasPrefix("ICE11") {
                return .ICET
            }
            if vehicleNumber.hasPrefix("ICE15") {
                return .ICET_5
            }
            if vehicleNumber.hasPrefix("ICE47") {
                return .ICE3BR407
            }
            if vehicleNumber.hasPrefix("ICE46") {
                return .ICE3BR406
            }
            if vehicleNumber.hasPrefix("ICE03") {
                return .ICE3
            }
            if vehicleNumber.hasPrefix("ICE02") {
                return .ICE2
            }
            if vehicleNumber.hasPrefix("ICD28") || vehicleNumber.hasPrefix("ICD48") {
                return .IC2BOMBARDIER
            }
            if vehicleNumber.hasPrefix("ICE80") {
                return .ICE3NEOBR408
            }
            return nil
        }
    }
    
}

public class DbWagonSequenceContext: QueryWagonSequenceContext {
    
    public override class var supportsSecureCoding: Bool { return true }
    
    public let lineLabel: String
    public let stationId: String
    public let departureTime: Date
    
    public init(lineLabel: String, stationId: String, departureTime: Date) {
        self.lineLabel = lineLabel
        self.stationId = stationId
        self.departureTime = departureTime
        super.init()
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard
            let lineLabel = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.lineLabel) as String?,
            let stationId = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.stationId) as String?,
            let departureTime = aDecoder.decodeObject(of: NSDate.self, forKey: PropertyKey.departureTime) as Date?
        else { return nil }
        self.init(lineLabel: lineLabel, stationId: stationId, departureTime: departureTime)
    }
    
    public override func encode(with aCoder: NSCoder) {
        aCoder.encode(lineLabel, forKey: PropertyKey.lineLabel)
        aCoder.encode(stationId, forKey: PropertyKey.stationId)
        aCoder.encode(departureTime, forKey: PropertyKey.departureTime)
    }
    
    struct PropertyKey {
        static let lineLabel = "lineLabel"
        static let stationId = "stationId"
        static let departureTime = "departureTime"
    }
}

