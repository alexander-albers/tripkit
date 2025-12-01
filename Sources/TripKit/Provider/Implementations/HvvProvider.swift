import Foundation
import os.log
import SwiftyJSON

/// Hamburger Verkehrsverbund (DE)
public class HvvProvider: AbstractNetworkProvider {
    
    /// Documentation: https://gti.geofox.de/html/GTIHandbuch_p.html
    static let API_BASE = "https://gti.geofox.de/gti/public/"
    static let VERSION = 63
    let authHeaders: [String: Any]
    
    public override var supportedLanguages: Set<String> { ["de", "en"] }
    
    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = "dd.MM.yyyy"
        formatter.locale = Locale(identifier: "de_DE")
        return formatter
    }()
    lazy var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "de_DE")
        return formatter
    }()
    lazy var dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        formatter.locale = Locale(identifier: "de_DE")
        return formatter
    }()
    lazy var isoDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    public init(apiAuthorization: [String: Any]) {
        self.authHeaders = apiAuthorization
        super.init(networkId: .HVV)
        
        styles = [
            "UU1": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(0, 103, 165), foregroundColor: LineStyle.white),
            "UU2": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(216, 34, 42), foregroundColor: LineStyle.white),
            "UU3": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(245, 218, 48), foregroundColor: LineStyle.white),
            "UU4": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(58, 160, 155), foregroundColor: LineStyle.white),
            "SS1": LineStyle(backgroundColor: LineStyle.rgb(57, 167, 73), foregroundColor: LineStyle.white),
            "SS11": LineStyle(backgroundColor: LineStyle.white, foregroundColor: LineStyle.rgb(57, 167, 73), borderColor: LineStyle.rgb(57, 167, 73)),
            "SS2": LineStyle(backgroundColor: LineStyle.rgb(162, 41, 73), foregroundColor: LineStyle.white),
            "SS21": LineStyle(backgroundColor: LineStyle.rgb(162, 41, 73), foregroundColor: LineStyle.white),
            "SS3": LineStyle(backgroundColor: LineStyle.rgb(87, 43, 121), foregroundColor: LineStyle.white),
            "SS31": LineStyle(backgroundColor: LineStyle.white, foregroundColor: LineStyle.rgb(87, 43, 121), borderColor: LineStyle.rgb(87, 43, 121)),
            "SS5": LineStyle(backgroundColor: LineStyle.rgb(64, 145, 189), foregroundColor: LineStyle.white),
            "SA1": LineStyle(backgroundColor: LineStyle.rgb(244, 134, 31), foregroundColor: LineStyle.white),
            "SA2": LineStyle(backgroundColor: LineStyle.rgb(244, 134, 31), foregroundColor: LineStyle.white),
            "SA3": LineStyle(backgroundColor: LineStyle.rgb(244, 134, 31), foregroundColor: LineStyle.white),
            "B600": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B601": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B602": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B603": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B604": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B605": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B606": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B607": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B608": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B609": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B611": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B613": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B616": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B617": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B618": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B619": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B621": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B623": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B626": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B627": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B629": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B638": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B639": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B640": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B641": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B642": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B643": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B644": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B648": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B649": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B658": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B688": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B": LineStyle(backgroundColor: LineStyle.rgb(217, 34, 42), foregroundColor: LineStyle.white),
            "F": LineStyle(backgroundColor: LineStyle.rgb(0, 150, 185), foregroundColor: LineStyle.white)
        ]
    }
    
    public override func suggestLocations(constraint: String, types: [LocationType]?, maxLocations: Int, completion: @escaping (HttpRequest, SuggestLocationsResult) -> Void) -> AsyncRequest {
        var dict: [String: Any] = [
            "version": HvvProvider.VERSION,
            "language": queryLanguage ?? defaultLanguage,
            "theName": ["name": constraint]
        ]
        dict["maxList"] = maxLocations > 0 ? maxLocations : 20
        let request = encodeJson(dict: dict, requestUrlEncoding: .utf8)
        let urlBuilder = UrlBuilder(path: HvvProvider.API_BASE + "checkName", encoding: .utf8)
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder).setPostPayload(request).setHeaders(getAuthHeaders(request))
        return makeRequest(httpRequest) {
            try self.suggestLocationsParsing(request: httpRequest, constraint: constraint, types: types, maxLocations: maxLocations, completion: completion)
        } errorHandler: { err in
            completion(httpRequest, .failure(err))
        }
    }
    
    override func suggestLocationsParsing(request: HttpRequest, constraint: String, types: [LocationType]?, maxLocations: Int, completion: @escaping (HttpRequest, SuggestLocationsResult) -> Void) throws {
        let json = try getResponse(from: request)
        let returnCode = json["returnCode"].stringValue
        guard returnCode == "OK" else {
            throw ParseError(reason: "invalid return code \(returnCode)")
        }
        var locations: [SuggestedLocation] = []
        for (_, location) in json["results"] {
            guard let location = parseLocation(json: location) else { continue }
            if let types = types, !types.contains(location.type) && !types.contains(.any) { continue }
            locations.append(SuggestedLocation(location: location, priority: 0))
        }
        completion(request, .success(locations: locations))
    }
    
    public override func queryNearbyLocations(location: Location, types: [LocationType]?, maxDistance: Int, maxLocations: Int, completion: @escaping (HttpRequest, NearbyLocationsResult) -> Void) -> AsyncRequest {
        var name = jsonLocation(location: location)
        if location.id == nil {
            // no id provided -> search for other stations
            name["type"] = "STATION"
        }
        var dict: [String: Any] = [
            "version": HvvProvider.VERSION,
            "language": queryLanguage ?? defaultLanguage,
            "theName": name
        ]
        dict["maxList"] = maxLocations > 0 ? maxLocations : 20
        if maxDistance > 0 {
            dict["maxDistance"] = maxDistance
        }
        let request = encodeJson(dict: dict, requestUrlEncoding: .utf8)
        let urlBuilder = UrlBuilder(path: HvvProvider.API_BASE + "checkName", encoding: .utf8)
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder).setPostPayload(request).setHeaders(getAuthHeaders(request))
        return makeRequest(httpRequest) {
            try self.queryNearbyLocationsByCoordinateParsing(request: httpRequest, location: location, types: types, maxDistance: maxDistance, maxLocations: maxLocations, completion: completion)
        } errorHandler: { err in
            completion(httpRequest, .failure(err))
        }
    }
    
    override func queryNearbyLocationsByCoordinateParsing(request: HttpRequest, location: Location, types: [LocationType]?, maxDistance: Int, maxLocations: Int, completion: @escaping (HttpRequest, NearbyLocationsResult) -> Void) throws {
        try suggestLocationsParsing(request: request, constraint: location.getUniqueShortName(), types: types ?? [.station], maxLocations: maxLocations) { _, result in
            switch result {
            case .success(let locations):
                completion(request, .success(locations: locations.map { $0.location }))
            case .failure(let error):
                completion(request, .failure(error))
            }
        }
    }
    
    public override func queryDepartures(stationId: String, departures: Bool, time: Date?, maxDepartures: Int, equivs: Bool, completion: @escaping (HttpRequest, QueryDeparturesResult) -> Void) -> AsyncRequest {
        var dict: [String: Any] = [
            "version": HvvProvider.VERSION,
            "language": queryLanguage ?? defaultLanguage,
            "station": jsonLocation(location: Location(id: stationId)),
            "allStationsInChangingNode": equivs,
            "maxTimeOffset": 720 // maximum 12 hours in advance
        ]
        dict["maxList"] = maxDepartures > 0 ? maxDepartures : 20
        if let time = time {
            dict["time"] = jsonDate(date: time)
        }
        let request = encodeJson(dict: dict, requestUrlEncoding: .utf8)
        let urlBuilder = UrlBuilder(path: HvvProvider.API_BASE + "departureList", encoding: .utf8)
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder).setPostPayload(request).setHeaders(getAuthHeaders(request))
        return makeRequest(httpRequest) {
            try self.queryDeparturesParsing(request: httpRequest, stationId: stationId, departures: departures, time: time, maxDepartures: maxDepartures, equivs: equivs, completion: completion)
        } errorHandler: { err in
            completion(httpRequest, .failure(err))
        }
    }
    
    override func queryDeparturesParsing(request: HttpRequest, stationId: String, departures: Bool, time: Date?, maxDepartures: Int, equivs: Bool, completion: @escaping (HttpRequest, QueryDeparturesResult) -> Void) throws {
        let json = try getResponse(from: request)
        let returnCode = json["returnCode"].stringValue
        guard returnCode == "OK" else {
            if returnCode == "ERROR_TEXT" && json["errorDevInfo"].stringValue.hasPrefix("0 Please provide a station object with a valid id") {
                completion(request, .invalidStation)
                return
            }
            throw ParseError(reason: "invalid return code \(returnCode)")
        }
        
        let startDate = try parseDate(date: json["time"])
        var stationDepartures: [StationDepartures] = []
        for (_, departure) in json["departures"] {
            let cancelled = departure["cancelled"].boolValue
            
            let station = departure["station"].exists() ? parseLocation(json: departure["station"]) : nil
            let line = parseLineAndDestination(json: departure["line"], directionType: json["direction"].int)
            let timeOffset = departure["timeOffset"].intValue  // minutes
            let delay = departure["delay"].int
            
            let plannedTime = startDate.addingTimeInterval(TimeInterval(timeOffset * 60))
            let predictedTime: Date?
            if let delay = delay {
                predictedTime = plannedTime.addingTimeInterval(TimeInterval(delay * 60))
            } else {
                predictedTime = nil
            }
            let plannedPlatform = parsePosition(position: departure["platform"].string)
            let predictedPlatform = parsePosition(position: departure["realtimePlatform"].string)
            let message = parseAttributes(attributes: departure["attributes"])
            let journeyContext: HvvJourneyContext?
            if let lineId = line.line.id, let serviceId = departure["serviceId"].int {
                journeyContext = HvvJourneyContext(lineKey: lineId, serviceId: serviceId, station: station ?? Location(id: stationId), stationTime: plannedTime, line: line.line)
            } else {
                journeyContext = nil
            }
            
            let dep = Departure(plannedTime: plannedTime, predictedTime: predictedTime, line: line.line, position: predictedPlatform, plannedPosition: plannedPlatform, cancelled: cancelled, destination: line.destination, capacity: nil, message: message, journeyContext: journeyContext)
            
            let stationDeparture: StationDepartures
            if let first = stationDepartures.first(where: { station == nil || $0.stopLocation == station }) {
                stationDeparture = first
            } else {
                stationDeparture = StationDepartures(stopLocation: station ?? Location(id: stationId), departures: [], lines: [])
                stationDepartures.append(stationDeparture)
            }
            stationDeparture.departures.append(dep)
        }
        completion(request, .success(departures: stationDepartures))
    }
    
    public override func queryJourneyDetail(context: QueryJourneyDetailContext, completion: @escaping (HttpRequest, QueryJourneyDetailResult) -> Void) -> AsyncRequest {
        guard let context = context as? HvvJourneyContext else {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .invalidId)
            return AsyncRequest(task: nil)
        }
        
        let request = encodeJson(dict: [
            "version": HvvProvider.VERSION,
            "language": queryLanguage ?? defaultLanguage,
            "lineKey": context.lineKey,
            "serviceId": context.serviceId,
            "station": jsonLocation(location: context.station),
            "showPath": true,
            "segments": "ALL",
            "time": jsonIsoDate(date: context.stationTime)
        ], requestUrlEncoding: .utf8)
        let urlBuilder = UrlBuilder(path: HvvProvider.API_BASE + "departureCourse", encoding: .utf8)
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder).setPostPayload(request).setHeaders(getAuthHeaders(request))
        return makeRequest(httpRequest) {
            try self.queryJourneyDetailParsing(request: httpRequest, context: context, completion: completion)
        } errorHandler: { err in
            completion(httpRequest, .failure(err))
        }
    }
    
    override func queryJourneyDetailParsing(request: HttpRequest, context: QueryJourneyDetailContext, completion: @escaping (HttpRequest, QueryJourneyDetailResult) -> Void) throws {
        guard let context = context as? HvvJourneyContext else {
            completion(request, .invalidId)
            return
        }
        let json = try getResponse(from: request)
        let returnCode = json["returnCode"].stringValue
        guard returnCode == "OK" else {
            throw ParseError(reason: "invalid return code \(returnCode)")
        }
        
        let courseElements = json["courseElements"].arrayValue
        let departure = try parseCourseElem(json: courseElements[0], prefix: "from")
        let arrival = try parseCourseElem(json: courseElements[courseElements.count - 1], prefix: "to")
        var stops: [Stop] = []
        for index in 0..<courseElements.count-1 {
            let dep = try parseCourseElem(json: courseElements[index], prefix: "to")
            let arr = try parseCourseElem(json: courseElements[index+1], prefix: "from")
            stops.append(Stop(location: dep.location, departure: dep, arrival: arr, message: nil))
        }
        
        var path: [LocationPoint] = []
        for index in 0..<courseElements.count {
            var track = parsePath(json: courseElements[index]["path"])
            if index != 0 {
                // remove overlap
                track.removeFirst()
            }
            path.append(contentsOf: track)
        }
        
        let leg = PublicLeg(line: context.line, destination: arrival.location, departure: departure, arrival: arrival, intermediateStops: stops, message: nil, path: path, journeyContext: context, wagonSequenceContext: nil, loadFactor: nil)
        let trip = Trip(id: "", from: departure.location, to: arrival.location, legs: [leg], duration: 0, fares: [], refreshContext: nil)
        completion(request, .success(trip: trip, leg: leg))
    }
    
    public override func queryTrips(from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        return doQueryTrips(from: from, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions, previousContext: nil, later: false, completion: completion)
    }
    
    public override func queryMoreTrips(context: QueryTripsContext, later: Bool, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        guard let context = context as? Context else {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .sessionExpired)
            return AsyncRequest(task: nil)
        }
        return doQueryTrips(from: context.from, via: context.via, to: context.to, date: context.date, departure: context.departure, tripOptions: context.tripOptions, previousContext: context, later: later, completion: completion)
    }
    
    public override func refreshTrip(context: RefreshTripContext, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        // unsupported
        return AsyncRequest(task: nil)
    }
    
    override func refreshTripParsing(request: HttpRequest, context: RefreshTripContext, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) throws {
        // does not apply
    }
    
    private func doQueryTrips(from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions, previousContext: Context?, later: Bool, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        let desiredTypes = jsonDesiredTypes(products: tripOptions.products)
        let handycap: Int
        switch tripOptions.accessibility ?? .neutral {
        case .barrierFree: handycap = 5
        case .limited: handycap = 3
        case .neutral:
            switch tripOptions.walkSpeed ?? .normal {
            case .fast: handycap = -1
            case .slow: handycap = 1
            case .normal: handycap = 0
            }
        }
        let timeIsDeparture = previousContext != nil ? later : departure
        var requestDict: [String : Any] = [
            "version": HvvProvider.VERSION,
            "language": queryLanguage ?? defaultLanguage,
            "start": jsonLocation(location: from),
            "dest": jsonLocation(location: to),
            "time": jsonDate(date: date),
            "timeIsDeparture": timeIsDeparture,
            "tariffDetails": true,
            "intermediateStops": true,
            "realtime": "REALTIME",
            "returnContSearchData": true,
            "numberOfSchedules": 6,
            "schedulesBefore": timeIsDeparture ? 0 : 6,
            "schedulesAfter": timeIsDeparture ? 6 : 0,
            "penalties": [
                ["name": "desiredType", "value": desiredTypes != nil ? "\(desiredTypes!):10000" : "train:0"] as [String : Any],
                ["name": "changeEvent", "value": tripOptions.optimize == .leastChanges ? 8 : 4],
                ["name": "walker", "value": tripOptions.optimize == .leastWalking ? 3 : 1],
                ["name": "anyHandicap", "value": handycap]
            ],
            "tariffInfoSelector": [
                "tariff": "HVV",
                "tariffRegions": false,
                "kinds": [1, 2]  // Einzelfahrkarte Erwachsener & Kind
            ] as [String : Any],
            "withPaths": true,
            "useBikeAndRide": false
        ]
        if let via = via {
            requestDict["via"] = jsonLocation(location: via)
        }
        if let previousContext = previousContext {
            requestDict["contSearchByServiceId"] = later ? previousContext.laterContext : previousContext.earlierContext
        }
        let request = encodeJson(dict: requestDict, requestUrlEncoding: .utf8)
        let urlBuilder = UrlBuilder(path: HvvProvider.API_BASE + "getRoute", encoding: .utf8)
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder).setPostPayload(request).setHeaders(getAuthHeaders(request))
        return makeRequest(httpRequest) {
            try self.queryTripsParsing(request: httpRequest, from: from, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions, previousContext: previousContext, later: later, completion: completion)
        } errorHandler: { err in
            completion(httpRequest, .failure(err))
        }
    }
    
    override func queryTripsParsing(request: HttpRequest, from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions, previousContext: QueryTripsContext?, later: Bool, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) throws {
        let json = try getResponse(from: request)
        let returnCode = json["returnCode"].stringValue
        let errorDevInfo = json["errorDevInfo"].stringValue
        switch returnCode {
        case "OK": break
        case "ERROR_ROUTE":
            completion(request, .noTrips)
            return
        case "ERROR_CN_TOO_MANY":
            completion(request, .ambiguous(ambiguousFrom: [], ambiguousVia: [], ambiguousTo: []))
            return
        case "START_NOT_FOUND", "FORCED_START_NOT_FOUND":
            completion(request, .unknownFrom)
            return
        case "DEST_NOT_FOUND", "FORCED_DEST_NOT_FOUND":
            completion(request, .unknownTo)
            return
        case "VIA_NOT_FOUND":
            completion(request, .unknownVia)
            return
        default:
            if errorDevInfo.lowercased().contains("kein ergebnis gefunden für haltestelle") || errorDevInfo.lowercased().contains("not listed as HVV station") {
                if let fromName = from.name, errorDevInfo.contains(fromName) {
                    completion(request, .unknownFrom)
                } else if let toName = to.name, errorDevInfo.contains(toName) {
                    completion(request, .unknownTo)
                } else if let viaName = via?.name, errorDevInfo.contains(viaName) {
                    completion(request, .unknownVia)
                } else {
                    completion(request, .noTrips)
                }
                return
            } else if errorDevInfo.lowercased().contains("ausserhalb der fahrplangültigkeit") {
                completion(request, .invalidDate)
                return
            } else if errorDevInfo == "-212 keine Lösung für die gewünschten Start- und Zielpunkte gefunden" {
                completion(request, .noTrips)
                return
            }
            throw ParseError(reason: "invalid return code \(returnCode): \(errorDevInfo)")
        }
        
        var trips: [Trip] = []
        let schedules: [JSON]
        if json["realtimeSchedules"].exists() {
            schedules = json["realtimeSchedules"].arrayValue
        } else if json["schedules"].exists() {
            schedules = json["schedules"].arrayValue
        } else {
            schedules = []
        }
        if schedules.isEmpty {
            completion(request, .noTrips)
            return
        }
        for schedule in schedules {
            trips.append(try parseTrip(json: schedule))
        }
        var laterContext = schedules.last?["contSearchAfter"].dictionaryObject
        if !later, let previousContext = previousContext as? Context, previousContext.canQueryLater {
            laterContext = previousContext.laterContext
        }
        var earlierContext = schedules.first?["contSearchBefore"].dictionaryObject
        if later, let previousContext = previousContext as? Context, previousContext.canQueryEarlier {
            earlierContext = previousContext.earlierContext
        }
        let context = Context(from: from, via: via, to: to, date: date, departure: departure, laterContext: laterContext, earlierContext: earlierContext, tripOptions: tripOptions)
        completion(request, .success(context: context, from: from, via: via, to: to, trips: trips, messages: []))
    }
    
    // MARK: parsing utils
    
    private func parseLocation(json: JSON) -> Location? {
        let type: LocationType
        switch json["type"].stringValue {
        case "STATION":     type = .station
        case "POI":         type = .poi
        case "ADDRESS":     type = .address
        case "COORDINATE":  type = .coord
        default:            type = .any
        }
        let id = json["id"].string
        let name = json["name"].string ?? json["combinedName"].string
        let place = json["city"].string
        let coord: LocationPoint?
        if let x = json["coordinate"]["x"].double, let y = json["coordinate"]["y"].double {
            coord = LocationPoint(lat: Int(y * 1e6), lon: Int(x * 1e6))
        } else {
            coord = nil
        }
        return Location(type: type == .any && id != nil ? .station : type, id: id, coord: coord, place: place, name: name)
    }
    
    private func jsonLocation(location: Location) -> [String: Any] {
        let type: String
        switch location.type {
        case .station:      type = "STATION"
        case .poi:          type = "POI"
        case .address:      type = "ADDRESS"
        case .coord:        type = "COORDINATE"
        default:            type = "UNKNOWN"
        }
        
        var result: [String: Any] = [:]
        if let id = location.id {
            result["id"] = id
        }
        result["type"] = type
        if let name = location.name {
            result["name"] = name
        }
        if let place = location.place {
            result["city"] = place
        }
        if let c = location.coord {
            result["coordinate"] = ["x": Double(c.lon) / 1e6, "y": Double(c.lat) / 1e6]
        }
        return result
    }
    
    private func parseDate(date: JSON) throws -> Date {
        let dateString = date["date"].stringValue
        let timeString = date["time"].stringValue
        
        guard let result = dateTimeFormatter.date(from: "\(dateString) \(timeString)") else {
            throw ParseError(reason: "failed to parse date \(dateString) \(timeString)")
        }
        return result
    }
    
    private func parseIsoDate(date: JSON) throws -> Date {
        guard let result = isoDateFormatter.date(from: date.stringValue) else {
            throw ParseError(reason: "failed to parse date \(date.stringValue)")
        }
        return result
    }
    
    private func jsonDate(date: Date) -> [String: String] {
        return [
            "date": dateFormatter.string(from: date),
            "time": timeFormatter.string(from: date)
        ]
    }
    
    private func jsonIsoDate(date: Date) -> String {
        return isoDateFormatter.string(from: date)
    }
    
    private func parseLineAndDestination(json: JSON, directionType: Int?) -> ServingLine {
        let id = json["id"].string
        let name = json["name"].string
        let direction = json["direction"].string
        let directionId = json["directionId"].string
        let product = parseLineProduct(type: json["type"]["shortInfo"].stringValue)
        let network = json["carrierNameShort"].string
        
        let dir: Line.Direction?
        switch directionType ?? 0 {
        case 1: dir = .outward
        case 6: dir = .return
        default: dir = nil
        }
        let line = Line(id: id, network: network, product: product, label: name, name: name, number: nil, vehicleNumber: nil, style: lineStyle(network: network, product: product, label: name), attr: nil, message: nil, direction: dir)
        let destination: Location?
        if let direction = direction {
            destination = Location(type: .station, id: directionId, coord: nil, place: nil, name: direction)
        } else {
            destination = nil
        }
        return ServingLine(line: line, destination: destination)
    }
    
    private func parseLineProduct(type: String) -> Product? {
        switch type {
        case "ICE", "IC":
            return .highSpeedTrain
        case "RB", "RE":
            return .regionalTrain
        case "Bus", "XpressBus", "Schnellbus", "Nachtbus":
            return .bus
        case "S", "A":
            return .suburbanTrain
        case "U":
            return .subway
        case "Schiff":
            return .ferry
        default:
            return nil
        }
    }
    
    private func parseTrip(json: JSON) throws -> Trip {
        guard
            let from = parseLocation(json: json["start"]),
            let to = parseLocation(json: json["dest"])
        else {
            throw ParseError(reason: "failed to parse from/to")
        }
        var legs: [Leg] = []
        for (_, jsonLeg) in json["scheduleElements"] {
            if let leg = try parseLeg(json: jsonLeg) {
                legs.append(leg)
            }
        }
        let duration = json["time"].doubleValue * 60
        let fares = parseFares(json: json["tariffInfos"])
        return Trip(id: "", from: from, to: to, legs: legs, duration: duration, fares: fares, refreshContext: nil)
    }
    
    private func parseLeg(json: JSON) throws -> Leg? {
        guard
            let departure = try parseStop(json: json["from"]).departure,
            let arrival = try parseStop(json: json["to"]).arrival
        else {
            throw ParseError(reason: "failed to parse leg from/to")
        }
        var path: [LocationPoint] = []
        for jsonPath in json["paths"].arrayValue {
            let track = parsePath(json: jsonPath)
            path.append(contentsOf: track)
        }
        let serviceType = json["line"]["type"]["simpleType"].stringValue
        switch serviceType {
        case "FOOTPATH":
            // Individual leg
            return IndividualLeg(type: .walk, departureTime: departure.time, departure: departure.location, arrival: arrival.location, arrivalTime: arrival.time, distance: 0, path: path)
        case "BICYCLE", "ACTIVITY_BIKE_AND_RIDE":
            return IndividualLeg(type: .bike, departureTime: departure.time, departure: departure.location, arrival: arrival.location, arrivalTime: arrival.time, distance: 0, path: path)
        case "CHANGE", "CHANGE_SAME_PLATFORM":
            if departure.time == arrival.time {
                return nil
            }
            return IndividualLeg(type: .transfer, departureTime: departure.time, departure: departure.location, arrival: arrival.location, arrivalTime: arrival.time, distance: 0, path: path)
        case "BUS", "TRAIN", "SHIP":
            // Public leg
            let servingLine = parseLineAndDestination(json: json["line"], directionType: nil)
            var stops: [Stop] = []
            for (_, jsonStop) in json["intermediateStops"] {
                stops.append(try parseStop(json: jsonStop))
            }
            if json["cancelled"].boolValue {
                departure.cancelled = true
                arrival.cancelled = true
                stops.forEach { $0.departure?.cancelled = true; $0.arrival?.cancelled = true }
            }
            let message = parseAttributes(attributes: json["announcement"])
            let context: HvvJourneyContext?
            if let lineId = servingLine.line.id, let serviceId = json["serviceId"].int {
                context = HvvJourneyContext(lineKey: lineId, serviceId: serviceId, station: departure.location, stationTime: departure.plannedTime, line: servingLine.line)
            } else {
                context = nil
            }
            return PublicLeg(line: servingLine.line, destination: servingLine.destination, departure: departure, arrival: arrival, intermediateStops: stops, message: message, path: path, journeyContext: context, wagonSequenceContext: nil, loadFactor: nil)
        default:
            throw ParseError(reason: "unknown service type \(serviceType)")
        }
    }
    
    private func parseStop(json: JSON) throws -> Stop {
        guard let location = parseLocation(json: json) else { throw ParseError(reason: "stop location could not be parsed") }
        let departure: StopEvent?
        if let plannedTime = try? parseDate(date: json["depTime"]) {
            let predictedTime: Date?
            if let delay = json["depDelay"].int {
                predictedTime = plannedTime.addingTimeInterval(TimeInterval(delay))
            } else {
                predictedTime = nil
            }
            let plannedPlatform = parsePosition(position: json["platform"].string)
            let predictedPlatform = parsePosition(position: json["realtimePlatform"].string)
            departure = StopEvent(location: location, plannedTime: plannedTime, predictedTime: predictedTime, plannedPlatform: plannedPlatform, predictedPlatform: predictedPlatform, cancelled: json["cancelled"].boolValue)
        } else {
            departure = nil
        }
        let arrival: StopEvent?
        if let plannedTime = try? parseDate(date: json["arrTime"]) {
            let predictedTime: Date?
            if let delay = json["arrDelay"].int {
                predictedTime = plannedTime.addingTimeInterval(TimeInterval(delay))
            } else {
                predictedTime = nil
            }
            let plannedPlatform = parsePosition(position: json["platform"].string)
            let predictedPlatform = parsePosition(position: json["realtimePlatform"].string)
            arrival = StopEvent(location: location, plannedTime: plannedTime, predictedTime: predictedTime, plannedPlatform: plannedPlatform, predictedPlatform: predictedPlatform, cancelled: json["cancelled"].boolValue)
        } else {
            arrival = nil
        }
        let message = parseAttributes(attributes: json["attributes"])
        return Stop(location: location, departure: departure, arrival: arrival, message: message)
    }
    
    private func parsePath(json: JSON) -> [LocationPoint] {
        var result: [LocationPoint] = []
        for (_, coord) in json["track"] {
            result.append(LocationPoint(lat: Int(coord["y"].doubleValue * 1e6), lon: Int(coord["x"].doubleValue * 1e6)))
        }
        return result
    }
    
    private func parseFares(json: JSON) -> [Fare] {
        var result: [Fare] = []
        for ticket in json.arrayValue.flatMap({ $0["ticketInfos"].arrayValue }) {
            let kind = ticket["tariffKindID"].intValue
            let currency = ticket["currency"].string ?? "EUR"
            guard let price = ticket["basePrice"].float, price > 0 else { continue }
            switch kind {
            case 1: result.append(Fare(name: nil, type: .adult, currency: currency, fare: price, unitsName: nil, units: nil))
            case 2: result.append(Fare(name: nil, type: .child, currency: currency, fare: price, unitsName: nil, units: nil))
            default: break
            }
        }
        return result
    }
    
    let P_POSITION: NSRegularExpression = try! NSRegularExpression(pattern: "^Gleis\\s*(.*?)\\s*(?:\\(.*\\))?$", options: .caseInsensitive)
    
    override func parsePosition(position: String?) -> String? {
        if let m = position?.match(pattern: P_POSITION) {
            return (m[0])
        }
        return super.parsePosition(position: position)
    }
    
    private func parseAttributes(attributes: JSON) -> String? {
        var messages: [String] = []
        for (_, attribute) in attributes {
            if let title = attribute["summary"].string {
                messages.append(title)
            } else if let value = attribute["description"].string {
                messages.append(value)
            }
        }
        // please, please continue to wear a mask, even if the app doesn't nag you about it anymore
        messages = messages.filter({!$0.lowercased().contains("ffp") && !$0.lowercased().contains("maskenpflicht") && !$0.lowercased().contains("3g-pflicht") && !$0.lowercased().contains("3g-regel")})
        messages = messages.map({ $0.ensurePunctuation })
        return messages.uniqued().joined(separator: "\n").emptyToNil
    }
    
    private func parseCourseElem(json: JSON, prefix: String) throws -> StopEvent {
        guard let location = parseLocation(json: json["\(prefix)Station"]) else { throw ParseError(reason: "failed to parse course elem") }
        let plannedTime = try parseIsoDate(date: json["\(prefix == "from" ? "dep" : "arr")Time"])
        let predictedTime: Date?
        if let delay = json["\(prefix == "from" ? "dep" : "arr")Delay"].int {
            predictedTime = plannedTime.addingTimeInterval(TimeInterval(delay))
        } else {
            predictedTime = nil
        }
        let plannedPlatform = parsePosition(position: json["\(prefix)Platform"].string)
        let predictedPlatform = parsePosition(position: json["\(prefix)RealtimePlatform"].string)
        let cancelled = json["\(prefix)Cancelled"].boolValue
        
        return StopEvent(location: location, plannedTime: plannedTime, predictedTime: predictedTime, plannedPlatform: plannedPlatform, predictedPlatform: predictedPlatform, cancelled: cancelled)
    }
    
    private func jsonDesiredTypes(products: [Product]?) -> String? {
        var result: [String] = []
        for product in Set(Product.allCases).subtracting(products ?? Product.allCases) {
            switch product {
            case .highSpeedTrain: result.append("fasttrain&extrafasttrain")
            case .regionalTrain: result.append("r")
            case .suburbanTrain: result.append("s")
            case .subway: result.append("u")
            case .tram: continue
            case .bus: result.append("bus")
            case .onDemand: result.append("callable")
            case .ferry: result.append("ship")
            case .cablecar: continue
            }
        }
        return result.joined(separator: ",").emptyToNil
    }
    
    private func getAuthHeaders(_ request: String?) -> [String: String]? {
        guard var headers = self.authHeaders as? [String: String] else { return nil }
        guard let input = request, let key = headers["geofox-auth-signature"] else { return nil }
        
        headers["geofox-auth-signature"] = input.hmacSha1(key: key).base64
        return headers
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
        public let laterContext: [String: Any]?
        public let earlierContext: [String: Any]?
        public let tripOptions: TripOptions
        
        init(from: Location, via: Location?, to: Location, date: Date, departure: Bool, laterContext: [String: Any]?, earlierContext: [String: Any]?, tripOptions: TripOptions) {
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
            let laterContext = aDecoder.decodeObject(of: [NSDictionary.self, NSString.self, NSNumber.self], forKey: PropertyKey.laterContext) as? [String: Any]
            let earlierContext = aDecoder.decodeObject(of: [NSDictionary.self, NSString.self, NSNumber.self], forKey: PropertyKey.earlierContext) as? [String: Any]
            
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

public class HvvJourneyContext: QueryJourneyDetailContext {
    
    public override class var supportsSecureCoding: Bool { return true }
    
    public let lineKey: String
    public let serviceId: Int
    public let station: Location
    public let stationTime: Date
    public let line: Line
    
    public init(lineKey: String, serviceId: Int, station: Location, stationTime: Date, line: Line) {
        self.lineKey = lineKey
        self.serviceId = serviceId
        self.station = station
        self.stationTime = stationTime
        self.line = line
        super.init()
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard
            let lineKey = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.lineKey) as String?,
            let station = aDecoder.decodeObject(of: Location.self, forKey: PropertyKey.station),
            let stationTime = aDecoder.decodeObject(of: NSDate.self, forKey: PropertyKey.stationTime) as Date?,
            let line = aDecoder.decodeObject(of: Line.self, forKey: PropertyKey.line)
        else { return nil }
        let serviceId = aDecoder.decodeInteger(forKey: PropertyKey.serviceId)
        self.init(lineKey: lineKey, serviceId: serviceId, station: station, stationTime: stationTime, line: line)
    }
    
    public override func encode(with aCoder: NSCoder) {
        aCoder.encode(lineKey, forKey: PropertyKey.lineKey)
        aCoder.encode(serviceId, forKey: PropertyKey.serviceId)
        aCoder.encode(station, forKey: PropertyKey.station)
        aCoder.encode(stationTime, forKey: PropertyKey.stationTime)
        aCoder.encode(line, forKey: PropertyKey.line)
    }
    
    struct PropertyKey {
        static let lineKey = "lineKey"
        static let serviceId = "serviceId"
        static let station = "station"
        static let stationTime = "stationTime"
        static let line = "line"
    }
}


