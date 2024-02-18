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
    
    public override var supportedLanguages: Set<String> { ["de", "en", "fr", "it"] }
    
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
    private lazy var dateFormatterTime2: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
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
            if let url = departureJson["itineraryUrl"].string, let contextId = url.replacingOccurrences(of: "api/timetable/v1/itineraries/", with: "").replacingOccurrences(of: "?routeIndexFrom=0", with: "").decodeUrl(using: .utf8) {
                journeyContext = SbbJourneyContext(contextId: contextId)
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
        let urlBuilder = UrlBuilder(path: SbbProvider.GRAPH_QL, encoding: .utf8)
        let payload = encodeJson(dict: [
            "operationName": "getServiceJourneyById",
            "query": QueryJourneyDetailQuery,
            "variables": [
                "id": context.contextId,
                "language": queryLanguage?.uppercased() ?? defaultLanguage.uppercased()
            ]
        ], requestUrlEncoding: .utf8)
        let httpRequest = HttpRequest(urlBuilder: urlBuilder).setHeaders(["Apollographql-Client-Name": "sbb-webshop-3.15.0"]).setPostPayload(payload)
        return makeRequest(httpRequest) {
            try self.queryJourneyDetailParsing(request: httpRequest, context: context, completion: completion)
        } errorHandler: { err in
            completion(httpRequest, .failure(err))
        }
    }
    
    override func queryJourneyDetailParsing(request: HttpRequest, context: QueryJourneyDetailContext, completion: @escaping (HttpRequest, QueryJourneyDetailResult) -> Void) throws {
        let json = try getResponse(from: request)
        
        let leg = try parsePublicLeg(legJson: json["data", "serviceJourneyById"], legId: "0", tripId: nil, occupancyClass: "second")
        let trip = Trip(id: "", from: leg.departure, to: leg.arrival, legs: [leg], duration: leg.arrivalTime.timeIntervalSince(leg.departureTime), fares: [])
        completion(request, .success(trip: trip, leg: leg))
    }
    
    public override func queryTrips(from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        let urlBuilder = UrlBuilder(path: SbbProvider.GRAPH_QL, encoding: .utf8)
        let payload = encodeJson(dict: getGQLQueryTripsParameters(from: from, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions, pagingCursor: nil), requestUrlEncoding: .utf8)
        let httpRequest = HttpRequest(urlBuilder: urlBuilder).setHeaders(["Apollographql-Client-Name": "sbb-webshop-3.15.0"]).setPostPayload(payload)
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
    
    private func getGQLQueryTripsParameters(from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions, pagingCursor: String?) -> [String: Any] {
        return [
            "operationName": "getTrips",
            "query": QueryTripsQueryString,
            "variables": [
                "input": [
                    "places": [
                        encodeLocation(from),
                        encodeLocation(via),
                        encodeLocation(to),
                    ].compactMap({$0}),
                    "time": encodeDate(date, departure: departure),
                    "includeEconomic": true,
                    "directConnection": false,
                    "includeAccessibility": tripOptions.accessibility == .barrierFree ? "BOARDING_ALIGHTING_SELF" : tripOptions.accessibility == .limited ? "BOARDING_ALIGHTING_BY_NOTIFICATION" : "NONE",
                    "includeNoticeAttributes": tripOptions.options?.contains(.bike) ?? false ? ["BIKE_TRANSPORT"] : [],
                    "includeTransportModes": encodeProducts(tripOptions),
                    "includeUnsharp": false,
                    "occupancy": "ALL",
                    "walkSpeed": tripOptions.walkSpeed == .slow ? 200 : tripOptions.walkSpeed == .normal ? 150 : 100
                ],
                "language": queryLanguage?.uppercased() ?? defaultLanguage.uppercased(),
                "pagingCursor": pagingCursor as Any
            ]
        ]
    }
    
    private func encodeLocation(_ location: Location?) -> [String: Any]? {
        guard let location = location else { return nil }
        if let id = location.id {
            return [
                "type": "ID",
                "value": id
            ]
        } else if let coord = location.coord {
            return [
                "type": "COORDINATES",
                "value": "[\(Double(coord.lon) / 1e6),\(Double(coord.lat) / 1e6)]"
            ]
        } else {
            return [:]
        }
    }
    
    private func encodeDate(_ date: Date, departure: Bool) -> [String: Any] {
        return [
            "date": dateFormatterDate.string(from: date),
            "time": dateFormatterTime2.string(from: date),
            "type": departure ? "DEPARTURE" : "ARRIVAL"
        ]
    }
    
    private func encodeProducts(_ tripOptions: TripOptions) -> [String] {
        var productsString: [String] = []
        for product in tripOptions.products ?? Product.allCases {
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
        return productsString
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
            urlBuilder.addParameter(key: "transportModes", value: encodeProducts(tripOptions).joined(separator: ","))
        }
    }
    
    override func queryTripsParsing(request: HttpRequest, from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions, previousContext: QueryTripsContext?, later: Bool, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) throws {
        let json = try getResponse(from: request)["data", "trips"]
        
        var trips: [Trip] = []
        let geoDispatchGroup = DispatchGroup()
        for tripJson in json["trips"].arrayValue {
            try parseTrip(from: tripJson, occupancyClass: tripOptions.tariffProfile?.tariffClass == 1 ? "first" : "second", dispatchGroup: geoDispatchGroup) { trip in
                trips.append(trip)
            }
        }
        
        let previousContext = previousContext as? SbbTripsContext
        let laterContext = later ? json["paginationCursor", "next"].string : previousContext?.laterContext ?? json["paginationCursor", "next"].string
        let earlierContext = !later ? json["paginationCursor", "previous"].string : previousContext?.laterContext ?? json["paginationCursor", "previous"].string
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
        let urlBuilder = UrlBuilder(path: SbbProvider.GRAPH_QL, encoding: .utf8)
        let payload = encodeJson(dict: getGQLQueryTripsParameters(from: context.from, via: context.via, to: context.to, date: context.date, departure: context.departure, tripOptions: context.tripOptions, pagingCursor: later ? context.laterContext : context.earlierContext), requestUrlEncoding: .utf8)
        let httpRequest = HttpRequest(urlBuilder: urlBuilder).setHeaders(["Apollographql-Client-Name": "sbb-webshop-3.15.0"]).setPostPayload(payload)
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
        let urlBuilder = UrlBuilder(path: SbbProvider.GRAPH_QL, encoding: .utf8)
        let payload = encodeJson(dict: [
            "operationName": "getTripById",
            "query": RefreshTripQuery,
            "variables": [
                "tripId": context.tripId,
                "language": queryLanguage?.uppercased() ?? defaultLanguage.uppercased()
            ]
        ], requestUrlEncoding: .utf8)
        let httpRequest = HttpRequest(urlBuilder: urlBuilder).setHeaders(["Apollographql-Client-Name": "sbb-webshop-3.15.0"]).setPostPayload(payload)
        return makeRequest(httpRequest) {
            try self.refreshTripParsing(request: httpRequest, context: context, completion: completion)
        } errorHandler: { err in
            completion(httpRequest, .failure(err))
        }
    }
    
    override func refreshTripParsing(request: HttpRequest, context: RefreshTripContext, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) throws {
        let json = try getResponse(from: request)
        try parseTrip(from: json["data", "tripById"], occupancyClass: (context as! SbbRefreshTripContext).occupancyClass) { trip in
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
                "language": queryLanguage?.uppercased() ?? defaultLanguage.uppercased()
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
    
    private func gql_parsePlace(json: JSON) -> Location? {
        let id = json["id"].string
        let stationName = json["name"].string
        let coord: LocationPoint?
        if let lat = json["centroid", "latitude"].double, let lon = json["centroid", "longitude"].double {
            coord = LocationPoint(lat: Int(lat * 1e6), lon: Int(lon * 1e6))
        } else {
            coord = nil
        }
        let (place, name) = split(stationName: stationName)
        return Location(type: .station, id: id, coord: coord, place: place, name: name)
    }
    
    private func gql_parseStop(location: Location, json: JSON, cancelled: Bool) -> StopEvent? {
        let plannedTime = parseTime(from: json["time"])
        let delay = json["delay"].intValue
        let predictedTime = plannedTime?.addingTimeInterval(TimeInterval(delay * 60))
        let position = json["quayFormatted"].string
        let positionChanged = json["quayChanged"].boolValue
        let plannedPosition = positionChanged && position != nil ? "?" : position
        let predictedPosition = positionChanged ? position : nil
        
        let stopEvent: StopEvent?
        if let plannedTime = plannedTime {
            stopEvent = StopEvent(location: location, plannedTime: plannedTime, predictedTime: predictedTime, plannedPlatform: plannedPosition, predictedPlatform: predictedPosition, cancelled: cancelled)
        } else {
            stopEvent = nil
        }
        return stopEvent
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
    
    private func gql_parseLine(from json: JSON) -> Line {
        let product: Product?
        switch json["vehicleMode"].stringValue {
        case "CABLEWAY", "CHAIRLIFT", "LIFT", "COG_RAILWAY", "CABLECAR":
            product = .cablecar
        case "TAXI":
            product = .onDemand
        case "METRO":
            product = .subway
        case "TRAIN":
            switch json["vehicleSubModeShortName"].stringValue {
            case "IC", "EC", "ICE", "TGV":
                product = .highSpeedTrain
            case "IR", "RE", "TER":
                product = .regionalTrain
            case "S":
                product = .suburbanTrain
            default:
                product = .regionalTrain
            }
        case "TRAMWAY":
            product = .tram
        case "BUS":
            product = .bus
        case "BOAT":
            product = .ferry
        default:
            product = nil
        }
        
        var label = json["vehicleSubModeShortName"].stringValue
        let number = json["number"].string
        let line = json["line"].string
        if let line = line {
            label += line
        } else if let number = number {
            label += number
        }
        
        return Line(id: nil, network: nil, product: product, label: label, name: json["name"].string, vehicleNumber: number, style: lineStyle(network: nil, product: product, label: label), attr: nil, message: nil)
    }
    
    override func lineStyle(network: String?, product: Product?, label: String?) -> LineStyle {
        if product == .highSpeedTrain {
            if label?.starts(with: "TGV") ?? false {
                return LineStyle(shape: .rect, backgroundColor: LineStyle.white, backgroundColor2: 0, foregroundColor: LineStyle.parseColor("#034c9c"), borderColor: LineStyle.parseColor("#034c9c"))
            } else if label?.starts(with: "ICE") ?? false {
                return LineStyle(shape: .rect, backgroundColor: LineStyle.white, backgroundColor2: 0, foregroundColor: LineStyle.red, borderColor: LineStyle.red)
            }
        }
        return super.lineStyle(network: network, product: product, label: label)
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
    
    private func parseTrip(from tripJson: JSON, occupancyClass: String, dispatchGroup: DispatchGroup? = nil, completion: @escaping (Trip) -> Void) throws {
        let id = tripJson["id"].stringValue
        
        let tripSummary = tripJson["summary"]
        guard let from = gql_parsePlace(json: tripSummary["firstStopPlace"]), let to = gql_parsePlace(json: tripSummary["lastStopPlace"]) else {
            throw ParseError(reason: "failed to parse trip from/to")
        }
        
        var legs: [Leg] = []
        for legJson in tripJson["legs"].arrayValue {
            let legId = legJson["id"].stringValue
            let legType = legJson["__typename"].stringValue
            switch legType {
            case "PTRideLeg":
                legs.append(try parsePublicLeg(legJson: legJson["serviceJourney"], legId: legId, tripId: id, occupancyClass: occupancyClass))
            case "ChangeLeg":
                break
            case "AccessLeg", "PTConnectionLeg":
                let from = gql_parsePlace(json: legJson["start"])
                let to = gql_parsePlace(json: legJson["end"])
                let duration = TimeInterval(legJson["duration"].intValue * 60)
                let time: Date?
                if let last = legs.last {
                    time = last.arrivalTime
                } else if let departureTime = dateFormatter.date(from: tripSummary["departure", "time"].stringValue) {
                    let delay = tripSummary["departure", "delay"].intValue
                    time = departureTime.addingTimeInterval(TimeInterval(delay * 60)).addingTimeInterval(-duration)
                } else {
                    time = nil
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
            refreshContext = SbbRefreshTripContext(tripId: id, occupancyClass: occupancyClass)
        } else {
            refreshContext = nil
        }
        let duration = tripSummary["duration"].intValue
        
        /*dispatchGroup?.enter()
        queryPath(for: id, legs: legs) { newLegs in
            legs = newLegs
            dispatchGroup?.leave()
            completion(Trip(id: "", from: from, to: to, legs: legs, duration: TimeInterval(duration * 60), fares: [], refreshContext: refreshContext))
        }*/
        completion(Trip(id: "", from: from, to: to, legs: legs, duration: TimeInterval(duration * 60), fares: [], refreshContext: refreshContext))
    }
    
    private func parsePublicLeg(legJson: JSON, legId: String, tripId: String?, occupancyClass: String) throws -> PublicLeg {
        let line = gql_parseLine(from: legJson["serviceProducts", 0])
        let destination: Location?
        if let destinationName = legJson["direction"].string {
            destination = Location(anyName: destinationName)
        } else {
            destination = nil
        }
        
        var stops: [Stop] = []
        var maxOccupancy: LoadFactor? = nil
        let jsonStopPoints = legJson["stopPoints"].arrayValue
        for (index, stopJson) in jsonStopPoints.enumerated() {
            guard let location = gql_parsePlace(json: stopJson["place"]) else { continue }
            
            let status = stopJson["stopStatus"].string
            let statusMessage = stopJson["stopStatusFormatted"].string
            let forBoarding = stopJson["forBoarding"].boolValue
            let forAlighting = stopJson["forAlighting"].boolValue
            let isFirst = index == 0
            let isLast = index == jsonStopPoints.count - 1
            var cancelled = status == "CANCELLED" || status == "NOT_SERVICED"
            if (status == "END_PARTIAL_CANCELLATION" || !forAlighting) && isLast {
                cancelled = true
            } else if (status == "BEGIN_PARTIAL_CANCELLATION" || !forBoarding) && isFirst {
                cancelled = true
            } else if !forBoarding && !forAlighting {
                cancelled = true
            }
            
            let departure = gql_parseStop(location: location, json: stopJson["departure"], cancelled: cancelled)
            let arrival = gql_parseStop(location: location, json: stopJson["arrival"], cancelled: cancelled)
            
            let loadFactor = parseLoadFactor(from: stopJson["occupancy", "\(occupancyClass)Class"])
            if let loadFactor = loadFactor, maxOccupancy == nil || loadFactor.rawValue < maxOccupancy!.rawValue {
                maxOccupancy = loadFactor
            }
            
            stops.append(Stop(location: location, departure: departure, arrival: arrival, message: statusMessage))
        }
        guard stops.count >= 2 else { throw ParseError(reason: "failed to parse stops") }
        guard let departure = stops.removeFirst().departure else { throw ParseError(reason: "failed to parse leg departure") }
        guard let arrival = stops.removeLast().arrival else { throw ParseError(reason: "failed to parse leg arrival") }
        
        var messages = Set<String>()
        for situationJson in legJson["situations"].arrayValue {
            for broadcastJson in situationJson["broadcastMessages"].arrayValue {
                guard let detail = broadcastJson["detail"].string?.stripHTMLTags() else { continue }
                messages.insert(detail)
            }
        }
        if let cancelledText = legJson["serviceAlteration", "cancelledText"].string {
            messages.insert(cancelledText)
        }
        if let partiallyCancelledText = legJson["serviceAlteration", "partiallyCancelledText"].string {
            messages.insert(partiallyCancelledText)
        }
        if let reachableText = legJson["serviceAlteration", "reachableText"].string {
            messages.insert(reachableText)
        }
        if let redirectedText = legJson["serviceAlteration", "redirectedText"].string {
            messages.insert(redirectedText)
        }
        if let unplannedStopPointsText = legJson["serviceAlteration", "unplannedStopPointsText"].string {
            messages.insert(unplannedStopPointsText)
        }
        
        var attributes = Set<Line.Attr>()
        for noticeJson in legJson["notices"].arrayValue {
            let type = noticeJson["type"].stringValue
            if type == "ATTRIBUTE" {
                guard let name = noticeJson["name"].string else { continue }
                switch name {
                case "WR", "B", "MP": attributes.insert(.restaurant)
                case "VR", "VB": attributes.insert(.bicycleCarriage)
                case "WV", "FS": attributes.insert(.wifiAvailable)
                case "NF": attributes.insert(.wheelChairAccess)
                default: break
                }
            } else if type == "INFO" {
                guard var text = noticeJson["text", "template"].string else { continue }
                for arg in noticeJson["text", "arguments"].arrayValue {
                    guard let argKey = arg["type"].string, let argValue = arg["values", 0].string else { continue }
                    text = text.replacingOccurrences(of: argKey, with: argValue)
                }
                messages.insert(text)
            }
        }
        let newLine = Line(id: line.id, network: line.network, product: line.product, label: line.label, name: line.name, number: line.number, vehicleNumber: line.vehicleNumber, style: line.style, attr: attributes.isEmpty ? nil : Array(attributes), message: line.message)
        
        let journeyContext: SbbJourneyContext?
        if let serviceId = legJson["id"].string {
            journeyContext = SbbJourneyContext(contextId: serviceId)
        } else {
            journeyContext = nil
        }
        let wagonSequenceContext: SbbWagonSequenceContext?
        if let tripId = tripId, line.product == .highSpeedTrain || line.product == .regionalTrain || line.product == .suburbanTrain {
            wagonSequenceContext = SbbWagonSequenceContext(urlPath: "api/timetable/v1/trips/\(tripId)/\(legId)")
        } else {
            wagonSequenceContext = nil
        }
        
        /*if prevChangeLeg, let last = legs.last {
            legs.append(IndividualLeg(type: .transfer, departureTime: last.arrivalTime, departure: last.arrival, arrival: departure.location, arrivalTime: departure.time, distance: 0, path: []))
            prevChangeLeg = false
        }*/
        
        return PublicLeg(line: newLine, destination: destination, departure: departure, arrival: arrival, intermediateStops: stops, message: messages.joined(separator: "\n").emptyToNil, path: [], journeyContext: journeyContext, wagonSequenceContext: wagonSequenceContext, loadFactor: maxOccupancy)
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
        
        let lang = queryLanguage ?? defaultLanguage
        headers["Accept-Language"] = lang + "_" + lang.uppercased()
        
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
    
    private let QueryTripsQueryString = """
            query getTrips($input: TripInput!, $pagingCursor: String, $language: LanguageEnum!) {
              trips(tripInput: $input, pagingCursor: $pagingCursor, language: $language) {
                trips {
                  id
                  legs {
                    duration
                    id
                    ... on AccessLeg {
                      __typename
                      duration
                      distance
                      start {
                        __typename
                        id
                        name
                      }
                      end {
                        __typename
                        id
                        name
                      }
                    }
                    ... on PTConnectionLeg {
                      __typename
                      duration
                      start {
                        id
                        name
                        __typename
                      }
                      end {
                        id
                        name
                        __typename
                      }
                      notices {
                        ...NoticesFields
                        __typename
                      }
                    }
                    ... on AlternativeModeLeg {
                      __typename
                      mode
                      duration
                    }
                    ... on PTRideLeg {
                      __typename
                      duration
                      start {
                        id
                        name
                        centroid {
                          latitude
                          longitude
                          __typename
                        }
                        __typename
                      }
                      end {
                        id
                        name
                        centroid {
                          latitude
                          longitude
                          __typename
                        }
                        __typename
                      }
                      arrival {
                        ...ArrivalDepartureFields
                        __typename
                      }
                      departure {
                        ...ArrivalDepartureFields
                        __typename
                      }
                      serviceJourney {
                        id
                        stopPoints {
                          place {
                            id
                            name
                            centroid {
                              latitude
                              longitude
                              __typename
                            }
                            __typename
                          }
                          occupancy {
                            firstClass
                            secondClass
                            __typename
                          }
                          accessibilityBoardingAlighting {
                            limitation
                            name
                            description
                            assistanceService {
                              template
                              arguments {
                                type
                                values
                                __typename
                              }
                              __typename
                            }
                            __typename
                          }
                          stopStatus
                          stopStatusFormatted
                          arrival {
                            ...ArrivalDepartureFields
                          }
                          departure {
                            ...ArrivalDepartureFields
                          }
                          forBoarding
                          forAlighting
                          delayUndefined
                          __typename
                        }
                        serviceProducts {
                          name
                          line
                          number
                          vehicleMode
                          vehicleSubModeShortName
                          corporateIdentityIcon
                          routeIndexFrom
                          routeIndexTo
                          __typename
                        }
                        direction
                        serviceAlteration {
                          cancelled
                          cancelledText
                          partiallyCancelled
                          partiallyCancelledText
                          redirected
                          redirectedText
                          reachable
                          reachableText
                          delayText
                          unplannedStopPointsText
                          quayChangedText
                          __typename
                        }
                        situations {
                          cause
                          broadcastMessages {
                            id
                            priority
                            title
                            detail
                            detailShort
                            distributionPeriod {
                              startDate
                              endDate
                              __typename
                            }
                            audiences {
                              urls {
                                name
                                url
                                __typename
                              }
                              __typename
                            }
                            __typename
                          }
                          affectedStopPointFromIdx
                          affectedStopPointToIdx
                          __typename
                        }
                        notices {
                          ...NoticesFields
                          __typename
                        }
                        quayTypeName
                        quayTypeShortName
                        __typename
                      }
                    }
                    __typename
                  }
                  situations {
                    cause
                    broadcastMessages {
                      id
                      priority
                      title
                      detail
                      __typename
                    }
                    affectedStopPointFromIdx
                    affectedStopPointToIdx
                    __typename
                  }
                  notices {
                    ...NoticesFields
                    __typename
                  }
                  valid
                  isBuyable
                  summary {
                    duration
                    arrival {
                      ...ArrivalDepartureFields
                      __typename
                    }
                    arrivalWalk
                    lastStopPlace {
                      id
                      name
                      centroid {
                        latitude
                        longitude
                        __typename
                      }
                      __typename
                    }
                    tripStatus {
                      alternative
                      alternativeText
                      cancelledText
                      delayedUnknown
                      __typename
                    }
                    departure {
                      ...ArrivalDepartureFields
                      __typename
                    }
                    departureWalk
                    firstStopPlace {
                      id
                      name
                      centroid {
                        latitude
                        longitude
                        __typename
                      }
                      __typename
                    }
                    product {
                      name
                      line
                      number
                      vehicleMode
                      vehicleSubModeShortName
                      corporateIdentityIcon
                      __typename
                    }
                    direction
                    occupancy {
                      firstClass
                      secondClass
                      __typename
                    }
                    tripStatus {
                      cancelled
                      partiallyCancelled
                      delayed
                      delayedUnknown
                      quayChanged
                      __typename
                    }
                    boardingAlightingAccessibility {
                      name
                      limitation
                      description
                      assistanceService {
                        template
                        arguments {
                          type
                          values
                          __typename
                        }
                        __typename
                      }
                      __typename
                    }
                    international
                    __typename
                  }
                  searchHint
                  __typename
                }
                paginationCursor {
                  previous
                  next
                  __typename
                }
                __typename
              }
            }

            fragment NoticesFields on Notice {
              name
              text {
                template
                arguments {
                  type
                  values
                  __typename
                }
                __typename
              }
              type
              priority
              __typename
            }

            fragment ArrivalDepartureFields on ScheduledStopPointDetail {
              time
              delay
              delayText
              quayFormatted
              quayChanged
              quayChangedText
              __typename
            }
            """
            
    private let QueryJourneyDetailQuery = """
            query getServiceJourneyById($id: ID!, $language: LanguageEnum!) {
              serviceJourneyById(id: $id, language: $language) {
                id
                stopPoints {
                  stopStatus
                  stopStatusFormatted
                  requestStop
                  delayUndefined
                  arrival {
                    ...ArrivalDepartureFields
                    __typename
                  }
                  departure {
                    ...ArrivalDepartureFields
                    __typename
                  }
                  accessibilityBoardingAlighting {
                    limitation
                    name
                    __typename
                  }
                  occupancy {
                    firstClass
                    secondClass
                    __typename
                  }
                  place {
                    id
                    name
                    centroid {
                      latitude
                      longitude
                      __typename
                    }
                    __typename
                  }
                  forBoarding
                  forAlighting
                  __typename
                }
                serviceProducts {
                  name
                  line
                  number
                  vehicleMode
                  vehicleSubModeShortName
                  corporateIdentityIcon
                  routeIndexFrom
                  routeIndexTo
                  __typename
                }
                direction
                serviceAlteration {
                  cancelled
                  cancelledText
                  partiallyCancelled
                  partiallyCancelledText
                  redirected
                  redirectedText
                  reachable
                  reachableText
                  delayText
                  unplannedStopPointsText
                  quayChangedText
                  __typename
                }
                situations {
                  cause
                  broadcastMessages {
                    id
                    priority
                    title
                    detail
                    detailShort
                    distributionPeriod {
                      startDate
                      endDate
                      __typename
                    }
                    audiences {
                      urls {
                        name
                        url
                        __typename
                      }
                      __typename
                    }
                    __typename
                  }
                  affectedStopPointFromIdx
                  affectedStopPointToIdx
                  __typename
                }
                notices {
                  ...NoticesFields
                  __typename
                }
                __typename
              }
            }

            fragment NoticesFields on Notice {
              name
              text {
                template
                arguments {
                  type
                  values
                  __typename
                }
                __typename
              }
              type
              priority
              __typename
            }

            fragment ArrivalDepartureFields on ScheduledStopPointDetail {
              time
              delay
              delayText
              quayFormatted
              quayChanged
              quayChangedText
              __typename
            }
            """
    
    private let RefreshTripQuery = """
            query getTripById($tripId: ID!, $language: LanguageEnum!) {
              tripById(tripId: $tripId, language: $language) {
                id
                legs {
                  duration
                  id
                  ... on AccessLeg {
                    __typename
                    duration
                    distance
                    start {
                      __typename
                      id
                      name
                      centroid {
                        latitude
                        longitude
                        __typename
                      }
                    }
                    end {
                      __typename
                      id
                      name
                      centroid {
                        latitude
                        longitude
                        __typename
                      }
                    }
                  }
                  ... on PTConnectionLeg {
                    __typename
                    duration
                    start {
                      id
                      name
                      centroid {
                        latitude
                        longitude
                        __typename
                      }
                    }
                    end {
                      id
                      name
                      centroid {
                        latitude
                        longitude
                        __typename
                      }
                    }
                    notices {
                      ...NoticesFields
                    }
                  }
                  ... on AlternativeModeLeg {
                    __typename
                    mode
                    duration
                  }
                  ... on PTRideLeg {
                    __typename
                    duration
                    start {
                      id
                      name
                      centroid {
                        latitude
                        longitude
                        __typename
                      }
                    }
                    end {
                      id
                      name
                      centroid {
                        latitude
                        longitude
                        __typename
                      }
                    }
                    arrival {
                      ...ArrivalDepartureFields
                    }
                    departure {
                      ...ArrivalDepartureFields
                    }
                    serviceJourney {
                      id
                      stopPoints {
                        place {
                          __typename
                          id
                          name
                          centroid {
                            latitude
                            longitude
                            __typename
                          }
                        }
                        occupancy {
                          firstClass
                          secondClass
                        }
                        accessibilityBoardingAlighting {
                          limitation
                          name
                          description
                          assistanceService {
                            template
                            arguments {
                              type
                              values
                            }
                          }
                        }
                        stopStatus
                        stopStatusFormatted
                        arrival {
                          ...ArrivalDepartureFields
                        }
                        departure {
                          ...ArrivalDepartureFields
                        }
                        forBoarding
                        forAlighting
                      }
                      serviceProducts {
                        name
                        line
                        number
                        vehicleMode
                        vehicleSubModeShortName
                        corporateIdentityIcon
                        routeIndexFrom
                        routeIndexTo
                      }
                      direction
                      serviceAlteration {
                        cancelled
                        cancelledText
                        partiallyCancelled
                        partiallyCancelledText
                        redirected
                        redirectedText
                        reachable
                        reachableText
                        delayText
                        unplannedStopPointsText
                        quayChangedText
                      }
                      situations {
                        cause
                        broadcastMessages {
                          id
                          priority
                          title
                          detail
                          detailShort
                          distributionPeriod {
                            startDate
                            endDate
                          }
                          audiences {
                            urls {
                              name
                              url
                            }
                          }
                        }
                        affectedStopPointFromIdx
                        affectedStopPointToIdx
                      }
                      notices {
                        ...NoticesFields
                      }
                      quayTypeName
                      quayTypeShortName
                    }
                  }
                }
                situations {
                  cause
                  broadcastMessages {
                    id
                    priority
                    title
                    detail
                  }
                  affectedStopPointFromIdx
                  affectedStopPointToIdx
                }
                notices {
                  ...NoticesFields
                }
                valid
                isBuyable
                summary {
                  duration
                  arrival {
                    ...ArrivalDepartureFields
                  }
                  arrivalWalk
                  lastStopPlace {
                    id
                    name
                    centroid {
                      latitude
                      longitude
                      __typename
                    }
                  }
                  tripStatus {
                    alternative
                    alternativeText
                    cancelledText
                    delayedUnknown
                  }
                  departure {
                    ...ArrivalDepartureFields
                  }
                  departureWalk
                  firstStopPlace {
                    id
                    name
                    centroid {
                      latitude
                      longitude
                      __typename
                    }
                  }
                  product {
                    name
                    line
                    number
                    vehicleMode
                    vehicleSubModeShortName
                    corporateIdentityIcon
                  }
                  direction
                  occupancy {
                    firstClass
                    secondClass
                  }
                  tripStatus {
                    cancelled
                    partiallyCancelled
                    delayed
                    delayedUnknown
                    quayChanged
                  }
                  boardingAlightingAccessibility {
                    name
                    limitation
                    description
                    assistanceService {
                      template
                      arguments {
                        type
                        values
                      }
                    }
                  }
                  international
                }
                searchHint
              }
            }
            fragment NoticesFields on Notice {
              name
              text {
                template
                arguments {
                  type
                  values
                  __typename
                }
                __typename
              }
              type
              priority
              __typename
            }

            fragment ArrivalDepartureFields on ScheduledStopPointDetail {
              time
              delay
              delayText
              quayFormatted
              quayChanged
              quayChangedText
              __typename
            }
            """
    
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
    public let occupancyClass: String
    
    public init(tripId: String, occupancyClass: String) {
        self.tripId = tripId
        self.occupancyClass = occupancyClass
        super.init()
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let tripId = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.tripId) as String? else { return nil }
        guard let occupancyClass = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.occupancyClass) as String? else { return nil }
        self.init(tripId: tripId, occupancyClass: occupancyClass)
    }
    
    public override func encode(with aCoder: NSCoder) {
        aCoder.encode(tripId, forKey: PropertyKey.tripId)
        aCoder.encode(occupancyClass, forKey: PropertyKey.occupancyClass)
    }
    
    struct PropertyKey {
        static let tripId = "tripId"
        static let occupancyClass = "occupancyClass"
    }
}

public class SbbJourneyContext: QueryJourneyDetailContext {
    
    public override class var supportsSecureCoding: Bool { return true }
    
    public let contextId: String
    
    public init(contextId: String) {
        self.contextId = contextId
        super.init()
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let contextId = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.contextId) as String? else { return nil }
        self.init(contextId: contextId)
    }
    
    public override func encode(with aCoder: NSCoder) {
        aCoder.encode(contextId, forKey: PropertyKey.contextId)
    }
    
    struct PropertyKey {
        static let contextId = "contextId"
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
