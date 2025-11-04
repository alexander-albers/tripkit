import Foundation
import SwiftyJSON

/// Deutsche Bahn (DE)
public class DbProvider: AbstractNetworkProvider {
    
    static let API_BASE = "https://app.services-bahn.de/mob/"
    
    lazy var dateFormatter: DateFormatter = {
        let result = DateFormatter()
        result.locale = Locale(identifier: "en_US_POSIX")
        result.timeZone = timeZone
        result.dateFormat = "yyyy-MM-dd"
        return result
    }()
    lazy var timeFormatter: DateFormatter = {
        let result = DateFormatter()
        result.locale = Locale(identifier: "en_US_POSIX")
        result.timeZone = timeZone
        result.dateFormat = "HH:mm"
        return result
    }()
    lazy var isoDateFormatter: DateFormatter = {
        let result = DateFormatter()
        result.locale = Locale(identifier: "en_US_POSIX")
        result.timeZone = timeZone
        result.dateFormat = "yyyy-MM-dd'T'HH:mm:ssxxx"
        return result
    }()
    lazy var correlationID: String = {
        return "\(UUID().uuidString)_\(UUID().uuidString)"
    }()
    
    let requestUrlEncoding: String.Encoding = .utf8
    
    public override var supportedLanguages: Set<String> { ["de", "en", "fr", "es", "it", "nl", "da", "pl", "cs"] }
    public override var supportedQueryTraits: Set<QueryTrait> { [.maxChanges, .minChangeTime, .tariffClass, .tariffTravelerType, .tariffReductions] }
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
            TariffReduction(title: "BahnCard Business 25 1. Kl.", tariffClass: 1, code: 21),
            TariffReduction(title: "BahnCard Business 25 2. Kl.", tariffClass: 2, code: 22),
            TariffReduction(title: "BahnCard Business 50 1. Kl.", tariffClass: 1, code: 23),
            TariffReduction(title: "BahnCard Business 50 2. Kl.", tariffClass: 2, code: 24),
            
            TariffReduction(title: "AT - VORTEILScard", tariffClass: nil, code: 9),
            TariffReduction(title: "AT - KlimaTicket", tariffClass: nil, code: 19),
            TariffReduction(title: "CH - General-Abonnement 1. Kl.", tariffClass: nil, code: 31),
            TariffReduction(title: "CH - General-Abonnement 2. Kl.", tariffClass: nil, code: 32),
            TariffReduction(title: "CH - HalbtaxAbo", tariffClass: nil, code: 11),
            TariffReduction(title: "NL - 40%", tariffClass: nil, code: 13),
        ]
    }
    
    private static let TARIFF_REDUCTION_MAP: [Int: String] = [
        0: "KEINE_ERMAESSIGUNG KLASSENLOS",
        1: "BAHNCARD25 KLASSE_1",
        2: "BAHNCARD25 KLASSE_2",
        3: "BAHNCARD50 KLASSE_1",
        4: "BAHNCARD50 KLASSE_2",
        16: "BAHNCARD100 KLASSE_1",
        17: "BAHNCARD100 KLASSE_2",
        21: "BAHNCARDBUSINESS25 KLASSE_1",
        22: "BAHNCARDBUSINESS25 KLASSE_2",
        23: "BAHNCARDBUSINESS50 KLASSE_1",
        24: "BAHNCARDBUSINESS50 KLASSE_2",
        9: "A-VORTEILSCARD KLASSENLOS",
        31: "CH-GENERAL-ABONNEMENT KLASSE_1",
        32: "CH-GENERAL-ABONNEMENT KLASSE_2",
        11: "CH-HALBTAXABO_OHNE_RAILPLUS KLASSENLOS",
        13: "NL-40_OHNE_RAILPLUS KLASSENLOS",
        19: "KLIMATICKET_OE KLASSENLOS"
    ]
    
    private static let TRAVELER_TYPE_MAP: [TravelerType: String] = [
        .adult: "ERWACHSENER",
        .youngAdult: "JUGENDLICHER",
        .child: "FAMILIENKIND",
        .youngChild: "KLEINKND",
        .senior: "SENIOR"
    ]
    
    private static let PRODUCTS_MAP: [String: Product] = [
        "HOCHGESCHWINDIGKEITSZUEGE": .highSpeedTrain,
        "INTERCITYUNDEUROCITYZUEGE": .highSpeedTrain,
        "INTERREGIOUNDSCHNELLZUEGE": .highSpeedTrain,
        "NAHVERKEHRSONSTIGEZUEGE": .regionalTrain,
        "SBAHNEN": .suburbanTrain,
        "BUSSE": .bus,
        "SCHIFFE": .ferry,
        "UBAHN": .subway,
        "STRASSENBAHN": .tram,
        "ANRUFPFLICHTIGEVERKEHRE": .onDemand,
    ]
    
    private static let SHORT_PRODUCTS_MAP: [String: Product] = [
        "ICE": .highSpeedTrain,
        "IC_EC": .highSpeedTrain,
        "IC": .highSpeedTrain,
        "EC": .highSpeedTrain,
        "IR": .highSpeedTrain,
        "RB": .regionalTrain,
        "RE": .regionalTrain,
        "SBAHN": .suburbanTrain,
        "BUS": .bus,
        "SCHIFF": .ferry,
        "UBAHN": .subway,
        "STR": .tram,
        "ANRUFPFLICHTIGEVERKEHRE": .onDemand,
    ]
    
    private static let ID_LOCATION_TYPE_MAP: [String: LocationType] = [
        "1": .station,
        "2": .address,
        "4": .poi,
    ]
    
    private static let LOCATION_TYPE_MAP: [LocationType: String] = [
        .any: "ALL",
        .station: "ST",
        .address: "ADR",
        .poi: "POI",
    ]
    
    private static let DEFAULT_MAX_DEPARTURES = 100
    private static let DEFAULT_MAX_LOCATIONS = 50
    private static let DEFAULT_MAX_DISTANCE = 10000
    
    private static let P_SPLIT_NAME_FIRST_COMMA = try! NSRegularExpression(pattern: "([^,]*), (.*)")
    private static let P_SPLIT_NAME_ONE_COMMA = try! NSRegularExpression(pattern: "([^,]*), ([^,]*)")
    private static let P_EXTRACT_STATION_ID = try! NSRegularExpression(pattern: ".*?@(?:L|b)=([^@]+).*@")
    
    public init() {
        super.init(networkId: .DB)
    }
    
    private func createLidEntry(key: String, value: Any?) -> String {
        guard let value = value else { return "" }
        return "\(key)=\(value)@"
    }
    
    private func formatLid(from location: Location) -> String {
        if let id = location.id, id.hasPrefix("A=") && id.contains("@") {
            return id
        }
        
        var result = ""
        
        let typeId = DbProvider.ID_LOCATION_TYPE_MAP.enumerated().first(where: {$0.element.value == location.type})?.element.key ?? "0"
        result += createLidEntry(key: "A", value: typeId)
        if let name = location.name {
            result += createLidEntry(key: "O", value: name)
        }
        if let coord = location.coord {
            result += createLidEntry(key: "X", value: coord.lon)
            result += createLidEntry(key: "X", value: coord.lat)
        }
        if let id = location.id {
            result += createLidEntry(key: "L", value: normalize(stationId: id))
        }
        
        return result
    }
    
    private func formatLid(stationId: String) -> String {
        return formatLid(from: Location(id: stationId))
    }
    
    private func parseLid(from loc: String?) -> Location? {
        guard let loc else { return nil }
        let props = loc.split(separator: "@").map({$0.split(separator: "=")}).filter({$0.count == 2}).reduce(into: [:], { $0[$1[0]] = String($1[1]) })
        
        let locationPoint: LocationPoint?
        if let lat = Int(props["y"] ?? ""), let lon = Int(props["x"] ?? "") {
            locationPoint = LocationPoint(lat: lat, lon: lon)
        } else {
            locationPoint = nil
        }
        
        return Location(type: DbProvider.ID_LOCATION_TYPE_MAP[props["A"] ?? ""] ?? .any, id: props["L"], coord: locationPoint, place: nil, name: props["O"])
    }
    
    private func extractStationId(from stationId: String?) -> String? {
        guard let stationId = stationId else { return nil }
        if let match = stationId.match(pattern: DbProvider.P_EXTRACT_STATION_ID), let first = match[0]?.emptyToNil {
            return first
        }
        return stationId
    }
    
    private func formatProducts(products: [Product]?) -> [String] {
        guard let products else { return ["ALL"]}
        return products
                .flatMap { p in DbProvider.PRODUCTS_MAP.enumerated().filter({$0.element.value == p}) }
                .map { "\($0.element.key)" }
    }
                                                                        
    private func parseProducts(from json: JSON) -> [Product]? {
        var result: [Product] = []
        for jsonProduct in json.arrayValue {
            if let p = DbProvider.PRODUCTS_MAP[jsonProduct.stringValue] {
                result.append(p)
            }
        }
        return result
    }
    
    private func format(locationTypes types: [LocationType]?) -> [String] {
        guard let types, !types.contains(.any) else {
            return ["\(DbProvider.LOCATION_TYPE_MAP[.any]!)"]
        }
        return types.compactMap({DbProvider.LOCATION_TYPE_MAP[$0]}).map({"\($0)"})
    }
    
    private func split(placeAndName: String?, pattern: NSRegularExpression, place: Int, name: Int) -> (place: String?, name: String?)? {
        guard let placeAndName else { return nil }
        if let m = placeAndName.match(pattern: pattern), m.count == 2 {
            return (m[place], m[name])
        } else {
            return (nil, placeAndName)
        }
    }
    
    private func split(stationName: String?) -> (place: String?, name: String?)? {
        return split(placeAndName: stationName, pattern: DbProvider.P_SPLIT_NAME_ONE_COMMA, place: 1, name: 0)
    }
    
    private func split(address: String?) -> (place: String?, name: String?)? {
        return split(placeAndName: address, pattern: DbProvider.P_SPLIT_NAME_FIRST_COMMA, place: 0, name: 1)
    }
    
    private func parse(location json: JSON) -> Location? {
        let lidString = json["locationId"].string
        guard let lid = parseLid(from: lidString) else { return nil }
        // always use long id...
        let shortId = lid.type == .station ? json["evaNr"].string ?? lid.id : lidString
        let coord: LocationPoint?
        let jsonPos = json["coordinates"].exists() ? json["coordinates"] : json["position"]
        if jsonPos.exists(), let lat = jsonPos["latitude"].double, let lon = jsonPos["longitude"].double {
            coord = LocationPoint(lat: Int(lat * 1e6), lon: Int(lon * 1e6))
        } else {
            coord = nil
        }
        
        return parse(locationType: lid.type, id: lidString, shortId: shortId, coord: coord, name: json["name"].string, products: parseProducts(from: json["products"]))
    }
    
    private func parse(locationType: LocationType, id: String?, shortId: String?, coord: LocationPoint?, name: String?, products: [Product]?) -> Location? {
        // For addresses and Swiss locations (ids starting wiht 85), the place and name are reversed
        let placeAndName = locationType == .station && (shortId?.hasPrefix("85") ?? false == false) ? split(stationName: name) : split(address: name)
        return Location(type: locationType, id: id, coord: coord, place: placeAndName?.place, name: placeAndName?.name, products: products)
    }
    
    private func parse(direction json: JSON) -> Location? {
        guard let direction = json["richtung"].string else { return nil }
        return Location(anyName: direction)
    }
    
    private func parse(locationList json: JSON) -> [Location] {
        var result: [Location] = []
        for jsonLoc in json.arrayValue {
            if let location = parse(location: jsonLoc) {
                result.append(location)
            }
        }
        return result
    }
    
    private func parse(messages json: JSON, result: inout [String], minPriority: Int?) {
        guard json.exists() else { return }
        for jsonMessage in json.arrayValue {
            guard let text = jsonMessage["text"].string else { continue }
            if let minPriority, jsonMessage["priority"].int ?? minPriority >= minPriority {
                continue
            }
            result.append(text)
        }
    }
    
    private func parse(attributes json: JSON) -> [Line.Attr]? {
        var result = Set<Line.Attr>()
        for jsonAttribute in json["attributNotizen"].arrayValue {
            switch jsonAttribute["key"].stringValue.lowercased() {
            case "fr", "fb": // Fahrradmitnahme
                result.insert(.bicycleCarriage)
            case "br", "bt": // Bordrestaurant
                result.insert(.restaurant)
            case "bf", "rg", "eh", "bg", "op", "be", "re":
                result.insert(.wheelChairAccess)
            case "wv", "wi":
                result.insert(.wifiAvailable)
            case "kl", "rc":
                result.insert(.airConditioned)
            case "ls", "ri":
                result.insert(.powerSockets)
            default:
                break
            }
        }
        return result.count == 0 ? nil : Array(result)
    }
    
    private func parse(messages json: JSON) -> String? {
        var result: [String] = []
        parse(messages: json["echtzeitNotizen"], result: &result, minPriority: nil)
        parse(messages: json["himNotizen"], result: &result, minPriority: nil)
        return result.isEmpty ? nil : result.joined(separator: "\n")
    }
    
    private func parse(line json: JSON) -> Line {
        let product = DbProvider.SHORT_PRODUCTS_MAP[json["produktGattung"].stringValue]
        let name = json["langtext"].string ?? json["mitteltext"].string
        var shortName = json["mitteltext"].string
        if let s = shortName, product == .bus || product == .tram {
            shortName = s.replacingOccurrences(of: "^[A-Za-z]+ ", with: "", options: [.regularExpression])
        }
        let attr = parse(attributes: json)
        return Line(id: json["zuglaufId"].string, network: nil, product: product, label: shortName?.replacingOccurrences(of: " ", with: ""), name: name, number: nil, vehicleNumber: json["verkehrsmittelNummer"].string, style: lineStyle(network: nil, product: product, label: name), attr: attr, message: nil)
    }
    
    private func parseCancelled(stop json: JSON) -> Bool {
        let cancelled = json["cancelled"].boolValue
        if cancelled {
            return true
        }
        if let notices = json["echtzeitNotizen"].array {
            for notice in notices {
                guard let text = notice["text"].string else { continue }
                if text == "Halt entfällt" || text == "Stop cancelled" {
                    return true
                }
            }
        }
        return false
    }
    
    private func parse(stop json: JSON, fallbackLocation: Location?) -> Stop? {
        let gleis = parsePosition(position: json["gleis"].string)
        let ezGleis = parsePosition(position: json["ezGleis"].string)
        let cancelled = parseCancelled(stop: json)
        guard let location = parse(location: json["ort"]) ?? fallbackLocation else { return nil }
        
        let departure: StopEvent?
        let arrival: StopEvent?
        
        if let plannedTimeString = json["abgangsDatum"].string, let plannedTime = isoDateFormatter.date(from: plannedTimeString) {
            departure = StopEvent(location: location, plannedTime: plannedTime, predictedTime: isoDateFormatter.date(from: correctRealtimeTimezone(plannedTime: plannedTimeString, predictedTime: json["ezAbgangsDatum"].stringValue)), plannedPlatform: gleis, predictedPlatform: ezGleis, cancelled: cancelled)
        } else {
            departure = nil
        }
        
        if let plannedTimeString = json["ankunftsDatum"].string, let plannedTime = isoDateFormatter.date(from: plannedTimeString) {
            arrival = StopEvent(location: location, plannedTime: plannedTime, predictedTime: isoDateFormatter.date(from: correctRealtimeTimezone(plannedTime: plannedTimeString, predictedTime: json["ezAnkunftsDatum"].stringValue)), plannedPlatform: gleis, predictedPlatform: ezGleis, cancelled: cancelled)
        } else {
            arrival = nil
        }
        return Stop(location: location, departure: departure, arrival: arrival, message: nil)
    }
    
    private static let P_timeZoneOffsetPattern = try! NSRegularExpression(pattern: "([+-]\\d\\d:\\d\\d|Z)")
    // see: https://github.com/public-transport/db-vendo-client/issues/24
    private func correctRealtimeTimezone(plannedTime: String, predictedTime: String) -> String {
        if predictedTime.isEmpty {
            return predictedTime
        }
        
        guard let match = plannedTime.match(pattern: DbProvider.P_timeZoneOffsetPattern), let timezoneOffsetPlanned = match[0] else {
            return predictedTime
        }
        
        // use same timezone for predicted time as for planned time
        return DbProvider.P_timeZoneOffsetPattern.stringByReplacingMatches(in: predictedTime, range: NSRange(predictedTime.startIndex..., in: predictedTime), withTemplate: timezoneOffsetPlanned)
    }
    
    private func parse(stops json: JSON) -> [Stop]? {
        guard !json.arrayValue.isEmpty else {
            return nil
        }
        var result: [Stop] = []
        for stopJson in json.arrayValue {
            guard let stop = parse(stop: stopJson, fallbackLocation: nil) else { continue }
            result.append(stop)
        }
        return result
    }
    
    private func parse(loadFactors json: JSON) -> (first: LoadFactor?, second: LoadFactor?) {
        var first: LoadFactor?
        var second: LoadFactor?
        for capacityJson in json["auslastungsInfos"].arrayValue {
            let className = capacityJson["klasse"].string
            let loadFactorInt = capacityJson["stufe"].intValue
            let loadFactor: LoadFactor?
            switch loadFactorInt {
            case 1: loadFactor = .low
            case 2: loadFactor = .medium
            case 3: loadFactor = .high
            case 4: loadFactor = .exceptional
            default: loadFactor = nil
            }
            if className == "KLASSE_2" {
                second = loadFactor
            } else {
                first = loadFactor
            }
        }
        return (first, second)
    }
    
    private func parse(leg json: JSON, tariffClass: Int) throws -> Leg? {
        var departureStop: Stop?
        var arrivalStop: Stop?
        
        let legType = json["typ"].string ?? "FAHRZEUG"
        let isPublicTransportLeg = legType == "FAHRZEUG"
        var intermediateStops = parse(stops: json["halte"]) ?? []
        if intermediateStops.count >= 2, isPublicTransportLeg {
            departureStop = intermediateStops.removeFirst()
            arrivalStop = intermediateStops.removeLast()
        } else {
            departureStop = parse(stop: json, fallbackLocation: parse(location: json["abgangsOrt"]))
            arrivalStop = parse(stop: json, fallbackLocation: parse(location: json["ankunftsOrt"]))
        }
        
        guard let departure = departureStop?.departure, let arrival = arrivalStop?.arrival else {
            throw ParseError(reason: "failed to parse departure/arrival stop")
        }
        
        let path = parse(polyline: json)
        
        if isPublicTransportLeg {
            let line = parse(line: json)
            let destination = parse(direction: json)
            let message = parse(messages: json)
            let loadFactor = parse(loadFactors: json)
            return PublicLeg(line: line, destination: destination, departure: departure, arrival: arrival, intermediateStops: intermediateStops, message: message, path: path, journeyContext: parse(journeyContext: json), wagonSequenceContext: parse(wagonSequenceContext: json), loadFactor: tariffClass == 1 ? loadFactor.first : loadFactor.second)
        } else {
            let distance = json["distanz"].intValue
            let type: IndividualLeg.`Type` = legType == "TRANSFER" ? .transfer : .walk
            if type == .walk && json["produktGattung"].stringValue != "SONSTIGE" {
                return nil  // don't parse wait times between public legs as individual leg
            }
            return IndividualLeg(type: type, departureTime: departure.time, departure: departure.location, arrival: arrival.location, arrivalTime: arrival.time, distance: distance, path: path)
        }
    }
    
    private func parse(polyline json: JSON) -> [LocationPoint] {
        var result: [LocationPoint] = []
        for jsonCoordinate in json["polylineGroup", "polylineDesc", 0, "coordinates"].arrayValue {
            guard let latitude = jsonCoordinate["latitude"].double, let longitude = jsonCoordinate["longitude"].double else { continue }
            result.append(LocationPoint(lat: Int(latitude * 1e6), lon: Int(longitude * 1e6)))
        }
        return result
    }
    
    private func parse(trip jsonTrip: JSON, tariffClass: Int, fares: [Fare]) throws -> Trip {
        let jsonLegs = jsonTrip["verbindungsAbschnitte"].arrayValue
        
        var legs: [Leg] = []
        var tripFrom: Location?
        var tripTo: Location?
        
        for (i, jsonLeg) in jsonLegs.enumerated() {
            guard let leg = try parse(leg: jsonLeg, tariffClass: tariffClass) else { continue }
            legs.append(leg)
            
            if i == 0 {
                tripFrom = leg.departure
            }
            if i == jsonLegs.count - 1 {
                tripTo = leg.arrival
            }
        }
        
        guard let tripFrom, let tripTo else {
            throw ParseError(reason: "failed to parse trip from/to")
        }
        
        let refreshContext: RefreshTripContext?
        if let context = jsonTrip["kontext"].string {
            refreshContext = DbRefreshTripContext(contextRecon: context)
        } else {
            refreshContext = nil
        }
        
        return Trip(id: jsonTrip["kontext"].string?.components(separatedBy: "#").first ?? "", from: tripFrom, to: tripTo, legs: legs, duration: TimeInterval(jsonTrip["reiseDauer"].intValue), fares: fares, refreshContext: refreshContext)
    }
    
    private func parse(journeyContext json: JSON) -> DbJourneyContext? {
        let journeyContext: DbJourneyContext?
        if let journeyId = json["zuglaufId"].string {
            journeyContext = DbJourneyContext(journeyId: journeyId)
        } else {
            journeyContext = nil
        }
        return journeyContext
    }
    
    private func parse(wagonSequenceContext json: JSON) -> DbWagonSequenceContext? {
        let wagonSequenceContext: DbWagonSequenceContext?
        guard json["wagenreihung"].boolValue else { return nil }
        if let lineLabel = json["risZuglaufId"].string, let departureId = json["risAbfahrtId"].string {
            wagonSequenceContext = DbWagonSequenceContext(lineLabel: lineLabel, departureId: departureId)
        } else {
            wagonSequenceContext = nil
        }
        return wagonSequenceContext
    }
    
    private func parse(fares json: JSON) -> [Fare] {
        let ab = json["angebote", "preise", "gesamt", "ab"]
        if ab.exists() {
            return [Fare(name: "Ticket", type: .adult, currency: ab["waehrung"].string ?? "EUR", fare: ab["betrag"].floatValue, unitsName: nil, units: nil)]
        } else {
            return []
        }
    }
    
    private func parse(errorCode json: JSON) -> String? {
        let details = json["details"]
        let code = json["code"].string
        if details.exists() {
            return details["typ"].string ?? code
        } else {
            return code
        }
    }
    
    private func createHttpRequest(for path: String, contentType: String, content: [String: Any]?) -> HttpRequest {
        let path = DbProvider.API_BASE + path
        let urlBuilder = UrlBuilder(path: path, encoding: requestUrlEncoding)
        let headers = [
            "Accept": contentType,
            "Content-Type": contentType,
            "X-Correlation-ID": correlationID
        ]
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder).setHeaders(headers)
        if let content {
            httpRequest.setPostPayload(encodeJson(dict: content, requestUrlEncoding: requestUrlEncoding))
        }
        return httpRequest
    }
    
    private func validateResponse(with data: Data?) throws -> JSON {
        guard let data = data else {
            throw ParseError(reason: "failed to parse json from data")
        }
        let json = try JSON(data: data)
        return json
    }
    
    public override func suggestLocations(constraint: String, types: [LocationType]?, maxLocations: Int, completion: @escaping (HttpRequest, SuggestLocationsResult) -> Void) -> AsyncRequest {
        let request: [String: Any] = [
            "searchTerm": constraint,
            "locationTypes": format(locationTypes: types),
            "maxResults": maxLocations == 0 ? DbProvider.DEFAULT_MAX_LOCATIONS : maxLocations
        ]
        
        let httpRequest = createHttpRequest(for: "location/search", contentType: "application/x.db.vendo.mob.location.v3+json", content: request)
        return makeRequest(httpRequest) {
            try self.suggestLocationsParsing(request: httpRequest, constraint: constraint, types: types, maxLocations: maxLocations, completion: completion)
        } errorHandler: { err in
            completion(httpRequest, .failure(err))
        }
    }
    
    override func suggestLocationsParsing(request: HttpRequest, constraint: String, types: [LocationType]?, maxLocations: Int, completion: @escaping (HttpRequest, SuggestLocationsResult) -> Void) throws {
        let json = try validateResponse(with: request.responseData)
        var result: [SuggestedLocation] = []
        
        for (i, jsonLocation) in json.arrayValue.enumerated() {
            if let location = parse(location: jsonLocation) {
                result.append(SuggestedLocation(location: location, priority: jsonLocation["weight"].int ?? -i))
            }
        }
        // Don't sort by priority to keep same order as in DB Navigator
        //result.sort(by: {$0.priority > $1.priority})
        
        completion(request, .success(locations: result))
    }
    
    public override func queryNearbyLocations(location: Location, types: [LocationType]?, maxDistance: Int, maxLocations: Int, completion: @escaping (HttpRequest, NearbyLocationsResult) -> Void) -> AsyncRequest {
        guard let coord = location.coord else {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .invalidId)
            return AsyncRequest(task: nil)
        }
        
        let request: [String: Any] = [
            "area": [
                "coordinates": [
                    "latitude": Double(coord.lat) / 1e6,
                    "longitude": Double(coord.lon) / 1e6
                ],
                "radius": maxDistance == 0 ? DbProvider.DEFAULT_MAX_DISTANCE : maxDistance,
            ],
            "maxResults": maxLocations == 0 ? DbProvider.DEFAULT_MAX_LOCATIONS : maxLocations,
            "products": ["ALL"],
            "types": (types ?? [.any]).map({DbProvider.LOCATION_TYPE_MAP[$0]}),
            "operatingSystem": "IOS"
        ]
        
        let httpRequest = createHttpRequest(for: "location/nearby/bytypes", contentType: "application/x.db.vendo.mob.location.v3+json", content: request)
        return makeRequest(httpRequest) {
            try self.queryNearbyLocationsByCoordinateParsing(request: httpRequest, location: location, types: types, maxDistance: maxDistance, maxLocations: maxLocations, completion: completion)
        } errorHandler: { err in
            completion(httpRequest, .failure(err))
        }
    }
    
    override func queryNearbyLocationsByCoordinateParsing(request: HttpRequest, location: Location, types: [LocationType]?, maxDistance: Int, maxLocations: Int, completion: @escaping (HttpRequest, NearbyLocationsResult) -> Void) throws {
        let json = try validateResponse(with: request.responseData)
        var result: [Location] = []
        
        for jsonLocation in json["fahrplanAuskunftLocations"].arrayValue {
            if let location = parse(location: jsonLocation), types == nil || types?.contains(location.type) ?? false || types?.contains(.any) ?? false {
                result.append(location)
            }
        }
        
        completion(request, .success(locations: result))
    }
    
    private func findAddressByCoord(location: Location, completion: @escaping (HttpRequest, NearbyLocationsResult) -> Void) -> AsyncRequest {
        guard let coord = location.coord else {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .invalidId)
            return AsyncRequest(task: nil)
        }
        
        let request: [String: Any] = [
            "area": [
                "coordinates": [
                    "latitude": Double(coord.lat) / 1e6,
                    "longitude": Double(coord.lon) / 1e6
                ],
                "radius": 1000,
            ],
            "maxResults": 1,
            "products": ["ALL"]
        ]
        
        let httpRequest = createHttpRequest(for: "location/search", contentType: "application/x.db.vendo.mob.location.v3+json", content: request)
        return makeRequest(httpRequest) {
            try self.findAddressByCoordParsing(request: httpRequest, location: location, completion: completion)
        } errorHandler: { err in
            completion(httpRequest, .failure(err))
        }
    }
    
    private func findAddressByCoordParsing(request: HttpRequest, location: Location, completion: @escaping (HttpRequest, NearbyLocationsResult) -> Void) throws {
        let json = try validateResponse(with: request.responseData)
        var result: [Location] = []
        
        for jsonLocation in json.arrayValue {
            if let location = parse(location: jsonLocation) {
                result.append(location)
            }
        }
        
        completion(request, .success(locations: result))
    }
    
    public override func queryTrips(from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        return doQueryTrips(from: from, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions, previousContext: nil, later: false, completion: completion)
    }
    
    private func doQueryTrips(from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions, previousContext: Context?, later: Bool, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        if from.type == .coord {
            let request = AsyncRequest(task: nil)
            request.task = findAddressByCoord(location: from) { _, result in
                switch result {
                case .success(let locations):
                    guard let from = locations.first else {
                        completion(HttpRequest(urlBuilder: UrlBuilder()), .unknownFrom)
                        return
                    }
                    request.task = self.doQueryTrips(from: from, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions, previousContext: previousContext, later: later, completion: completion).task
                default:
                    completion(HttpRequest(urlBuilder: UrlBuilder()), .unknownFrom)
                }
            }.task
            return request
        }
        if let via = via, via.type == .coord {
            let request = AsyncRequest(task: nil)
            request.task = findAddressByCoord(location: via) { _, result in
                switch result {
                case .success(let locations):
                    guard let via = locations.first else {
                        completion(HttpRequest(urlBuilder: UrlBuilder()), .unknownVia)
                        return
                    }
                    request.task = self.doQueryTrips(from: from, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions, previousContext: previousContext, later: later, completion: completion).task
                default:
                    completion(HttpRequest(urlBuilder: UrlBuilder()), .unknownVia)
                }
            }.task
            return request
        }
        if to.type == .coord {
            let request = AsyncRequest(task: nil)
            request.task = findAddressByCoord(location: to) { _, result in
                switch result {
                case .success(let locations):
                    guard let to = locations.first else {
                        completion(HttpRequest(urlBuilder: UrlBuilder()), .unknownTo)
                        return
                    }
                    request.task = self.doQueryTrips(from: from, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions, previousContext: previousContext, later: later, completion: completion).task
                default:
                    completion(HttpRequest(urlBuilder: UrlBuilder()), .unknownTo)
                }
            }.task
            return request
        }
        
        let deparr = departure ? "ABFAHRT" : "ANKUNFT"
        var tripRequest: [String: Any] = [
            "abgangsLocationId": formatLid(from: from),
            "verkehrsmittel": formatProducts(products: tripOptions.products),
            "fahrradmitnahme": tripOptions.options?.contains(.bike) ?? false,
            "zeitWunsch": [
                "reiseDatum": isoDateFormatter.string(from: date),
                "zeitPunktArt": deparr,
            ],
            "zielLocationId": formatLid(from: to),
            "economic": false
        ]
        if let via {
            tripRequest["viaLocations"] = [
                [
                    "locationId": formatLid(from: via),
                    "verkehrsmittel": formatProducts(products: tripOptions.products)
                ]
            ]
        }
        if let maxChanges = tripOptions.maxChanges {
            tripRequest["maxUmstiege"] = maxChanges
        }
        if let minChangeTime = tripOptions.minChangeTime {
            tripRequest["minUmstiegsdauer"] = minChangeTime
        }
        if let previousContext {
            guard let contextString = later ? previousContext.laterContext : previousContext.earlierContext else {
                completion(HttpRequest(urlBuilder: UrlBuilder()), .noTrips)
                return AsyncRequest(task: nil)
            }
            tripRequest["context"] = contextString
        }
        let request: [String: Any] = [
            "autonomeReservierung": false,
            "einstiegsTypList": ["STANDARD"],
            "klasse": tripOptions.tariffProfile?.tariffClass == 1 ? "KLASSE_1" : "KLASSE_2",
            "reiseHin": [
                "wunsch": tripRequest
            ],
            "reisendenProfil": [
                "reisende": [
                    [
                        "ermaessigungen": (tripOptions.tariffProfile?.tariffReductions.map({$0.code}) ?? [0]).compactMap({DbProvider.TARIFF_REDUCTION_MAP[$0]}),
                        "reisendenTyp": DbProvider.TRAVELER_TYPE_MAP[tripOptions.tariffProfile?.travelerType ?? .adult] ?? DbProvider.TRAVELER_TYPE_MAP[.adult]!
                    ]
                ]
            ],
            "reservierungsKontingenteVorhanden": false
        ]
        
        
        let httpRequest = createHttpRequest(for: "angebote/fahrplan", contentType: "application/x.db.vendo.mob.verbindungssuche.v9+json", content: request)
        return makeRequest(httpRequest) {
            try self.queryTripsParsing(request: httpRequest, from: from, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions, previousContext: previousContext, later: later, completion: completion)
        } errorHandler: { err in
            completion(httpRequest, .failure(err))
        }
    }
    
    public override func queryMoreTrips(context: QueryTripsContext, later: Bool, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        guard let context = context as? Context else {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .sessionExpired)
            return AsyncRequest(task: nil)
        }
        return doQueryTrips(from: context.from, via: context.via, to: context.to, date: context.date, departure: context.departure, tripOptions: context.tripOptions, previousContext: context, later: later, completion: completion)
    }
    
    public override func refreshTrip(context: RefreshTripContext, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        guard let context = context as? DbRefreshTripContext else {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .sessionExpired)
            return AsyncRequest(task: nil)
        }
        
        let request: [String: Any] = [
            "reconCtx": context.contextRecon
        ]
        let httpRequest = createHttpRequest(for: "trip/recon", contentType: "application/x.db.vendo.mob.verbindungssuche.v9+json", content: request)
        return makeRequest(httpRequest) {
            try self.refreshTripParsing(request: httpRequest, context: context, completion: completion)
        } errorHandler: { err in
            completion(httpRequest, .failure(err))
        }
    }
    
    override func refreshTripParsing(request: HttpRequest, context: RefreshTripContext, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) throws {
        let json = try validateResponse(with: request.responseData)
        let trip = try parse(trip: json, tariffClass: 2, fares: [])
        let context = Context(from: trip.from, via: nil, to: trip.to, date: Date(), departure: true, laterContext: json["spaeterContext"].string, earlierContext: json["frueherContext"].string, tripOptions: TripOptions())
        completion(request, .success(context: context, from: trip.from, via: nil, to: trip.to, trips: [trip], messages: []))
    }
    
    override func queryTripsParsing(request: HttpRequest, from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions, previousContext: QueryTripsContext?, later: Bool, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) throws {
        let json = try validateResponse(with: request.responseData)
        
        var trips: [Trip] = []
        for jsonTripParent in json["verbindungen"].arrayValue {
            let jsonTrip = jsonTripParent["verbindung"]
            let fares = parse(fares: jsonTripParent)
            let trip = try parse(trip: jsonTrip, tariffClass: tripOptions.tariffProfile?.tariffClass ?? 2, fares: fares)
            trips.append(trip)
        }
        
        if trips.isEmpty {
            completion(request, .noTrips)
            return
        }
        
        let context: Context
        if let previousContext = previousContext as? Context {
            context = Context(from: from, via: via, to: to, date: date, departure: departure, laterContext: later ? json["spaeterContext"].string : previousContext.laterContext, earlierContext: !later ? json["frueherContext"].string : previousContext.earlierContext, tripOptions: tripOptions)
        } else {
            context = Context(from: from, via: via, to: to, date: date, departure: departure, laterContext: json["spaeterContext"].string, earlierContext: json["frueherContext"].string, tripOptions: tripOptions)
        }
        
        completion(request, .success(context: context, from: from, via: via, to: to, trips: trips, messages: []))
    }
    
    public override func queryJourneyDetail(context: QueryJourneyDetailContext, completion: @escaping (HttpRequest, QueryJourneyDetailResult) -> Void) -> AsyncRequest {
        guard let context = context as? DbJourneyContext else {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .invalidId)
            return AsyncRequest(task: nil)
        }
        
        let path = "zuglauf/\(context.journeyId.encodeUrl(using: requestUrlEncoding)!)"
        let httpRequest = createHttpRequest(for: path, contentType: "application/x.db.vendo.mob.zuglauf.v2+json", content: nil)
        return makeRequest(httpRequest) {
            try self.queryJourneyDetailParsing(request: httpRequest, context: context, completion: completion)
        } errorHandler: { err in
            completion(httpRequest, .failure(err))
        }
    }
    
    override func queryJourneyDetailParsing(request: HttpRequest, context: QueryJourneyDetailContext, completion: @escaping (HttpRequest, QueryJourneyDetailResult) -> Void) throws {
        let json = try validateResponse(with: request.responseData)
        
        guard let leg = try parse(leg: json, tariffClass: 2) as? PublicLeg else {
            completion(request, .failure(ParseError(reason: "failed to parse public leg")))
            return
        }
        let trip = Trip(id: "", from: leg.departure, to: leg.arrival, legs: [leg], duration: TimeInterval(json["reiseDauer"].intValue), fares: [])
        completion(request, .success(trip: trip, leg: leg))
    }
    
    public override func queryDepartures(stationId: String, departures: Bool, time: Date?, maxDepartures: Int, equivs: Bool, completion: @escaping (HttpRequest, QueryDeparturesResult) -> Void) -> AsyncRequest {
        let request: [String: Any] = [
            "anfragezeit": timeFormatter.string(from: time ?? Date()),
            "datum": dateFormatter.string(from: time ?? Date()),
            "ursprungsBahnhofId": formatLid(stationId: stationId),
            "verkehrsmittel": ["ALL"]
        ]
        
        let httpRequest = createHttpRequest(for: "bahnhofstafel/\(departures ? "abfahrt" : "ankunft")", contentType: "application/x.db.vendo.mob.bahnhofstafeln.v2+json", content: request)
        return makeRequest(httpRequest) {
            try self.queryDeparturesParsing(request: httpRequest, stationId: stationId, departures: departures, time: time, maxDepartures: maxDepartures, equivs: equivs, completion: completion)
        } errorHandler: { err in
            completion(httpRequest, .failure(err))
        }
    }
    
    override func queryDeparturesParsing(request: HttpRequest, stationId: String, departures: Bool, time: Date?, maxDepartures: Int, equivs: Bool, completion: @escaping (HttpRequest, QueryDeparturesResult) -> Void) throws {
        let json = try validateResponse(with: request.responseData)
        
        var result: [StationDepartures] = []
        for jsonDeparture in json["bahnhofstafel\(departures ? "Abfahrt" : "Ankunft")Positionen"].arrayValue {
            guard let location = parse(location: jsonDeparture["abfrageOrt"]) else { continue }
            if !equivs && extractStationId(from: stationId) != extractStationId(from: location.id) { continue }
            
            let stop = parse(stop: jsonDeparture, fallbackLocation: location)
            guard let stopEvent = stop?.departure ?? stop?.arrival else { continue }
            let line = parse(line: jsonDeparture)
            let cancelled = parseCancelled(stop: jsonDeparture)
            let departure = Departure(plannedTime: stopEvent.plannedTime, predictedTime: stopEvent.predictedTime, line: line, position: stopEvent.predictedPlatform, plannedPosition: stopEvent.plannedPlatform, cancelled: cancelled, destination: parse(direction: jsonDeparture), capacity: nil, message: parse(messages: jsonDeparture), journeyContext: parse(journeyContext: jsonDeparture), wagonSequenceContext: parse(wagonSequenceContext: jsonDeparture))
            
            var stationDepartures = result.first(where: {$0.stopLocation.id == location.id})
            if stationDepartures == nil {
                stationDepartures = StationDepartures(stopLocation: location, departures: [], lines: [])
                result.append(stationDepartures!)
            }
            stationDepartures?.departures.append(departure)
            
            if result.flatMap({$0.departures}).count >= maxDepartures { break }
        }
        
        completion(request, .success(departures: result))
    }
    
    public override func queryWagonSequence(context: QueryWagonSequenceContext, completion: @escaping (HttpRequest, QueryWagonSequenceResult) -> Void) -> AsyncRequest {
        guard let context = context as? DbWagonSequenceContext else {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .invalidId)
            return AsyncRequest(task: nil)
        }
        
        let path = "zuglaeufe/\(context.lineLabel)/halte/by-abfahrt/\(context.departureId)/wagenreihung"
        let httpRequest = createHttpRequest(for: path, contentType: "application/x.db.vendo.mob.wagenreihung.v3+json", content: nil)
        return makeRequest(httpRequest) {
            try self.queryWagonSequenceParsing(request: httpRequest, context: context, completion: completion)
        } errorHandler: { err in
            completion(httpRequest, .failure(err))
        }
    }
    
    override func queryWagonSequenceParsing(request: HttpRequest, context: QueryWagonSequenceContext, completion: @escaping (HttpRequest, QueryWagonSequenceResult) -> Void) throws {
        let json = try validateResponse(with: request.responseData)
        
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
        case ICE1, ICE2, ICE3, ICE3BR406, ICE3BR407, ICE3NEOBR408, ICET, ICET_5, ICE4, ICE4_7, ICE4_XXL, IC2BOMBARDIER, IC2STADLER, ICE3EUROPE, ICE3NEOEUROPE, ICE3PRIDE, ICE4GERMANY, ICE4HANDBALL, ICE4FOOTBALL
        
        public static func parse(from vehicleNumber: String) -> TrainType? {
            if vehicleNumber.hasPrefix("ICE0304") {
                return .ICE3PRIDE
            }
            if vehicleNumber.hasPrefix("ICE4601") {
                return .ICE3EUROPE
            }
            if vehicleNumber.hasPrefix("ICE8029") {
                return .ICE3NEOEUROPE
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
    
    public class Context: QueryTripsContext {
        
        public override class var supportsSecureCoding: Bool { return true }
        
        public override var canQueryEarlier: Bool { return earlierContext != nil }
        public override var canQueryLater: Bool { return laterContext != nil }
        
        public let from: Location
        public let via: Location?
        public let to: Location
        public let date: Date
        public let departure: Bool
        public let laterContext: String?
        public let earlierContext: String?
        public let tripOptions: TripOptions
        
        init(from: Location, via: Location?, to: Location, date: Date, departure: Bool, laterContext: String?, earlierContext: String?, tripOptions: TripOptions) {
            self.from = from
            self.via = via
            self.to = to
            self.date = date
            self.departure = departure
            self.laterContext = laterContext
            self.earlierContext = earlierContext
            self.tripOptions = tripOptions
            super.init()
        }
        
        public required convenience init?(coder aDecoder: NSCoder) {
            guard
                let from = aDecoder.decodeObject(of: Location.self, forKey: PropertyKey.from),
                let to = aDecoder.decodeObject(of: Location.self, forKey: PropertyKey.to),
                let date = aDecoder.decodeObject(of: NSDate.self, forKey: PropertyKey.date) as Date?,
                let tripOptions = aDecoder.decodeObject(of: TripOptions.self, forKey: PropertyKey.tripOptions)
                else {
                    return nil
            }
            let departure = aDecoder.decodeBool(forKey: PropertyKey.departure)
            let via = aDecoder.decodeObject(of: Location.self, forKey: PropertyKey.via)
            let laterContext = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.laterContext) as String?
            let earlierContext = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.earlierContext) as String?
            
            self.init(from: from, via: via, to: to, date: date, departure: departure, laterContext: laterContext, earlierContext: earlierContext, tripOptions: tripOptions)
        }
        
        public override func encode(with aCoder: NSCoder) {
            aCoder.encode(from, forKey: PropertyKey.from)
            aCoder.encode(via, forKey: PropertyKey.via)
            aCoder.encode(to, forKey: PropertyKey.to)
            aCoder.encode(date, forKey: PropertyKey.date)
            aCoder.encode(departure, forKey: PropertyKey.departure)
            aCoder.encode(earlierContext, forKey: PropertyKey.earlierContext)
            aCoder.encode(laterContext, forKey: PropertyKey.laterContext)
            aCoder.encode(tripOptions, forKey: PropertyKey.tripOptions)
        }
        
        struct PropertyKey {
            static let from = "from"
            static let via = "via"
            static let to = "to"
            static let date = "date"
            static let departure = "dep"
            static let laterContext = "laterContext"
            static let earlierContext = "earlierContext"
            static let tripOptions = "tripOptions"
        }
        
    }
    
}

public class DbWagonSequenceContext: QueryWagonSequenceContext {
    
    public override class var supportsSecureCoding: Bool { return true }
    
    public let lineLabel: String
    public let departureId: String
    
    public init(lineLabel: String, departureId: String) {
        self.lineLabel = lineLabel
        self.departureId = departureId
        super.init()
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard
            let lineLabel = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.lineLabel) as String?,
            let departureId = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.departureId) as String?
        else { return nil }
        self.init(lineLabel: lineLabel, departureId: departureId)
    }
    
    public override func encode(with aCoder: NSCoder) {
        aCoder.encode(lineLabel, forKey: PropertyKey.lineLabel)
        aCoder.encode(departureId, forKey: PropertyKey.departureId)
    }
    
    struct PropertyKey {
        static let lineLabel = "lineLabel"
        static let departureId = "departureId"
    }
}

public class DbJourneyContext: QueryJourneyDetailContext {
    
    public override class var supportsSecureCoding: Bool { return true }
    
    public let journeyId: String
    
    public init(journeyId: String) {
        self.journeyId = journeyId
        super.init()
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let journeyId = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.journeyId) as String? else { return nil }
        self.init(journeyId: journeyId)
    }
    
    public override func encode(with aCoder: NSCoder) {
        aCoder.encode(journeyId, forKey: PropertyKey.journeyId)
    }
    
    struct PropertyKey {
        
        static let journeyId = "journeyId"
        
    }
}

public class DbRefreshTripContext: RefreshTripContext {
    
    public override class var supportsSecureCoding: Bool { return true }
    
    public let contextRecon: String
    
    init(contextRecon: String) {
        self.contextRecon = contextRecon
        super.init()
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let contextRecon = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.contextRecon) as String? else { return nil }
        self.init(contextRecon: contextRecon)
    }
    
    public override func encode(with aCoder: NSCoder) {
        aCoder.encode(contextRecon, forKey: PropertyKey.contextRecon)
    }
    
    struct PropertyKey {
        
        static let contextRecon = "contextRecon"
        
    }
    
}
