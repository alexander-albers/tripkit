import Foundation
import os.log
import SwiftyJSON
import CoreLocation
import MapKit

/// Schweizer Bundesbahnen (CH)
public class SbbProvider: AbstractNetworkProvider {
    
    /// Thanks a lot to @marudor! https://blog.marudor.de/SBB-Apis/
    /// This implementation however does not build anymore on the blog post, so certificate loading is no longer necessary.
    static let API_BASE = "https://active.vnext.app.sbb.ch/"
    static let GRAPH_QL = "https://graphql.www.sbb.ch/"
    static let USER_AGENT = "SBBmobile/12.21.2.71.master Android/14 (Google;Pixel 6)"
    
    public override var supportedLanguages: Set<String> { ["de-DE", "en-US", "fr-FR", "it-IT"] }
    
    private var apiKey: String
    // Random UUID serves as app token / correlation id
    private let appToken: String = UUID().uuidString
    
    private lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssxxx"
        dateFormatter.timeZone = timeZone
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateFormatter
    }()
    private lazy var dateFormatterDate: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = timeZone
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateFormatter
    }()
    private lazy var dateFormatterTime: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        dateFormatter.timeZone = timeZone
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateFormatter
    }()
    
    var P_SPLIT_NAME_FIRST_COMMA: NSRegularExpression { return try! NSRegularExpression(pattern: "^(?:([^,]*), (?!$))?([^,]*)(?:, )?$") }
    
    private lazy var timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    public init(apiKey: String) {
        self.apiKey = apiKey
        super.init(networkId: .SBB)
        
        styles = [
            "I": LineStyle(backgroundColor: LineStyle.rgb(236, 0, 0), foregroundColor: LineStyle.white),
            "R": LineStyle(backgroundColor: LineStyle.rgb(236, 0, 0), foregroundColor: LineStyle.white)
        ]
        
        do {
            let identity = try Bundle.module.cert(named: "sbb-certificate", ext: "crt")
            HttpClient.cacheRootCertificate(for: "active.vnext.app.sbb.ch", certificate: identity)
        } catch let error as NSError {
            os_log("SBB: failed to load client certificate, http requests might not work! %{public}@", log: .requestLogger, type: .error, error.description)
        }
    }
    
    public override func suggestLocations(constraint: String, types: [LocationType]?, maxLocations: Int, completion: @escaping (HttpRequest, SuggestLocationsResult) -> Void) -> AsyncRequest {
        let urlBuilder = UrlBuilder(path: SbbProvider.API_BASE + "api/timetable/v1/places", encoding: .utf8)
        urlBuilder.addParameter(key: "searchText", value: constraint)
        appendPlaceTypes(types, to: urlBuilder)
        urlBuilder.addParameter(key: "maxResults", value: maxLocations)
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder).setUserAgent(SbbProvider.USER_AGENT).setHeaders(getHeaders(urlBuilder))
        return makeRequest(httpRequest) {
            try self.suggestLocationsParsing(request: httpRequest, constraint: constraint, types: types, maxLocations: maxLocations, completion: completion)
        } errorHandler: { err in
            completion(httpRequest, .failure(err))
        }
    }
    
    override func suggestLocationsParsing(request: HttpRequest, constraint: String, types: [LocationType]?, maxLocations: Int, completion: @escaping (HttpRequest, SuggestLocationsResult) -> Void) throws {
        let json = try getResponse(from: request)
        
        var locations: [SuggestedLocation] = []
        for (_, locJSON) in json["places"] {
            guard let location = parseLocation(json: locJSON) else { continue }
            if let types = types, !types.contains(location.type) && !types.contains(.any) { continue }
            locations.append(SuggestedLocation(location: location, priority: 0))
        }
        
        locations = Array(locations.prefix(maxLocations))
        
        completion(request, .success(locations: locations))
    }
    
    public override func queryNearbyLocations(location: Location, types: [LocationType]?, maxDistance: Int, maxLocations: Int, completion: @escaping (HttpRequest, NearbyLocationsResult) -> Void) -> AsyncRequest {
        guard let coord = location.coord else {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .invalidId)
            return AsyncRequest(task: nil)
        }
        
        let urlBuilder = UrlBuilder(path: SbbProvider.API_BASE + "api/timetable/v1/positions/\(Double(coord.lat) / 1e6)/\(Double(coord.lon) / 1e6)/places", encoding: .utf8)
        appendPlaceTypes(types, to: urlBuilder)
        urlBuilder.addParameter(key: "radiusInMeter", value: maxDistance)
        urlBuilder.addParameter(key: "maxResults", value: min(50, maxLocations))
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder).setUserAgent(SbbProvider.USER_AGENT).setHeaders(getHeaders(urlBuilder))
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
        let urlBuilder = UrlBuilder(path: SbbProvider.API_BASE + "api/timetable/v1/departure-boards", encoding: .utf8)
        urlBuilder.addParameter(key: "departureStopPlaceName", value: "_") // needs just any arbitrary name
        urlBuilder.addParameter(key: "departureStopPlaceReference", value: stationId)
        urlBuilder.addParameter(key: "departureDateTimeType", value: departures ? "DEPARTURE" : "ARRIVAL")
        if let time = time {
            appendTime(time, to: urlBuilder, parameterName: "departureDateTime")
        }
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder).setUserAgent(SbbProvider.USER_AGENT).setHeaders(getHeaders(urlBuilder))
        return makeRequest(httpRequest) {
            try self.queryDeparturesParsing(request: httpRequest, stationId: stationId, departures: departures, time: time, maxDepartures: maxDepartures, equivs: equivs, completion: completion)
        } errorHandler: { err in
            completion(httpRequest, .failure(err))
        }
    }
    
    override func queryDeparturesParsing(request: HttpRequest, stationId: String, departures: Bool, time: Date?, maxDepartures: Int, equivs: Bool, completion: @escaping (HttpRequest, QueryDeparturesResult) -> Void) throws {
        let json = try getResponse(from: request)
        
        var departures: [Departure] = []
        for departureJson in json["departures"].arrayValue {
            guard let plannedTime = parseTime(from: departureJson["departureDateTime"]) else {
                throw ParseError(reason: "failed to parse departure time")
            }
            let line = parseLine(from: departureJson["transportDesignation"])
            let position = departureJson["quayDisplayName"].string
            let destination: Location?
            if let destinationName = departureJson["directionDisplayTitle"].string {
                destination = Location(anyName: destinationName)
            } else {
                destination = nil
            }
            let journeyContext: QueryJourneyDetailContext?
            if let url = departureJson["itineraryUrl"].string {
                journeyContext = SbbJourneyContext(urlPath: url)
            } else {
                journeyContext = nil
            }
            
            departures.append(Departure(plannedTime: plannedTime, predictedTime: nil, line: line, position: nil, plannedPosition: position, cancelled: false, destination: destination, journeyContext: journeyContext))
        }
        if departures.isEmpty {
            completion(request, .invalidStation)
        } else {
            let stationDepartures = StationDepartures(stopLocation: Location(id: stationId), departures: departures, lines: [])
            completion(request, .success(departures: [stationDepartures]))
        }
    }
    
    public override func queryJourneyDetail(context: QueryJourneyDetailContext, completion: @escaping (HttpRequest, QueryJourneyDetailResult) -> Void) -> AsyncRequest {
        guard let context = context as? SbbJourneyContext else {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .invalidId)
            return AsyncRequest(task: nil)
        }
        let urlBuilder = UrlBuilder(path: SbbProvider.API_BASE + context.urlPath, encoding: .utf8)
        let httpRequest = HttpRequest(urlBuilder: urlBuilder).setUserAgent(SbbProvider.USER_AGENT).setHeaders(getHeaders(urlBuilder))
        return makeRequest(httpRequest) {
            try self.queryJourneyDetailParsing(request: httpRequest, context: context, completion: completion)
        } errorHandler: { err in
            completion(httpRequest, .failure(err))
        }
    }
    
    override func queryJourneyDetailParsing(request: HttpRequest, context: QueryJourneyDetailContext, completion: @escaping (HttpRequest, QueryJourneyDetailResult) -> Void) throws {
        let json = try getResponse(from: request)
        
        let line = parseLine(from: json["ptRideLegHeader", "transportDesignation"])
        let destination: Location?
        if let destinationName = json["ptRideLegHeader", "direction"].string {
            destination = Location(anyName: destinationName)
        } else {
            destination = nil
        }
        
        var stops: [Stop] = []
        var maxLoadFactor: LoadFactor? = nil
        for stopJson in json["stopPoints"].arrayValue {
            let loadFactor = parseLoadFactor(from: stopJson["occupancySecondClass"])
            if maxLoadFactor == nil || (loadFactor != nil && loadFactor!.rawValue > maxLoadFactor!.rawValue) {
                maxLoadFactor = loadFactor
            }
            
            let location = Location(anyName: stopJson["displayName"].string)
            let stopEvent = parseStopPoint(stopJson: stopJson)
            let stop = Stop(location: location, departure: stopJson["departureTime"].exists() ? stopEvent : nil, arrival: stopJson["arrivalTime"].exists() ? stopEvent : nil, message: nil)
            stops.append(stop)
        }
        guard let departure = stops.removeFirst().departure, let arrival = stops.removeLast().arrival else {
            throw ParseError(reason: "failed to parse first/last stop")
        }
        
        let leg = PublicLeg(line: line, destination: destination, departure: departure, arrival: arrival, intermediateStops: stops, message: nil, path: [], journeyContext: context, wagonSequenceContext: nil, loadFactor: maxLoadFactor)
        let trip = Trip(id: "", from: departure.location, to: arrival.location, legs: [leg], duration: arrival.time.timeIntervalSince(departure.time), fares: [])
        completion(request, .success(trip: trip, leg: leg))
    }
    
    public override func queryTrips(from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        let urlBuilder = UrlBuilder(path: SbbProvider.API_BASE + "api/timetable/v1/trips", encoding: .utf8)
        appendTripsParameters(to: urlBuilder, from: from, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions)
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder).setUserAgent(SbbProvider.USER_AGENT).setHeaders(getHeaders(urlBuilder))
        return makeRequest(httpRequest) {
            try self.queryTripsParsing(request: httpRequest, from: from, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions, previousContext: nil, later: false, completion: completion)
        } errorHandler: { err in
            if let err = err as? HttpError, case .invalidStatusCode(_, _) = err {
                guard let json = try? self.getResponse(from: httpRequest) else {
                    completion(httpRequest, .failure(err))
                    return
                }
                print(json)
                        
                switch json["serviceErrorCode"].stringValue {
                case "JIS-1000":
                    completion(httpRequest, .noTrips)
                case "JIS-2003":
                    completion(httpRequest, .noTrips)
                case "JIS-2004":
                    completion(httpRequest, .tooClose)
                default:
                    completion(httpRequest, .failure(err))
                }
            } else {
                completion(httpRequest, .failure(err))
            }
        }
    }
    
    private func appendTripsParameters(to urlBuilder: UrlBuilder, from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions) {
        appendLocation(from, to: urlBuilder, prefix: "departure")
        appendLocation(to, to: urlBuilder, prefix: "arrival")
        if let via = via {
            appendLocation(via, to: urlBuilder, prefix: "via", suffix: "0")
        }
        urlBuilder.addParameter(key: "searchDate", value: dateFormatterDate.string(from: date))
        urlBuilder.addParameter(key: "searchTime", value: dateFormatterTime.string(from: date))
        urlBuilder.addParameter(key: "searchDateTimeType", value: departure ? "DEPARTURE" : "ARRIVAL")
        if tripOptions.options?.contains(.bike) ?? false {
            urlBuilder.addParameter(key: "noticeAttributes", value: "BIKE_TRANSPORT")
        }
        if let products = tripOptions.products, !products.isEmpty {
            var productsString: [String] = []
            for product in products {
                switch product {
                case .highSpeedTrain:
                    productsString.append("HIGH_SPEED_TRAIN")
                    productsString.append("INTERCITY")
                    productsString.append("SPECIAL_TRAIN")
                case .regionalTrain:
                    productsString.append("INTERREGIO")
                    productsString.append("REGIO")
                case .suburbanTrain:
                    productsString.append("URBAN_TRAIN")
                case .bus:
                    productsString.append("BUS")
                case .ferry:
                    productsString.append("SHIP")
                case .cablecar:
                    productsString.append("CABLEWAY_GONDOLA_CHAIRLIFT_FUNICULAR")
                case .tram:
                    productsString.append("TRAMWAY")
                default:
                    break
                }
            }
            urlBuilder.addParameter(key: "transportModes", value: productsString.joined(separator: ","))
        }
    }
    
    override func queryTripsParsing(request: HttpRequest, from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions, previousContext: QueryTripsContext?, later: Bool, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) throws {
        let json = try getResponse(from: request)
        
        var trips: [Trip] = []
        let geoDispatchGroup = DispatchGroup()
        for tripJson in json["trips"].arrayValue {
            try parseTrip(from: tripJson, dispatchGroup: geoDispatchGroup) { trip in
                trips.append(trip)
            }
        }
        
        let previousContext = previousContext as? SbbTripsContext
        let laterContext = later ? json["laterPagingCursor"].string : previousContext?.laterContext ?? json["laterPagingCursor"].string
        let earlierContext = !later ? json["earlierPagingCursor"].string : previousContext?.laterContext ?? json["earlierPagingCursor"].string
        let context = SbbTripsContext(from: from, via: via, to: to, date: date, departure: departure, laterContext: laterContext, earlierContext: earlierContext, tripOptions: tripOptions)
        
        geoDispatchGroup.notify(queue: .global()) {
            if trips.isEmpty {
                completion(request, .noTrips)
                return
            }
            completion(request, .success(context: context, from: nil, via: nil, to: nil, trips: trips, messages: []))
        }
    }
    
    public override func queryMoreTrips(context: QueryTripsContext, later: Bool, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        guard let context = context as? SbbTripsContext else {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .noTrips)
            return AsyncRequest(task: nil)
        }
        let urlBuilder = UrlBuilder(path: SbbProvider.API_BASE + "api/timetable/v1/trips", encoding: .utf8)
        appendTripsParameters(to: urlBuilder, from: context.from, via: context.via, to: context.to, date: context.date, departure: context.departure, tripOptions: context.tripOptions)
        urlBuilder.addParameter(key: "pagingCursor", value: later ? context.laterContext : context.earlierContext)
        let httpRequest = HttpRequest(urlBuilder: urlBuilder).setUserAgent(SbbProvider.USER_AGENT).setHeaders(getHeaders(urlBuilder))
        return makeRequest(httpRequest) {
            try self.queryTripsParsing(request: httpRequest, from: context.from, via: context.via, to: context.to, date: context.date, departure: context.departure, tripOptions: context.tripOptions, previousContext: context, later: later, completion: completion)
        } errorHandler: { err in
            completion(httpRequest, .failure(err))
        }
    }
    
    public override func refreshTrip(context: RefreshTripContext, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        guard let context = context as? SbbRefreshTripContext else {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .noTrips)
            return AsyncRequest(task: nil)
        }
        let urlBuilder = UrlBuilder(path: SbbProvider.API_BASE + "api/timetable/v1/trips/\(context.tripId)", encoding: .utf8)
        let httpRequest = HttpRequest(urlBuilder: urlBuilder).setUserAgent(SbbProvider.USER_AGENT).setHeaders(getHeaders(urlBuilder))
        return makeRequest(httpRequest) {
            try self.refreshTripParsing(request: httpRequest, context: context, completion: completion)
        } errorHandler: { err in
            completion(httpRequest, .failure(err))
        }
    }
    
    override func refreshTripParsing(request: HttpRequest, context: RefreshTripContext, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) throws {
        let json = try getResponse(from: request)
        try parseTrip(from: json) { trip in
            completion(request, .success(context: nil, from: trip.from, via: nil, to: trip.to, trips: [trip], messages: []))
        }
    }
    
    public override func queryWagonSequence(context: QueryWagonSequenceContext, completion: @escaping (HttpRequest, QueryWagonSequenceResult) -> Void) -> AsyncRequest {
        guard let context = context as? SbbWagonSequenceContext else {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .invalidId)
            return AsyncRequest(task: nil)
        }
        let urlBuilder = UrlBuilder(path: SbbProvider.API_BASE + context.urlPath, encoding: .utf8)
        let httpRequest = HttpRequest(urlBuilder: urlBuilder).setUserAgent(SbbProvider.USER_AGENT).setHeaders(getHeaders(urlBuilder))
        return makeRequest(httpRequest) {
            try self.queryWagonSequenceParsing(request: httpRequest, context: context, completion: completion)
        } errorHandler: { err in
            completion(httpRequest, .failure(err))
        }
    }
    
    override func queryWagonSequenceParsing(request: HttpRequest, context: QueryWagonSequenceContext, completion: @escaping (HttpRequest, QueryWagonSequenceResult) -> Void) throws {
        let json = try getResponse(from: request)
        
        let wagonSize = 20.0
        var sectors: [StationTrackSector] = []
        
        var travelDirection: WagonSequence.TravelDirection? = nil
        switch json["departure", "operationalOrientation"].stringValue {
        case "LEFT": travelDirection = .left
        case "RIGHT": travelDirection = .right
        default: travelDirection = nil
        }
        var wagonGroups: [WagonGroup] = []
        for wagonGroupJson in json["departure", "trains"].arrayValue {
            var wagons: [Wagon] = []
            for wagonJson in wagonGroupJson["trainComponents"].arrayValue {
                let number = Int(wagonJson["label"].stringValue)
                
                let sectorName = wagonJson["boardingPosition"].stringValue
                let start = sectors.last?.end ?? 0
                let trackPosition = StationTrackSector(sectorName: sectorName, start: start, end: start + wagonSize)
                if let lastSector = sectors.last, lastSector.sectorName == sectorName {
                    sectors.removeLast()
                    sectors.append(StationTrackSector(sectorName: sectorName, start: lastSector.start, end: lastSector.end + wagonSize))
                } else {
                    sectors.append(StationTrackSector(sectorName: sectorName, start: start, end: start + wagonSize))
                }
                
                let firstClass = wagonJson["trainElement", "passengerClass"].string == "FIRST"
                let secondClass = wagonJson["trainElement", "passengerClass"].string == "SECOND"
                var attributes: [WagonAttributes] = []
                for attributeStr in wagonJson["trainElement", "attributes"].arrayValue {
                    let attribute: WagonAttributes.`Type`?
                    switch attributeStr.stringValue {
                    case "AbteilKinderwagen": attribute = .cabinInfant
                    case "NiederflurEinstieg": attribute = .boardingAid
                    case "AbteilRollstuhl": attribute = .wheelchairSpace
                    case "AbteilVeloPl": attribute = .bikeSpace
                    default: attribute = nil
                    }
                    if let attribute = attribute {
                        attributes.append(WagonAttributes(attribute: attribute, state: .undefined))
                    }
                }
                
                let loadFactor = parseLoadFactor(from: wagonJson["occupancy"])
                wagons.append(Wagon(number: number, orientation: nil, trackPosition: trackPosition, attributes: attributes, firstClass: firstClass, secondClass: secondClass, loadFactor: loadFactor))
            }
            
            wagonGroups.append(WagonGroup(designation: "", wagons: wagons, destination: wagonGroupJson["direction"].string, lineLabel: nil))
        }
        guard !sectors.isEmpty, !wagonGroups.compactMap({$0.wagons}).isEmpty else {
            throw ParseError(reason: "failed to parse sectors or wagon groups")
        }
        
        let track = StationTrack(trackNumber: nil, start: sectors.first?.start ?? 0, end: sectors.last?.end ?? 0, sectors: sectors)
        
        completion(request, .success(wagonSequence: WagonSequence(travelDirection: travelDirection, wagonGroups: wagonGroups, track: track)))
    }
    
    private func queryPath(for tripId: String, legs: [Leg], completion: @escaping ([Leg]) -> Void) {
        let urlBuilder = UrlBuilder(path: SbbProvider.GRAPH_QL, encoding: .utf8)
        let payload = encodeJson(dict: [
            "operationName": "getGeoJsonByTripContext",
            "query": "query getGeoJsonByTripContext($context: String!, $language: LanguageEnum!) {\n  geoJsonByTripContext(context: $context, language: $language) {\n    features\n    bbox\n    __typename\n  }\n}",
            "variables": [
                "context": tripId,
                "language": "DE"
            ]
        ], requestUrlEncoding: .utf8)
        let httpRequest = HttpRequest(urlBuilder: urlBuilder).setPostPayload(payload)
        _ = makeRequest(httpRequest) {
            try self.parseGeoJsonResponse(request: httpRequest, legs: legs, completion: completion)
        } errorHandler: { err in
            completion(legs)
        }
    }
    
    private func parseGeoJsonResponse(request: HttpRequest, legs: [Leg], completion: @escaping ([Leg]) -> Void) throws {
        let json = try getResponse(from: request)
        let featuresJson = JSON(parseJSON: json["data", "geoJsonByTripContext", "features"].stringValue).arrayValue
        
        var newLegs: [Leg] = []
        
        let legIds = findInArray(featuresJson, predicate: ["legStart": JSON(booleanLiteral: true)]).map({$0["properties", "legId"].stringValue})
        
        for (idx, leg) in legs.enumerated() {
            guard let index = legIds[safe: idx] else { continue }
            var intermediatesJson = findInArray(featuresJson, predicate: [
                "legId": JSON(stringLiteral: index),
                "type": JSON(stringLiteral: "endpoint"),
            ])
            let departureJson = intermediatesJson.count > 0 ? intermediatesJson.removeFirst() : nil
            let departure = addCoordToLocation(leg.departure, locationJson: departureJson)
            let arrivalJson = intermediatesJson.count > 0 ? intermediatesJson.removeLast() : nil
            let arrival = addCoordToLocation(leg.arrival, locationJson: arrivalJson)
            
            switch leg {
            case let leg as PublicLeg:
                let pathJson = findInArray(featuresJson, predicate: [
                    "legId": JSON(stringLiteral: "\(index)"),
                    "type": JSON(stringLiteral: "path"),
                    "pathType": JSON(stringLiteral: "transport"),
                    "generalization": JSON(integerLiteral: 0),
                ]).last
                var path: [LocationPoint] = []
                for coordinatesTuple in pathJson?["geometry", "coordinates"].array ?? [] {
                    let coordinatesArray = coordinatesTuple.arrayValue
                    guard coordinatesArray.count == 2, let lat = coordinatesArray[1].double, let lon = coordinatesArray[0].double else { continue }
                    path.append(LocationPoint(lat: Int(lat * 1e6), lon: Int(lon * 1e6)))
                }
                
                var intermediateStops: [Stop] = []
                for stopJson in intermediatesJson {
                    let coord: LocationPoint?
                    let coordinatesArray = stopJson["geometry", "coordinates"].arrayValue
                    if coordinatesArray.count == 2, let lat = coordinatesArray[1].double, let lon = coordinatesArray[0].double {
                        coord = LocationPoint(lat: Int(lat * 1e6), lon: Int(lon * 1e6))
                    } else {
                        coord = nil
                    }
                    let id: String?
                    if let idInt = stopJson["properties", "sbb_id"].int {
                        id = "\(idInt)"
                    } else {
                        id = nil
                    }
                    if let location = Location(type: id == nil ? .any : .station, id: id, coord: coord, place: nil, name: stopJson["properties", "label"].string) {
                        intermediateStops.append(Stop(location: location, departure: nil, arrival: nil, message: nil))
                    }
                }
                
                newLegs.append(PublicLeg(line: leg.line, destination: leg.destination, departure: addLocationToStopEvent(leg.departureStop, location: departure)!, arrival: addLocationToStopEvent(leg.arrivalStop, location: arrival)!, intermediateStops: intermediateStops, message: leg.message, path: path, journeyContext: leg.journeyContext, wagonSequenceContext: leg.wagonSequenceContext, loadFactor: leg.loadFactor))
            case let leg as IndividualLeg:
                let pathJson = findInArray(featuresJson, predicate: [
                    "legId": JSON(stringLiteral: "\(index)"),
                    "type": JSON(stringLiteral: "path"),
                    "pathType": JSON(stringLiteral: "walk"),
                ]).last
                var path: [LocationPoint] = []
                for coordinatesTuple in pathJson?["geometry", "coordinates"].array ?? [] {
                    let coordinatesArray = coordinatesTuple.arrayValue
                    guard coordinatesArray.count == 2, let lat = coordinatesArray[1].double, let lon = coordinatesArray[0].double else { continue }
                    path.append(LocationPoint(lat: Int(lat * 1e6), lon: Int(lon * 1e6)))
                }
                
                newLegs.append(IndividualLeg(type: leg.type, departureTime: leg.departureTime, departure: departure, arrival: arrival, arrivalTime: leg.arrivalTime, distance: departureJson?["properties", "distanceInMeter"].int ?? 0, path: path))
            default:
                throw ParseError(reason: "unknown leg type")
            }
        }
        
        completion(newLegs)
    }
    
    private func findInArray(_ jsonArray: [JSON], predicate: [String: JSON]) -> [JSON] {
        var result: [JSON] = []
        for elem in jsonArray {
            var match = true
            for (key, value) in predicate {
                if elem["properties", key] != value {
                    match = false
                    break
                }
            }
            if match {
                result.append(elem)
            }
        }
        return result
    }
    
    private func addCoordToLocation(_ location: Location, locationJson: JSON?) -> Location {
        guard let locationJson = locationJson else { return location }
        let coordinates = locationJson["geometry", "coordinates"].arrayValue
        guard coordinates.count == 2, let lat = coordinates[1].double, let lon = coordinates[0].double else { return location }
        let coord = LocationPoint(lat: Int(lat * 1e6), lon: Int(lon * 1e6))
        return Location(type: location.type, id: location.id, coord: coord, place: location.place, name: location.name, products: location.products) ?? location
    }
    
    private func addLocationToStopEvent(_ stopEvent: StopEvent?, location: Location) -> StopEvent? {
        guard let stopEvent = stopEvent else { return nil }
        return StopEvent(location: location, plannedTime: stopEvent.plannedTime, predictedTime: stopEvent.predictedTime, plannedPlatform: stopEvent.plannedPlatform, predictedPlatform: stopEvent.predictedPlatform, cancelled: stopEvent.cancelled)
    }
    
    // MARK: parsing utils
    
    private func parseLocation(json: JSON) -> Location? {
        let type: LocationType
        switch json["placeType"].stringValue {
        case "STOP_PLACE":          type = .station
        case "POINT_OF_INTEREST":   type = .poi
        case "ADDRESS":             type = .address
        case "COORDINATES":         type = .coord
        default:                    type = .any
        }
        let id = normalize(stationId: json["identifier"].string)
        let (place, name) = split(stationName: json["displayName"].string ?? json["name"].string)
        
        let coord: LocationPoint?
        if let lat = json["coordinates", "latitude"].double, let lon = json["coordinates", "longitude"].double {
            coord = LocationPoint(lat: Int(lat * 1e6), lon: Int(lon * 1e6))
        } else {
            coord = nil
        }
        return Location(type: type, id: id, coord: coord, place: place, name: name)
    }
    
    private func parseStation(json: JSON) -> Location? {
        let id = normalize(stationId: json["placeReference"].string)
        let (place, name) = split(stationName: json["placeName"].string)
        
        let coord: LocationPoint?
        if let lat = json["placeCoordinates", "latitude"].double, let lon = json["placeCoordinates", "longitude"].double {
            coord = LocationPoint(lat: Int(lat * 1e6), lon: Int(lon * 1e6))
        } else {
            coord = nil
        }
        return Location(type: .station, id: id, coord: coord, place: place, name: name)
    }
    
    private func parseStopPoint(stopJson: JSON) -> StopEvent? {
        let location = Location(anyName: stopJson["displayName"].string)
        let plannedTime: Date?
        let predictedTime: Date?
        if stopJson["departureTime"].exists() {
            plannedTime = parseTime(from: stopJson["departureTime", "timeAimed"])
            predictedTime = parseTime(from: stopJson["departureTime", "timeExpected"])
        } else if stopJson["arrivalTime"].exists() {
            plannedTime = parseTime(from: stopJson["arrivalTime", "timeAimed"])
            predictedTime = parseTime(from: stopJson["arrivalTime", "timeExpected"])
        } else {
            plannedTime = nil
            predictedTime = nil
        }
        
        let position = stopJson["quay", "name"].string?.replacingOccurrences(of: "Pl. ", with: "").replacingOccurrences(of: "Gl. ", with: "")
        let positionChanged = stopJson["quay", "changed"].boolValue
        let plannedPosition = positionChanged && position != nil ? "?" : position
        let predictedPosition = positionChanged ? position : nil
        
        let stopEvent: StopEvent?
        if let plannedTime = plannedTime {
            stopEvent = StopEvent(location: location, plannedTime: plannedTime, predictedTime: predictedTime, plannedPlatform: plannedPosition, predictedPlatform: predictedPosition, cancelled: false)
        } else {
            stopEvent = nil
        }
        return stopEvent
    }
    
    private func parseTime(from json: JSON) -> Date? {
        guard let string = json.string, let time = dateFormatter.date(from: string) else {
            return nil
        }
        return time
    }
    
    private func parseLoadFactor(from json: JSON) -> LoadFactor? {
        switch json.stringValue {
        case "LOW": return .low
        case "MEDIUM": return .medium
        case "HIGH": return .high
        default: return nil
        }
    }
    
    private func parseLine(from json: JSON) -> Line {
        let product: Product?
        var label: String?
        switch json["vehicleType"].stringValue {
        case "CABLEWAY", "CHAIRLIFT", "LIFT", "COG_RAILWAY", "CABLECAR":
            product = .cablecar
        case "TAXI":
            product = .onDemand
        case "METRO":
            product = .subway
        case "TRAIN":
            switch json["transportInsignia", "identifier"].stringValue {
            case "IC", "EC", "ICE", "TGV":
                product = .highSpeedTrain
            case "IR", "RE", "TER":
                product = .regionalTrain
            case "S":
                product = .suburbanTrain
            default:
                product = .regionalTrain
            }
            label = json["transportInsignia", "displayName"].string
        case "TRAMWAY":
            product = .tram
        case "BUS":
            product = .bus
        case "BOAT":
            product = .ferry
        default:
            product = nil
        }
        
        let name = json["transportDisplayName"].string
        if label == nil {
            label = json["transportInsignia", "detail"].string ?? json["transportInsignia", "displayName"].string ?? name
        }
        label = label?.replacingOccurrences(of: " ", with: "")
        
        let number = json["transportExtraInfo"].string
        if let _label = label, let last = _label.last, let number = number, !last.isNumber {
            // some high speed trains do not contain the line number in the display name
            label = _label + number
        }
        
        return Line(id: nil, network: nil, product: product, label: label, name: name, vehicleNumber: number, style: lineStyle(network: nil, product: product, label: label), attr: nil, message: nil)
    }
    
    private func parseTrip(from tripJson: JSON, dispatchGroup: DispatchGroup? = nil, completion: @escaping (Trip) -> Void) throws {
        let id = tripJson["id"].stringValue
        
        let tripSummary = tripJson["tripSummary"]
        guard let from = parseStation(json: tripSummary["departureAnchor"]), let to = parseStation(json: tripSummary["arrivalAnchor"]) else {
            throw ParseError(reason: "failed to parse trip from/to")
        }
        
        var legs: [Leg] = []
        for legJson in tripJson["legs"].arrayValue {
            let legType = legJson["type"].stringValue
            switch legType {
            case "PtRideLeg":
                let line = parseLine(from: legJson["firstTransportDesignation"])
                let destination: Location?
                if let destinationName = legJson["direction"].string {
                    destination = Location(anyName: destinationName)
                } else {
                    destination = nil
                }
                guard let departure = parseStopPoint(stopJson: legJson["departureStopPoint"]) else {
                    throw ParseError(reason: "failed to parse leg departure")
                }
                guard let arrival = parseStopPoint(stopJson: legJson["arrivalStopPoint"]) else {
                    throw ParseError(reason: "failed to parse leg arrival")
                }
                let classText = "Second"
                let departureLoadFactor = parseLoadFactor(from: legJson["departureStopPoint", "occupancy\(classText)Class"])
                let arrivalLoadFactor = parseLoadFactor(from: legJson["arrivalStopPoint", "occupancy\(classText)Class"])
                let loadFactor: LoadFactor?
                if let departureLoadFactor = departureLoadFactor, let arrivalLoadFactor = arrivalLoadFactor {
                    loadFactor = LoadFactor(rawValue: max(departureLoadFactor.rawValue, arrivalLoadFactor.rawValue))
                } else if let departureLoadFactor = departureLoadFactor {
                    loadFactor = departureLoadFactor
                } else if let arrivalLoadFactor = arrivalLoadFactor {
                    loadFactor = arrivalLoadFactor
                } else {
                    loadFactor = nil
                }
                
                let journeyContext: SbbJourneyContext?
                if let urlPath = legJson["itineraryUrl"].string {
                    journeyContext = SbbJourneyContext(urlPath: urlPath)
                } else {
                    journeyContext = nil
                }
                let wagonSequenceContext: SbbWagonSequenceContext?
                if let urlPath = legJson["formationUrl"].string {
                    wagonSequenceContext = SbbWagonSequenceContext(urlPath: urlPath)
                } else {
                    wagonSequenceContext = nil
                }
                
                /*if prevChangeLeg, let last = legs.last {
                    legs.append(IndividualLeg(type: .transfer, departureTime: last.arrivalTime, departure: last.arrival, arrival: departure.location, arrivalTime: departure.time, distance: 0, path: []))
                    prevChangeLeg = false
                }*/
                
                legs.append(PublicLeg(line: line, destination: destination, departure: departure, arrival: arrival, intermediateStops: [], message: nil, path: [], journeyContext: journeyContext, wagonSequenceContext: wagonSequenceContext, loadFactor: loadFactor))
            case "ChangeLeg":
                break
            case "AccessLeg":
                let from = parseLocation(json: legJson["from"])
                let to = parseLocation(json: legJson["to"])
                let duration = TimeInterval(legJson["duration", "durationInMinutes"].intValue * 60)
                let time: Date?
                if let last = legs.last {
                    time = last.arrivalTime
                } else {
                    time = dateFormatter.date(from: tripSummary["departureAnchor", "timeExpected"].string ?? tripSummary["departureAnchor", "timeAimed"].string ?? "")?.addingTimeInterval(-duration)
                }
                guard let from = from, let to = to, let time = time else {
                    throw ParseError(reason: "failed to parse individual leg")
                }
                legs.append(IndividualLeg(type: .walk, departureTime: time, departure: from, arrival: to, arrivalTime: time.addingTimeInterval(duration), distance: 0, path: []))
            default:
                throw ParseError(reason: "unknown leg type \(legType)")
            }
        }
        let refreshContext: RefreshTripContext?
        if !id.isEmpty {
            refreshContext = SbbRefreshTripContext(tripId: id)
        } else {
            refreshContext = nil
        }
        let duration = tripSummary["duration", "durationInMinutes"].intValue
        
        dispatchGroup?.enter()
        queryPath(for: id, legs: legs) { newLegs in
            legs = newLegs
            dispatchGroup?.leave()
            completion(Trip(id: "", from: from, to: to, legs: legs, duration: TimeInterval(duration * 60), fares: [], refreshContext: refreshContext))
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
    
    private func getHeaders(_ urlBuilder: UrlBuilder) -> [String: String]? {
        guard let url = urlBuilder.build() else { return nil }
        var headers: [String: String] = [:]
        
        let timestamp = timestampFormatter.string(from: Date())
        headers["X-API-DATE"] = timestamp
        headers["X-APP-TOKEN"] = appToken
        
        let input = url.path + timestamp
        headers["X-API-AUTHORIZATION"] = input.hmacSha1(key: apiKey).base64
        
        headers["Accept-Language"] = queryLanguage
        
        return headers
    }
    
    private func appendTime(_ time: Date, to urlBuilder: UrlBuilder, parameterName: String) {
        urlBuilder.addParameter(key: parameterName, value: dateFormatter.string(from: time).replacingOccurrences(of: ":", with: "%3A").replacingOccurrences(of: "+", with: "%2B"), percentCoded: true)
    }
    
    private func appendLocation(_ location: Location, to urlBuilder: UrlBuilder, prefix: String, suffix: String = "") {
        urlBuilder.addParameter(key: "\(prefix)Name\(suffix)", value: location.getUniqueLongName())
        if let id = location.id {
            urlBuilder.addParameter(key: "\(prefix)Reference", value: id)
        } else if let coord = location.coord {
            urlBuilder.addParameter(key: "\(prefix)Reference", value: "[\(Double(coord.lon) / 1e6),\(Double(coord.lat) / 1e6)]")
        }
    }
    
    private func appendPlaceTypes(_ types: [LocationType]?, to urlBuilder: UrlBuilder) {
        if let types = types {
            var placeTypes: [String] = []
            for type in types {
                switch type {
                case .station: placeTypes.append("STOP_PLACE")
                case .poi: placeTypes.append("POINT_OF_INTEREST")
                case .address: placeTypes.append("ADDRESS")
                case .coord: placeTypes.append("COORDINATES")
                default: break
                }
            }
            urlBuilder.addParameter(key: "placeTypes", value: placeTypes.joined(separator: ","))
        }
    }
    
}

public class SbbTripsContext: QueryTripsContext {
    
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

public class SbbRefreshTripContext: RefreshTripContext {
    
    public override class var supportsSecureCoding: Bool { return true }
    
    public let tripId: String
    
    public init(tripId: String) {
        self.tripId = tripId
        super.init()
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let tripId = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.tripId) as String? else { return nil }
        self.init(tripId: tripId)
    }
    
    public override func encode(with aCoder: NSCoder) {
        aCoder.encode(tripId, forKey: PropertyKey.tripId)
    }
    
    struct PropertyKey {
        static let tripId = "tripId"
    }
}

public class SbbJourneyContext: QueryJourneyDetailContext {
    
    public override class var supportsSecureCoding: Bool { return true }
    
    public let urlPath: String
    
    public init(urlPath: String) {
        self.urlPath = urlPath
        super.init()
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let urlPath = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.urlPath) as String? else { return nil }
        self.init(urlPath: urlPath)
    }
    
    public override func encode(with aCoder: NSCoder) {
        aCoder.encode(urlPath, forKey: PropertyKey.urlPath)
    }
    
    struct PropertyKey {
        static let urlPath = "urlPath"
    }
}

public class SbbWagonSequenceContext: QueryWagonSequenceContext {
    
    public override class var supportsSecureCoding: Bool { return true }
    
    public let urlPath: String
    
    public init(urlPath: String) {
        self.urlPath = urlPath
        super.init()
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let urlPath = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.urlPath) as String? else { return nil }
        self.init(urlPath: urlPath)
    }
    
    public override func encode(with aCoder: NSCoder) {
        aCoder.encode(urlPath, forKey: PropertyKey.urlPath)
    }
    
    struct PropertyKey {
        static let urlPath = "urlPath"
    }
}
