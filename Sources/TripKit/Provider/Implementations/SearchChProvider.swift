import Foundation
import SwiftyJSON

/// Search.ch (CH)
public class SearchChProvider: AbstractNetworkProvider {
    
    /// Documentation: https://fahrplan.search.ch/api/help
    /// Thanks a lot to @sirtoobii for his work on the public-transport-enabler implementation
    static let API_BASE = "https://fahrplan.search.ch/api/"

    public override var supportedLanguages: Set<String> { ["de", "en", "fr", "it"] }
    
    var P_SPLIT_NAME_FIRST_COMMA: NSRegularExpression { return try! NSRegularExpression(pattern: "^(?:([^,]*), (?!$))?([^,]*)(?:, )?$") }
    
    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = "MM/dd/yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    lazy var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    lazy var datetimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    public init() {
        super.init(networkId: .SEARCHCH)
    }
    
    public override func suggestLocations(constraint: String, types: [LocationType]?, maxLocations: Int, completion: @escaping (HttpRequest, SuggestLocationsResult) -> Void) -> AsyncRequest {
        let urlBuilder = UrlBuilder(path: SearchChProvider.API_BASE + "completion.json", encoding: .utf8)
        urlBuilder.addParameter(key: "term", value: constraint)
        urlBuilder.addParameter(key: "show_ids", value: 1)
        urlBuilder.addParameter(key: "show_coordinates", value: 1)
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder).setHeaders(languageHeader)
        return makeRequest(httpRequest) {
            try self.suggestLocationsParsing(request: httpRequest, constraint: constraint, types: types, maxLocations: maxLocations, completion: completion)
        } errorHandler: { err in
            completion(httpRequest, .failure(err))
        }
    }
    
    override func suggestLocationsParsing(request: HttpRequest, constraint: String, types: [LocationType]?, maxLocations: Int, completion: @escaping (HttpRequest, SuggestLocationsResult) -> Void) throws {
        let json = try getResponse(from: request)
        
        var locations: [SuggestedLocation] = []
        for jsonLoc in json.arrayValue {
            guard let location = parseLocation(json: jsonLoc) else { continue }
            if let types = types, !types.contains(location.type) && !types.contains(.any) { continue }
            locations.append(SuggestedLocation(location: location, priority: 0))
        }
        completion(request, .success(locations: locations))
    }
    
    public override func queryNearbyLocations(location: Location, types: [LocationType]?, maxDistance: Int, maxLocations: Int, completion: @escaping (HttpRequest, NearbyLocationsResult) -> Void) -> AsyncRequest {
        guard let coord = location.coord else {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .invalidId)
            return AsyncRequest(task: nil)
        }
        
        let urlBuilder = UrlBuilder(path: SearchChProvider.API_BASE + "completion.json", encoding: .utf8)
        urlBuilder.addParameter(key: "latlon", value: "\(Double(coord.lat) / 1e6)\(Double(coord.lon) / 1e6)")
        urlBuilder.addParameter(key: "accuracy", value: maxDistance)
        urlBuilder.addParameter(key: "show_ids", value: 1)
        urlBuilder.addParameter(key: "show_coordinates", value: 1)
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder).setHeaders(languageHeader)
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
        let urlBuilder = UrlBuilder(path: SearchChProvider.API_BASE + "stationboard.json", encoding: .utf8)
        urlBuilder.addParameter(key: "stop", value: stationId)
        if let time = time {
            urlBuilder.addParameter(key: "date", value: dateFormatter.string(from: time))
            urlBuilder.addParameter(key: "time", value: timeFormatter.string(from: time))
        }
        urlBuilder.addParameter(key: "limit", value: maxDepartures)
        urlBuilder.addParameter(key: "show_tracks", value: 1)
        urlBuilder.addParameter(key: "show_trackchanges", value: 1)
        urlBuilder.addParameter(key: "show_delays", value: 1)
        urlBuilder.addParameter(key: "mode", value: departures ? "depart" : "arrival")
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder).setHeaders(languageHeader)
        return makeRequest(httpRequest) {
            try self.queryDeparturesParsing(request: httpRequest, stationId: stationId, departures: departures, time: time, maxDepartures: maxDepartures, equivs: equivs, completion: completion)
        } errorHandler: { err in
            completion(httpRequest, .failure(err))
        }
    }
    
    override func queryDeparturesParsing(request: HttpRequest, stationId: String, departures: Bool, time: Date?, maxDepartures: Int, equivs: Bool, completion: @escaping (HttpRequest, QueryDeparturesResult) -> Void) throws {
        let json = try getResponse(from: request)
        
        if let messages = json["messages"].array?.map({$0.stringValue}) {
            // TODO: handle all possible error languages
            completion(request, .failure(ParseError(reason: messages.joined(separator: "\n"))))
            return
        }
        
        guard let location = parseLocation(json: json["stop"]) else {
            completion(request, .invalidStation)
            return
        }
        let stationDeparture = StationDepartures(stopLocation: location, departures: [], lines: [])
        
        for jsonDep in json["connections"].arrayValue {
            guard let (plannedTime, predictedTime, cancelled) = parseTimes(plannedTimeString: jsonDep["time"].string, delayString: jsonDep["dep_delay"].string) else {
                throw ParseError(reason: "failed to parse time")
            }
            
            let id = jsonDep["*Z"].string
            let network = jsonDep["operator"].string
            let product = parseProduct(from: jsonDep["*G"].string)
            let label = jsonDep["line"].string
            let style = try style(from: jsonDep["color"].string)
            let line = Line(id: id, network: network, product: product, label: label, name: nil, number: nil, vehicleNumber: nil, style: style, attr: nil, message: nil, direction: nil)
            
            let destination = parseLocation(json: jsonDep["terminal"])
            let (plannedPlatform, predictedPlatform) = parsePlatforms(platformString: jsonDep["track"].string)
            
            if !cancelled {
                stationDeparture.departures.append(Departure(plannedTime: plannedTime, predictedTime: predictedTime, line: line, position: predictedPlatform, plannedPosition: plannedPlatform, destination: destination, journeyContext: nil, wagonSequenceContext: nil))
            }
        }
        
        completion(request, .success(departures: [stationDeparture]))
    }
    
    public override func queryTrips(from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        let urlBuilder = UrlBuilder(path: SearchChProvider.API_BASE + "route.json", encoding: .utf8)
        urlBuilder.addParameter(key: "from", value: from.id ?? from.name ?? from.getUniqueLongName())
        if let via = via {
            urlBuilder.addParameter(key: "via", value: via.id ?? via.name ?? via.getUniqueLongName())
        }
        urlBuilder.addParameter(key: "to", value: to.id ?? to.name ?? to.getUniqueLongName())
        urlBuilder.addParameter(key: "date", value: dateFormatter.string(from: date))
        urlBuilder.addParameter(key: "time", value: timeFormatter.string(from: date))
        urlBuilder.addParameter(key: "time_type", value: departure ? "depart" : "arrival")
        urlBuilder.addParameter(key: "show_trackchanges", value: 1)
        urlBuilder.addParameter(key: "show_delays", value: 1)
        urlBuilder.addParameter(key: "num", value: 6)
        
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder).setHeaders(languageHeader)
        return makeRequest(httpRequest) {
            try self.queryTripsParsing(request: httpRequest, from: from, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions, previousContext: nil, later: false, completion: completion)
        } errorHandler: { err in
            completion(httpRequest, .failure(err))
        }
    }
    
    override func queryTripsParsing(request: HttpRequest, from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions, previousContext: QueryTripsContext?, later: Bool, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) throws {
        let json = try getResponse(from: request)
        
        if let messages = json["messages"].array?.map({$0.stringValue}) {
            completion(request, .failure(ParseError(reason: messages.joined(separator: "\n"))))
            return
        }
        
        var trips: [Trip] = []
        for jsonTrip in json["connections"].arrayValue {
            var legs: [Leg] = []
            let jsonLegs = jsonTrip["legs"].arrayValue
            for (index, jsonLeg) in jsonLegs.enumerated() {
                if index == jsonLegs.count - 1 {
                    // We reached the final leg which is our destination (and identical with the "Exit" of the previous leg)
                    break
                }
                guard
                    let departure = try parseStop(json: jsonLeg).departure,
                    let arrival = try parseStop(json: jsonLeg["exit"]).arrival
                else {
                    throw ParseError(reason: "failed to parse leg from/to")
                }
                
                switch jsonLeg["type"].stringValue {
                case "walk":
                    legs.append(IndividualLeg(type: .WALK, departureTime: departure.predictedTime ?? departure.plannedTime, departure: departure.location, arrival: arrival.location, arrivalTime: arrival.predictedTime ?? arrival.plannedTime, distance: 0, path: []))
                default:
                    var intermediateStops: [Stop] = []
                    for jsonStop in jsonLeg["stops"].arrayValue {
                        intermediateStops.append(try parseStop(json: jsonStop))
                    }
                    
                    let id = jsonLeg["*Z"].string
                    let network = jsonLeg["operator"].string
                    let product = parseProduct(from: jsonLeg["*G"].string)
                    let label = jsonLeg["line"].string
                    let bgColor = LineStyle.parseColor(try expandHex(jsonLeg["bgColor"].string ?? "fff"))
                    let fgColor = LineStyle.parseColor(try expandHex(jsonLeg["fgColor"].string ?? "000"))
                    let style = LineStyle(shape: .rect, backgroundColor: bgColor, foregroundColor: fgColor)
                    let line = Line(id: id, network: network, product: product, label: label, name: nil, number: nil, vehicleNumber: nil, style: style, attr: nil, message: nil, direction: nil)
                    
                    let destination: Location?
                    if let destinationString = jsonLeg["terminal"].string {
                        let (place, name) = split(stationName: destinationString)
                        destination = Location(type: .station, id: destinationString, coord: nil, place: place, name: name)
                    } else {
                        destination = nil
                    }
                    
                    legs.append(PublicLeg(line: line, destination: destination, departure: departure, arrival: arrival, intermediateStops: intermediateStops, message: nil, path: [], journeyContext: nil, loadFactor: nil))
                }
            }
            
            trips.append(Trip(id: "", from: legs.first?.departure ?? from, to: legs.last?.arrival ?? to, legs: legs, fares: [], refreshContext: nil))
        }
        
        completion(request, .success(context: nil, from: from, via: via, to: to, trips: trips, messages: []))
    }
    
    // MARK: parse utils
    
    private var languageHeader: [String: String] {
        ["Accept-Language": queryLanguage ?? defaultLanguage]
    }
    
    private func parseLocation(json: JSON) -> Location? {
        let type = parseIconClass(from: json["iconclass"].string)
        var id = normalize(stationId: json["id"].string ?? json["stopid"].string)
        let coord: LocationPoint?
        if let lat = json["lat"].double, let lon = json["lon"].double {
            coord = LocationPoint(lat: Int(lat * 1e6), lon: Int(lon * 1e6))
        } else {
            coord = nil
        }
        let label = json["label"].string ?? json["name"].string
        let (place, name) = split(stationName: label)
        if id == nil {
            // you can use the label instead of the id in requests
            id = label
        }
        return Location(type: type, id: id, coord: coord, place: place, name: name)
    }
    
    private func parseIconClass(from string: String?) -> LocationType {
        switch string ?? "" {
        case "sl-icon-type-zug", "sl-icon-type-train", "sl-icon-type-express-train", "sl-icon-type-strain", "sl-icon-type-night-strain", "sl-icon-type-bus", "sl-icon-type-night-bus", "sl-icon-type-tram", "sl-icon-type-ship", "sl-icon-type-funicular", "sl-icon-type-cablecar":
            return .station
        case "sl-icon-type-adr", "sl-icon-type-position":
            return .address
        default:
            return .station
        }
    }
    
    /**
     Splits the station name into place and station name.
     - Parameter stationName: the display name of the station.
     - Returns: the place and name of the station.
     */
    func split(stationName: String?) -> (place: String?, name: String?) {
        guard let stationName = stationName else {
            return (nil, nil)
        }
        if let m = stationName.match(pattern: P_SPLIT_NAME_FIRST_COMMA) {
            return (m[0], m[1])
        }
        return (nil, stationName)
    }
    
    private func parseStop(json: JSON) throws -> Stop {
        guard let location = parseLocation(json: json) else {
            throw ParseError(reason: "failed to parse stop location")
        }
        
        let departure: StopEvent?
        if let (plannedTime, predictedTime, cancelled) = parseTimes(plannedTimeString: json["departure"].string, delayString: json["dep_delay"].string) {
            let (plannedPlatform, predictedPlatform) = parsePlatforms(platformString: json["track"].string)
            departure = StopEvent(location: location, plannedTime: plannedTime, predictedTime: predictedTime, plannedPlatform: plannedPlatform, predictedPlatform: predictedPlatform, cancelled: cancelled)
        } else {
            departure = nil
        }
        
        let arrival: StopEvent?
        if let (plannedTime, predictedTime, cancelled) = parseTimes(plannedTimeString: json["arrival"].string, delayString: json["arr_delay"].string) {
            let (plannedPlatform, predictedPlatform) = parsePlatforms(platformString: json["track"].string)
            arrival = StopEvent(location: location, plannedTime: plannedTime, predictedTime: predictedTime, plannedPlatform: plannedPlatform, predictedPlatform: predictedPlatform, cancelled: cancelled)
        } else {
            arrival = nil
        }
        
        return Stop(location: location, departure: departure, arrival: arrival, message: nil, wagonSequenceContext: nil)
    }
    
    private func addDelay(to time: Date, delay: String) -> Date? {
        guard let delayNum = Int(delay) else { return nil }
        return time.addingTimeInterval(TimeInterval(delayNum * 60))
    }
    
    private func parseProduct(from string: String?) -> Product? {
        switch string ?? "" {
        case "IC": return .highSpeedTrain
        case "ICE": return .highSpeedTrain
        case "IRE": return .regionalTrain
        case "TGV": return .highSpeedTrain
        case "RJX": return .highSpeedTrain // RailJetExpress
        case "IR": return .highSpeedTrain
        case "EC": return .highSpeedTrain
        case "RE": return .regionalTrain
        case "R": return .regionalTrain
        case "M": return .subway
        case "FUN": return .tram // Funicular railways
        case "CC": return .tram  // Also used for funicular railways
        case "B": return .bus
        case "S": return .suburbanTrain
        case "T": return .tram
        case "PB": return .cablecar
        case "GB": return .cablecar // Gondola Lift
        case "BAT": return .ferry
        default: return nil
        }
    }
    
    private func style(from color: String?) throws -> LineStyle {
        guard let colors = color?.components(separatedBy: "~"), colors.count >= 2 else {
            return super.lineStyle(network: nil, product: nil, label: nil)
        }
        let fgColor = colors[0].isEmpty ? LineStyle.black : LineStyle.parseColor(try expandHex(colors[0]))
        let bgColor = colors[1].isEmpty ? LineStyle.white : LineStyle.parseColor(try expandHex(colors[1]))
        return LineStyle(shape: .rect, backgroundColor: bgColor, foregroundColor: fgColor)
    }
            
    /// Expands shorthand hex "f0a" to "ff00aa" and adds "#" as prefix
    ///
    /// - Parameter hexValue: 3 or 6 character hex value
    /// - Returns Expanded and prefixed hex string
    private func expandHex(_ hexValue: String) throws -> String {
        if hexValue.count == 3 {
            return "#\(hexValue[0] + hexValue[0] + hexValue[1] + hexValue[1] + hexValue[2] + hexValue[2])"
        } else if hexValue.count == 6 {
            return "#\(hexValue)"
        } else {
            throw ParseError(reason: "hex value has more than six bytes: " + hexValue);
        }
    }
    
    private func parseTimes(plannedTimeString: String?, delayString: String?) -> (plannedTime: Date, predictedTime: Date?, cancelled: Bool)? {
        guard let plannedTimeString = plannedTimeString, let plannedTime = datetimeFormatter.date(from: plannedTimeString) else {
            return nil
        }
        let predictedTime: Date?
        if let delay = delayString {
            predictedTime = addDelay(to: plannedTime, delay: delay)
        } else {
            predictedTime = nil
        }
        return (plannedTime, predictedTime, delayString == "X")
    }
    
    private func parsePlatforms(platformString: String?) -> (plannedPlatform: String?, predictedPlatform: String?) {
        var plannedPlatform = platformString
        var predictedPlatform = platformString
        if let platform = platformString, platform.hasSuffix("!") {
            // platform changed
            plannedPlatform = "?"
            predictedPlatform = String(platform.dropLast())
        }
        return (plannedPlatform, predictedPlatform)
    }
    
}
