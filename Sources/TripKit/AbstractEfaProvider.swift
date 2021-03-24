import Foundation
import os.log
import SWXMLHash
import SwiftyJSON

public class AbstractEfaProvider: AbstractNetworkProvider {
    
    override public var supportedQueryTraits: Set<QueryTrait> { return [.maxChanges] }
    
    let departureMonitorEndpoint: String
    let tripEndpoint: String
    let stopFinderEndpoint: String
    let coordEndpoint: String
    let tripStopTimesEndpoint: String
    let desktopTripEndpoint: String?
    let desktopDeparturesEndpoint: String?
    var supportsDesktopTrips: Bool = true
    var supportsDesktopDepartures: Bool = true
    var language = "de"
    
    static let DEFAULT_DEPARTURE_MONITOR_ENDPOINT = "XSLT_DM_REQUEST"
    static let DEFAULT_TRIP_ENDPOINT = "XSLT_TRIP_REQUEST2"
    static let DEFAULT_STOPFINDER_ENDPOINT = "XML_STOPFINDER_REQUEST"
    static let DEFAULT_COORD_ENDPOINT = "XML_COORD_REQUEST"
    static let DEFAULT_TRIPSTOPTIMES_ENDPOINT = "XML_STOPSEQCOORD_REQUEST"
    
    lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        dateFormatter.timeZone = timeZone
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateFormatter
    }()
    lazy var timeFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HHmm"
        dateFormatter.timeZone = timeZone
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateFormatter
    }()
    
    var includeRegionId: Bool = true
    var useRouteIndexAsTripId: Bool = true
    var requestUrlEncoding: String.Encoding = .utf8
    var needsSpEncId: Bool = false
    var useLineRestriction: Bool = true
    var useProxFootSearch: Bool = true
    
    init(networkId: NetworkId, departureMonitorEndpoint: String, tripEndpoint: String, stopFinderEndpoint: String, coordEndpoint: String, tripStopTimesEndpoint: String, desktopTripEndpoint: String? = nil, desktopDeparturesEndpoint: String? = nil) {
        self.departureMonitorEndpoint = departureMonitorEndpoint
        self.tripEndpoint = tripEndpoint
        self.stopFinderEndpoint = stopFinderEndpoint
        self.coordEndpoint = coordEndpoint
        self.tripStopTimesEndpoint = tripStopTimesEndpoint
        self.desktopTripEndpoint = desktopTripEndpoint
        self.desktopDeparturesEndpoint = desktopDeparturesEndpoint
        
        super.init(networkId: networkId)
    }
    
    init(networkId: NetworkId, apiBase: String, departureMonitorEndpoint: String?, tripEndpoint: String?, stopFinderEndpoint: String?, coordEndpoint: String?, tripStopTimesEndpoint: String?, desktopTripEndpoint: String? = nil, desktopDeparturesEndpoint: String? = nil) {
        self.departureMonitorEndpoint = apiBase + (departureMonitorEndpoint ?? AbstractEfaProvider.DEFAULT_DEPARTURE_MONITOR_ENDPOINT)
        self.tripEndpoint = apiBase + (tripEndpoint ?? AbstractEfaProvider.DEFAULT_TRIP_ENDPOINT)
        self.stopFinderEndpoint = apiBase + (stopFinderEndpoint ?? AbstractEfaProvider.DEFAULT_STOPFINDER_ENDPOINT)
        self.coordEndpoint = apiBase + (coordEndpoint ?? AbstractEfaProvider.DEFAULT_COORD_ENDPOINT)
        self.tripStopTimesEndpoint = apiBase + (tripStopTimesEndpoint ?? AbstractEfaProvider.DEFAULT_TRIPSTOPTIMES_ENDPOINT)
        self.desktopTripEndpoint = desktopTripEndpoint
        self.desktopDeparturesEndpoint = desktopDeparturesEndpoint
        
        super.init(networkId: networkId)
    }
    
    init(networkId: NetworkId, apiBase: String, desktopTripEndpoint: String? = nil, desktopDeparturesEndpoint: String? = nil) {
        self.departureMonitorEndpoint = apiBase + AbstractEfaProvider.DEFAULT_DEPARTURE_MONITOR_ENDPOINT
        self.tripEndpoint = apiBase + AbstractEfaProvider.DEFAULT_TRIP_ENDPOINT
        self.stopFinderEndpoint = apiBase + AbstractEfaProvider.DEFAULT_STOPFINDER_ENDPOINT
        self.coordEndpoint = apiBase + AbstractEfaProvider.DEFAULT_COORD_ENDPOINT
        self.tripStopTimesEndpoint = apiBase + AbstractEfaProvider.DEFAULT_TRIPSTOPTIMES_ENDPOINT
        self.desktopTripEndpoint = desktopTripEndpoint
        self.desktopDeparturesEndpoint = desktopDeparturesEndpoint
        
        super.init(networkId: networkId)
    }
    
    // MARK: NetworkProvider implementations – Requests
    
    override public func suggestLocations(constraint: String, types: [LocationType]?, maxLocations: Int, completion: @escaping (HttpRequest, SuggestLocationsResult) -> Void) -> AsyncRequest {
        let urlBuilder = UrlBuilder(path: stopFinderEndpoint, encoding: requestUrlEncoding)
        stopFinderRequestParameters(builder: urlBuilder, constraint: constraint, types: types, maxLocations: maxLocations, outputFormat: "JSON")
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder)
        return HttpClient.getJson(httpRequest: httpRequest) { result in
            switch result {
            case .success(let json):
                do {
                    try self.handleJsonStopfinderResponse(httpRequest: httpRequest, json: json, completion: completion)
                } catch let err as ParseError {
                    os_log("suggestLocations parse error: %{public}@", log: .requestLogger, type: .error, err.reason)
                    completion(httpRequest, .failure(err))
                } catch let err {
                    os_log("suggestLocations handle response error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                    completion(httpRequest, .failure(err))
                }
            case .failure(let err):
                os_log("suggestLocations network error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                completion(httpRequest, .failure(err))
            }
        }
    }
    
    override public func queryNearbyLocations(location: Location, types: [LocationType]?, maxDistance: Int, maxLocations: Int, completion: @escaping (HttpRequest, NearbyLocationsResult) -> Void) -> AsyncRequest {
        if let coord = location.coord {
            return coordRequest(types: types, lat: coord.lat, lon: coord.lon, maxDistance: maxDistance, maxLocations: maxLocations, completion: completion)
        } else if location.type == .station, let id = location.id {
            return nearbyStationsRequest(stationId: id, maxLocations: maxLocations, completion: completion)
        } else {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .invalidId)
            return AsyncRequest(task: nil)
        }
    }
    
    func nearbyStationsRequest(stationId: String, maxLocations: Int, completion: @escaping (HttpRequest, NearbyLocationsResult) -> Void) -> AsyncRequest {
        let urlBuilder = UrlBuilder(path: departureMonitorEndpoint, encoding: requestUrlEncoding)
        nearbyStationsRequestParameters(builder: urlBuilder, stationId: stationId, maxLocations: maxLocations)
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder)
        return HttpClient.getXml(httpRequest: httpRequest) { result in
            switch result {
            case .success(let xml):
                do {
                    try self.handleNearbyStationsRequest(httpRequest: httpRequest, xml: xml, maxLocations: maxLocations, completion: completion)
                } catch let err as ParseError {
                    os_log("nearbyStations parse error: %{public}@", log: .requestLogger, type: .error, err.reason)
                    completion(httpRequest, .failure(err))
                } catch let err {
                    os_log("nearbyStations handle response error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                    completion(httpRequest, .failure(err))
                }
            case .failure(let err):
                os_log("nearbyStations network error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                completion(httpRequest, .failure(err))
            }
        }
    }
    
    func coordRequest(types: [LocationType]?, lat: Int, lon: Int, maxDistance: Int, maxLocations: Int, completion: @escaping (HttpRequest, NearbyLocationsResult) -> Void) -> AsyncRequest {
        let urlBuilder = UrlBuilder(path: coordEndpoint, encoding: requestUrlEncoding)
        coordRequestParameters(builder: urlBuilder, types: types, lat: lat, lon: lon, maxDistance: maxDistance, maxLocations: maxLocations)
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder)
        return HttpClient.getXml(httpRequest: httpRequest) { result in
            switch result {
            case .success(let xml):
                do {
                    try self.handleCoordRequest(httpRequest: httpRequest, xml: xml, completion: completion)
                } catch let err as ParseError {
                    os_log("coordRequest parse error: %{public}@", log: .requestLogger, type: .error, err.reason)
                    completion(httpRequest, .failure(err))
                } catch let err {
                    os_log("coordRequest handle response error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                    completion(httpRequest, .failure(err))
                }
            case .failure(let err):
                os_log("coordRequest network error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                completion(httpRequest, .failure(err))
            }
        }
    }
    
    public override func queryTrips(from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        let urlBuilder = UrlBuilder(path: tripEndpoint, encoding: requestUrlEncoding)
        queryTripsParameters(builder: urlBuilder, from: from, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions, desktop: false)
        
        let desktopUrl: URL?
        if supportsDesktopTrips {
            let desktopUrlBuilder = UrlBuilder(path: desktopTripEndpoint ?? tripEndpoint, encoding: requestUrlEncoding)
            queryTripsParameters(builder: desktopUrlBuilder, from: from, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions, desktop: true)
            desktopUrl = desktopUrlBuilder.build()
        } else {
            desktopUrl = nil
        }
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder)
        return HttpClient.getXml(httpRequest: httpRequest) { result in
            switch result {
            case .success(let xml):
                do {
                    try self.handleTripRequestResponse(httpRequest: httpRequest, xml: xml, desktopUrl: desktopUrl, previousContext: nil, later: false, completion: completion)
                } catch is SessionExpiredError {
                    completion(httpRequest, .sessionExpired)
                } catch let err as ParseError {
                    os_log("queryTrips parse error: %{public}@", log: .requestLogger, type: .error, err.reason)
                    completion(httpRequest, .failure(err))
                } catch let err {
                    os_log("queryTrips handle response error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                    completion(httpRequest, .failure(err))
                }
            case .failure(let err):
                os_log("queryTrips network error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                completion(httpRequest, .failure(err))
            }
        }
    }
    
    override public func queryMoreTrips(context: QueryTripsContext, later: Bool, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        guard let context = context as? Context else {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .sessionExpired)
            return AsyncRequest(task: nil)
        }
        let urlBuilder = UrlBuilder(path: tripEndpoint, encoding: requestUrlEncoding)
        if later {
            commandLink(builder: urlBuilder, sessionId: context.queryLaterContext.sessionId, requestId: context.queryLaterContext.requestId)
        } else {
            commandLink(builder: urlBuilder, sessionId: context.queryEarlierContext.sessionId, requestId: context.queryEarlierContext.requestId)
        }
        appendCommonRequestParameters(builder: urlBuilder, outputFormat: "XML")
        urlBuilder.addParameter(key: "coordListOutputFormat", value: "STRING")
        urlBuilder.addParameter(key: "command", value: later ? "tripNext" : "tripPrev")
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder)
        return HttpClient.getXml(httpRequest: httpRequest) { result in
            switch result {
            case .success(let xml):
                do {
                    try self.handleTripRequestResponse(httpRequest: httpRequest, xml: xml, desktopUrl: context.desktopUrl, previousContext: context, later: later, completion: completion)
                } catch is SessionExpiredError {
                    completion(httpRequest, .sessionExpired)
                } catch let err as ParseError {
                    os_log("queryMoreTrips parse error: %{public}@", log: .requestLogger, type: .error, err.reason)
                    completion(httpRequest, .failure(err))
                } catch let err {
                    os_log("queryMoreTrips handle response error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                    completion(httpRequest, .failure(err))
                }
            case .failure(let err):
                os_log("queryMoreTrips network error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                switch err {
                case .invalidStatusCode(let code):
                    if code == 404 {
                        completion(httpRequest, .sessionExpired)
                    } else {
                        completion(httpRequest, .failure(err))
                    }
                default:
                    completion(httpRequest, .failure(err))
                }
            }
        }
    }
    
    public override func refreshTrip(context: RefreshTripContext, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        guard let context = context as? EfaRefreshTripContext else {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .sessionExpired)
            return AsyncRequest(task: nil)
        }
        let urlBuilder = UrlBuilder(path: tripEndpoint, encoding: requestUrlEncoding)
        urlBuilder.addParameter(key: "language", value: "de")
        urlBuilder.addParameter(key: "outputFormat", value: "XML")
        urlBuilder.addParameter(key: "coordOutputFormat", value: "WGS84")
        urlBuilder.addParameter(key: "sessionID", value: context.sessionId)
        urlBuilder.addParameter(key: "requestID", value: context.requestId)
        urlBuilder.addParameter(key: "command", value: "tripCoordSeq:\(context.routeIndex)")
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder)
        return HttpClient.getXml(httpRequest: httpRequest) { result in
            switch result {
            case .success(let xml):
                do {
                    try self.handleTripRequestResponse(httpRequest: httpRequest, xml: xml, desktopUrl: nil, previousContext: nil, later: false, completion: completion)
                } catch is SessionExpiredError {
                    completion(httpRequest, .sessionExpired)
                } catch let err as ParseError {
                    os_log("refreshTrip parse error: %{public}@", log: .requestLogger, type: .error, err.reason)
                    completion(httpRequest, .failure(err))
                } catch let err {
                    os_log("refreshTrip handle response error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                    completion(httpRequest, .failure(err))
                }
            case .failure(let err):
                os_log("refreshTrip network error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                switch err {
                case .invalidStatusCode(let code):
                    if code == 404 {
                        completion(httpRequest, .sessionExpired)
                    } else {
                        completion(httpRequest, .failure(err))
                    }
                default:
                    completion(httpRequest, .failure(err))
                }
            }
        }
    }
    
    override public func queryDepartures(stationId: String, departures: Bool, time: Date?, maxDepartures: Int, equivs: Bool, completion: @escaping (HttpRequest, QueryDeparturesResult) -> Void) -> AsyncRequest {
        let urlBuilder = UrlBuilder(path: departureMonitorEndpoint, encoding: requestUrlEncoding)
        queryDeparturesParameters(builder: urlBuilder, stationId: stationId, departures: departures, time: time, maxDepartures: maxDepartures, equivs: equivs, desktop: false)
        
        let desktopUrl: URL?
        if supportsDesktopDepartures {
            let desktopUrlBuilder = UrlBuilder(path: desktopDeparturesEndpoint ?? departureMonitorEndpoint, encoding: requestUrlEncoding)
            queryDeparturesParameters(builder: desktopUrlBuilder, stationId: stationId, departures: departures, time: time, maxDepartures: maxDepartures, equivs: equivs, desktop: true)
            desktopUrl = desktopUrlBuilder.build()
        } else {
            desktopUrl = nil
        }
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder)
        return HttpClient.getXml(httpRequest: httpRequest) { result in
            switch result {
            case .success(let xml):
                do {
                    try self.handleQueryDeparturesResponse(httpRequest: httpRequest, xml: xml, departures: departures, desktopUrl: desktopUrl, completion: completion)
                } catch let err as ParseError {
                    os_log("queryDepartures parse error: %{public}@", log: .requestLogger, type: .error, err.reason)
                    completion(httpRequest, .failure(err))
                } catch let err {
                    os_log("queryDepartures handle response error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                    completion(httpRequest, .failure(err))
                }
            case .failure(let err):
                os_log("queryDepartures network error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                completion(httpRequest, .failure(err))
            }
        }
    }
    
    public override func queryJourneyDetail(context: QueryJourneyDetailContext, completion: @escaping (HttpRequest, QueryJourneyDetailResult) -> Void) -> AsyncRequest {
        guard let context = context as? EfaJourneyContext, var lineId = context.line.id else {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .invalidId)
            return AsyncRequest(task: nil)
        }
        if lineId.hasSuffix(":") {
            lineId += "j18"
        }
        let urlBuilder = UrlBuilder(path: tripStopTimesEndpoint, encoding: requestUrlEncoding)
        appendCommonRequestParameters(builder: urlBuilder, outputFormat: "XML")
        urlBuilder.addParameter(key: "stopID", value: context.stopId)
        urlBuilder.addParameter(key: "tripCode", value: context.tripCode)
        urlBuilder.addParameter(key: "line", value: context.line.id)
        appendDate(builder: urlBuilder, date: context.stopDepartureTime, dateParam: "date", timeParam: "time")
        urlBuilder.addParameter(key: "tStOTType", value: "all")
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder)
        return HttpClient.getXml(httpRequest: httpRequest) { result in
            switch result {
            case .success(let xml):
                do {
                    try self.handleQueryJourneyDetailResponse(httpRequest: httpRequest, xml: xml, line: context.line, completion: completion)
                } catch let err as ParseError {
                    os_log("journeyDetail parse error: %{public}@", log: .requestLogger, type: .error, err.reason)
                    completion(httpRequest, .failure(err))
                } catch let err {
                    os_log("journeyDetail handle response error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                    completion(httpRequest, .failure(err))
                }
            case .failure(let err):
                os_log("journeyDetail network error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                completion(httpRequest, .failure(err))
            }
        }
    }
    
    // MARK: NetworkProvider mobile implementations – Requests
    
    func mobileStopfinderRequest(constraint: String, types: [LocationType]?, maxLocations: Int, completion: @escaping (HttpRequest, SuggestLocationsResult) -> Void) -> AsyncRequest {
        let urlBuilder = UrlBuilder(path: stopFinderEndpoint, encoding: requestUrlEncoding)
        stopFinderRequestParameters(builder: urlBuilder, constraint: constraint, types: types, maxLocations: maxLocations, outputFormat: "XML")
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder)
        return HttpClient.getXml(httpRequest: httpRequest) { result in
            switch result {
            case .success(let xml):
                do {
                    try self.handleMobileStopfinderResponse(httpRequest: httpRequest, xml: xml, completion: completion)
                } catch let err as ParseError {
                    os_log("mobileStopfinder parse error: %{public}@", log: .requestLogger, type: .error, err.reason)
                    completion(httpRequest, .failure(err))
                } catch let err {
                    os_log("mobileStopfinder handle response error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                    completion(httpRequest, .failure(err))
                }
            case .failure(let err):
                os_log("mobileStopfinder network error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                completion(httpRequest, .failure(err))
            }
        }
    }
    
    func mobileCoordRequest(types: [LocationType]?, lat: Int, lon: Int, maxDistance: Int, maxLocations: Int, completion: @escaping (HttpRequest, NearbyLocationsResult) -> Void) -> AsyncRequest {
        let urlBuilder = UrlBuilder(path: coordEndpoint, encoding: requestUrlEncoding)
        coordRequestParameters(builder: urlBuilder, types: types, lat: lat, lon: lon, maxDistance: maxDistance, maxLocations: maxLocations)
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder)
        return HttpClient.getXml(httpRequest: httpRequest) { result in
            switch result {
            case .success(let xml):
                do {
                    try self.handleMobileCoordRequest(httpRequest: httpRequest, xml: xml, completion: completion)
                } catch let err as ParseError {
                    os_log("mobileCoord parse error: %{public}@", log: .requestLogger, type: .error, err.reason)
                    completion(httpRequest, .failure(err))
                } catch let err {
                    os_log("mobileCoord handle response error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                    completion(httpRequest, .failure(err))
                }
            case .failure(let err):
                os_log("mobileCoord network error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                completion(httpRequest, .failure(err))
            }
        }
    }
    
    func queryTripsMobile(from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        let urlBuilder = UrlBuilder(path: tripEndpoint, encoding: requestUrlEncoding)
        queryTripsParameters(builder: urlBuilder, from: from, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions, desktop: false)
        
        let desktopUrl: URL?
        if supportsDesktopTrips {
            let desktopUrlBuilder = UrlBuilder(path: desktopTripEndpoint ?? tripEndpoint, encoding: requestUrlEncoding)
            queryTripsParameters(builder: desktopUrlBuilder, from: from, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions, desktop: true)
            desktopUrl = desktopUrlBuilder.build()
        } else {
            desktopUrl = nil
        }
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder)
        return HttpClient.getXml(httpRequest: httpRequest) { result in
            switch result {
            case .success(let xml):
                do {
                    try self.handleMobileTripRequestResponse(httpRequest: httpRequest, xml: xml, desktopUrl: desktopUrl, from: from, via: via, to: to, previousContext: nil, later: false, completion: completion)
                } catch let err as ParseError {
                    os_log("mobileTripRequest parse error: %{public}@", log: .requestLogger, type: .error, err.reason)
                    completion(httpRequest, .failure(err))
                } catch let err {
                    os_log("mobileTripRequest handle response error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                    completion(httpRequest, .failure(err))
                }
            case .failure(let err):
                os_log("mobileTripRequest network error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                completion(httpRequest, .failure(err))
            }
        }
    }
    
    func queryMoreTripsMobile(context: QueryTripsContext, later: Bool, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        guard let context = context as? Context else {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .sessionExpired)
            return AsyncRequest(task: nil)
        }
        let urlBuilder = UrlBuilder(path: tripEndpoint, encoding: requestUrlEncoding)
        if later {
            commandLink(builder: urlBuilder, sessionId: context.queryLaterContext.sessionId, requestId: context.queryLaterContext.requestId)
        } else {
            commandLink(builder: urlBuilder, sessionId: context.queryEarlierContext.sessionId, requestId: context.queryEarlierContext.requestId)
        }
        appendCommonRequestParameters(builder: urlBuilder, outputFormat: "XML")
        urlBuilder.addParameter(key: "command", value: later ? "tripNext" : "tripPrev")
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder)
        return HttpClient.getXml(httpRequest: httpRequest) { result in
            switch result {
            case .success(let xml):
                do {
                    try self.handleMobileTripRequestResponse(httpRequest: httpRequest, xml: xml, desktopUrl: context.desktopUrl, from: nil, via: nil, to: nil, previousContext: context, later: later, completion: completion)
                } catch is SessionExpiredError {
                    completion(httpRequest, .sessionExpired)
                } catch let err as ParseError {
                    os_log("queryMoreTripsMobile parse error: %{public}@", log: .requestLogger, type: .error, err.reason)
                    completion(httpRequest, .failure(err))
                } catch let err {
                    os_log("queryMoreTripsMobile handle response error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                    completion(httpRequest, .failure(err))
                }
            case .failure(let err):
                os_log("queryMoreTripsMobile network error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                switch err {
                case .invalidStatusCode(let code):
                    if code == 404 {
                        completion(httpRequest, .sessionExpired)
                    } else {
                        completion(httpRequest, .failure(err))
                    }
                default:
                    completion(httpRequest, .failure(err))
                }
            }
        }
    }
    
    func refreshTripMobile(context: RefreshTripContext, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        guard let context = context as? EfaRefreshTripContext else {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .sessionExpired)
            return AsyncRequest(task: nil)
        }
        let urlBuilder = UrlBuilder(path: tripEndpoint, encoding: requestUrlEncoding)
        urlBuilder.addParameter(key: "language", value: "de")
        urlBuilder.addParameter(key: "outputFormat", value: "XML")
        urlBuilder.addParameter(key: "coordOutputFormat", value: "WGS84")
        urlBuilder.addParameter(key: "sessionID", value: context.sessionId)
        urlBuilder.addParameter(key: "requestID", value: context.requestId)
        urlBuilder.addParameter(key: "command", value: "tripCoordSeq:\(context.routeIndex)")
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder)
        return HttpClient.getXml(httpRequest: httpRequest) { result in
            switch result {
            case .success(let xml):
                do {
                    try self.handleMobileTripRequestResponse(httpRequest: httpRequest, xml: xml, desktopUrl: nil, from: nil, via: nil, to: nil, previousContext: nil, later: false, completion: completion)
                } catch is SessionExpiredError {
                    completion(httpRequest, .sessionExpired)
                } catch let err as ParseError {
                    os_log("refreshTripMobile parse error: %{public}@", log: .requestLogger, type: .error, err.reason)
                    completion(httpRequest, .failure(err))
                } catch let err {
                    os_log("refreshTripMobile handle response error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                    completion(httpRequest, .failure(err))
                }
            case .failure(let err):
                os_log("refreshTripMobile network error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                switch err {
                case .invalidStatusCode(let code):
                    if code == 404 {
                        completion(httpRequest, .sessionExpired)
                    } else {
                        completion(httpRequest, .failure(err))
                    }
                default:
                    completion(httpRequest, .failure(err))
                }
            }
        }
    }
    
    func queryDeparturesMobile(stationId: String, departures: Bool, time: Date?, maxDepartures: Int, equivs: Bool, completion: @escaping (HttpRequest, QueryDeparturesResult) -> Void) -> AsyncRequest {
        let urlBuilder = UrlBuilder(path: departureMonitorEndpoint, encoding: requestUrlEncoding)
        queryDeparturesParameters(builder: urlBuilder, stationId: stationId, departures: departures, time: time, maxDepartures: maxDepartures, equivs: equivs, desktop: false)

        let desktopUrl: URL?
        if supportsDesktopDepartures {
            let desktopUrlBuilder = UrlBuilder(path: desktopDeparturesEndpoint ?? departureMonitorEndpoint, encoding: requestUrlEncoding)
            queryDeparturesParameters(builder: desktopUrlBuilder, stationId: stationId, departures: departures, time: time, maxDepartures: maxDepartures, equivs: equivs, desktop: true)
            desktopUrl = desktopUrlBuilder.build()
        } else {
            desktopUrl = nil
        }
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder)
        return HttpClient.getXml(httpRequest: httpRequest) { result in
            switch result {
            case .success(let xml):
                do {
                    try self.handleQueryDeparturesMobileResponse(httpRequest: httpRequest, xml: xml, departures: departures, desktopUrl: desktopUrl, completion: completion)
                } catch let err as ParseError {
                    os_log("queryDeparturesMobile parse error: %{public}@", log: .requestLogger, type: .error, err.reason)
                    completion(httpRequest, .failure(err))
                } catch let err {
                    os_log("queryDeparturesMobile handle response error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                    completion(httpRequest, .failure(err))
                }
            case .failure(let err):
                os_log("queryDeparturesMobile network error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                completion(httpRequest, .failure(err))
            }
        }
    }
    
    func queryJourneyDetailMobile(context: QueryJourneyDetailContext, completion: @escaping (HttpRequest, QueryJourneyDetailResult) -> Void) -> AsyncRequest {
        guard let context = context as? EfaJourneyContext, var lineId = context.line.id else {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .invalidId)
            return AsyncRequest(task: nil)
        }
        if lineId.hasSuffix(":") {
            lineId += "j18"
        }
        let urlBuilder = UrlBuilder(path: tripStopTimesEndpoint, encoding: requestUrlEncoding)
        appendCommonRequestParameters(builder: urlBuilder, outputFormat: "XML")
        urlBuilder.addParameter(key: "stopID", value: context.stopId)
        urlBuilder.addParameter(key: "tripCode", value: context.tripCode)
        urlBuilder.addParameter(key: "line", value: context.line.id)
        appendDate(builder: urlBuilder, date: context.stopDepartureTime, dateParam: "date", timeParam: "time")
        urlBuilder.addParameter(key: "tStOTType", value: "all")
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder)
        return HttpClient.getXml(httpRequest: httpRequest) { result in
            switch result {
            case .success(let xml):
                do {
                    try self.handleQueryJourneyDetailMobileResponse(httpRequest: httpRequest, xml: xml, line: context.line, completion: completion)
                } catch let err as ParseError {
                    os_log("journeyDetailMobile parse error: %{public}@", log: .requestLogger, type: .error, err.reason)
                    completion(httpRequest, .failure(err))
                } catch let err {
                    os_log("journeyDetailMobile handle response error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                    completion(httpRequest, .failure(err))
                }
            case .failure(let err):
                os_log("journeyDetailMobile network error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                completion(httpRequest, .failure(err))
            }
        }
    }
    
    // MARK: NetworkProvider responses
    
    func handleJsonStopfinderResponse(httpRequest: HttpRequest, json: JSON, completion: @escaping (HttpRequest, SuggestLocationsResult) -> Void) throws {
        let head = json["stopFinder"].exists() ? json["stopFinder"] : json
        
        // check for errors
        for message in head["message"].arrayValue {
            let name = message["name"].stringValue
            let value = message["value"].stringValue
            if name == "code" && value != "-8010" && value != "-8011" {
                throw ParseError(reason: "received illegal message code \(value)")
            }
        }
        
        var locations: [SuggestedLocation] = []
        let pointObj = head["points"]["point"]
        func parseJsonPoint(json: JSON) throws -> SuggestedLocation {
            var type = json["type"].stringValue
            if type == "any" {
                type = json["anyType"].string ?? type
            }
            let id = json["stateless"].string
            let name = normalizeLocationName(name: json["name"].string)
            let object = normalizeLocationName(name: json["object"].string)
            let postcode = json["postcode"].string
            let quality = json["quality"].intValue
            let place = json["ref"]["place"].string?.emptyToNil
            let coordinates = parseCoordinates(string: json["ref"]["coord"].string ?? json["ref"]["coords"].string)
            
            let location: Location?
            switch type {
            case "stop":
                location = Location(type: .station, id: id, coord: coordinates, place: place, name: object)
                break
            case "poi":
                location = Location(type: .poi, id: id, coord: coordinates, place: place, name: object)
                break
            case "crossing":
                location = Location(type: .address, id: id, coord: coordinates, place: place, name: object)
                break
            case "street", "address", "singlehouse", "buildingname", "loc":
                location = Location(type: .address, id: id, coord: coordinates, place: place, name: name)
                break
            case "postcode":
                location = Location(type: .address, id: id, coord: coordinates, place: place, name: postcode)
                break
            default:
                location = Location(type: .any, id: nil, coord: coordinates, place: place, name: name)
                break
            }
            guard let finalLocation = location else {
                throw ParseError(reason: "failed to init location")
            }
            return SuggestedLocation(location: finalLocation, priority: quality)
        }
        if pointObj.exists() {
            locations.append(try parseJsonPoint(json: pointObj))
        } else if head["points"].exists() {
            for point in head["points"].arrayValue {
                locations.append(try parseJsonPoint(json: point))
            }
        } else if let first = head.arrayValue.first {
            locations.append(try parseJsonPoint(json: first))
        }
        
        locations.sort {$0.priority > $1.priority}
        completion(httpRequest, .success(locations: locations))
    }
    
    func handleCoordRequest(httpRequest: HttpRequest, xml: XMLIndexer, completion: @escaping (HttpRequest, NearbyLocationsResult) -> Void) throws {
        let request = xml["itdRequest"]["itdCoordInfoRequest"]["itdCoordInfo"]["coordInfoItemList"]
        
        var locations: [Location] = []
        for coordItem in request["coordInfoItem"].all {
            let type = coordItem.element?.attribute(by: "type")?.text
            let locationType: LocationType
            if type == "STOP" {
                locationType = .station
            } else if type == "POI_POINT" {
                locationType = .poi
            } else {
                throw ParseError(reason: "unknown location type \(type ?? "")")
            }
            let id = coordItem.element?.attribute(by: "stateless")?.text ?? coordItem.element?.attribute(by: "id")?.text
            let name = normalizeLocationName(name: coordItem.element?.attribute(by: "name")?.text)
            let place = normalizeLocationName(name: coordItem.element?.attribute(by: "locality")?.text)
            let coordList = processItdPathCoordinates(coordItem["itdPathCoordinates"])
            let coord = coordList == nil ? nil : coordList!.count > 0 ? coordList![0] : nil
            
            let location = Location(type: locationType, id: id, coord: coord, place: place, name: name)
            if let location = location {
                locations.append(location)
            }
        }
        completion(httpRequest, .success(locations: locations))
    }
    
    func handleNearbyStationsRequest(httpRequest: HttpRequest, xml: XMLIndexer, maxLocations: Int, completion: @escaping (HttpRequest, NearbyLocationsResult) -> Void) throws {
        let request = xml["itdRequest"]["itdDepartureMonitorRequest"]
        
        var ownStation: Location?
        var stations: [Location] = []
        let nameState = try processItdOdv(odv: request["itdOdv"], expectedUsage: "dm") { (nameState, location, matchQuality) in
            if location.type == .station {
                if nameState == "identified" {
                    ownStation = location
                } else if nameState == "assigned" {
                    stations.append(location)
                }
            }
        }
        
        if nameState == "notidentified" {
            completion(httpRequest, .invalidId)
            return
        }
        
        if let ownStation = ownStation, !stations.contains(ownStation) {
            stations.append(ownStation)
        }
        
        if maxLocations == 0 || maxLocations >= stations.count {
            completion(httpRequest, .success(locations: stations))
        } else {
            completion(httpRequest, .success(locations: Array(stations[0..<maxLocations])))
        }
    }
    
    func handleTripRequestResponse(httpRequest: HttpRequest, xml: XMLIndexer, desktopUrl: URL?, previousContext: Context?, later: Bool, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) throws {
        var request = xml["itdRequest"]["itdTripRequest"]
        if request.all.isEmpty {
            request = xml["itdRequest"]
        }
        let requestId = request.element?.attribute(by: "requestID")?.text
        let sessionId = xml["itdRequest"].element?.attribute(by: "sessionID")?.text
        if let code = request["itdMessage"].element?.attribute(by: "code")?.text, code == "-4000" {
            completion(httpRequest, .noTrips)
            return
        }
        
        var ambiguousFrom, ambiguousTo, ambiguousVia: [Location]?
        var from, to, via: Location?
        for odv in request["itdOdv"].all {
            guard let usage = odv.element?.attribute(by: "usage")?.text else { continue }
            
            var locations: [Location] = []
            var sort: [Location: Int] = [:]
            
            let nameState = try processItdOdv(odv: odv, expectedUsage: usage, callback: { (nameState: String?, location: Location, matchQuality: Int) in
                locations.append(location)
                sort[location] = matchQuality
            })
            
            locations.sort {sort[$0]! > sort[$1]!}
            
            if nameState == "list" {
                if usage == "origin" {
                    ambiguousFrom = locations
                } else if usage == "via" {
                    ambiguousVia = locations
                } else if usage == "destination" {
                    ambiguousTo = locations
                } else {
                    throw ParseError(reason: "unknown usage \(usage)")
                }
            } else if nameState == "identified" {
                if usage == "origin" {
                    from = locations[0]
                } else if usage == "via" {
                    via = locations[0]
                } else if usage == "destination" {
                    to = locations[0]
                } else {
                    throw ParseError(reason: "unknown usage \(usage)")
                }
            } else if nameState == "notidentified" {
                if usage == "origin" {
                    completion(httpRequest, .unknownFrom)
                } else if usage == "via" {
                    completion(httpRequest, .unknownVia)
                } else if usage == "destination" {
                    completion(httpRequest, .unknownTo)
                } else {
                    throw ParseError(reason: "unknown usage \(usage)")
                }
                return
            }
        }
        if ambiguousFrom != nil || ambiguousVia != nil || ambiguousTo != nil {
            completion(httpRequest, .ambiguous(ambiguousFrom: ambiguousFrom ?? [], ambiguousVia: ambiguousVia ?? [], ambiguousTo: ambiguousTo ?? []))
            return
        }
        if let message = request["itdTripDateTime"]["itdDateTime"]["itdDate"]["itdMessage"].element?.text, message == "invalid date" {
            completion(httpRequest, .invalidDate)
            return
        }
        
        var messages: [InfoText] = []
        for infoLink in xml["itdRequest"]["itdInfoLinkList"]["itdBannerInfoList"]["infoLink"].all {
            guard let infoLinkText = infoLink["infoLinkText"].element?.text, let infoLinkUrl = infoLink["infoLinkURL"].element?.text else { continue }
            messages.append(InfoText(text: String(htmlEncodedString: infoLinkText) ?? infoLinkText, url: infoLinkUrl))
        }
        
        var trips: [Trip] = []
        var routes = request["itdItinerary"]["itdRouteList"]["itdRoute"].all
        if routes.isEmpty {
            routes = request["itdTripCoordSeqRequest"]["itdRoute"].all
        }
        if routes.isEmpty {
            completion(httpRequest, .noTrips)
            return
        }
        
        for route in routes {
            let id = "" // when using query earlier, trip ids are no longer unique, but shift
            
            var legs: [Leg] = []
            var firstDepartureLocation: Location?
            var lastArrivalLocation: Location?
            var cancelled = false
            
            for partialRoute in route["itdPartialRouteList"]["itdPartialRoute"].all {
                var legMessages: [String] = []
                for infoLink in partialRoute["infoLink"].all {
                    guard let infoLinkText = infoLink["infoText"]["subtitle"].element?.text else { continue }
                    legMessages.append(infoLinkText)
                }
                
                let points = partialRoute["itdPoint"].all
                var point = points[0]
                if point.element?.attribute(by: "usage")?.text != "departure" {
                    throw ParseError(reason: "wrong route usage")
                }
                guard let departureLocation = processItdPointAttributes(point: point) else {
                    throw ParseError(reason: "departure location point attr")
                }
                if firstDepartureLocation == nil {
                    firstDepartureLocation = departureLocation
                }
                let departurePosition = parsePosition(position: point.element?.attribute(by: "platformName")?.text)
                let plannedDeparturePosition = parsePosition(position: point.element?.attribute(by: "plannedPlatformName")?.text)
                guard let departureTime = processItdDateTime(xml: point["itdDateTime"]) else {
                    throw ParseError(reason: "departure time")
                }
                let departureTargetTime = processItdDateTime(xml: point["itdDateTimeTarget"])
                
                point = points[1]
                if point.element?.attribute(by: "usage")?.text != "arrival" {
                    throw ParseError(reason: "wrong route usage")
                }
                guard let arrivalLocation = processItdPointAttributes(point: point) else {
                    throw ParseError(reason: "arrival location point attr")
                }
                lastArrivalLocation = arrivalLocation
                let arrivalPosition = parsePosition(position: point.element?.attribute(by: "platformName")?.text)
                let plannedArrivalPosition = parsePosition(position: point.element?.attribute(by: "plannedPlatformName")?.text)
                guard let arrivalTime = processItdDateTime(xml: point["itdDateTime"]) else {
                    throw ParseError(reason: "arrival time")
                }
                let arrivalTargetTime = processItdDateTime(xml: point["itdDateTimeTarget"])
                
                let meansOfTransportProductName = partialRoute["itdMeansOfTransport"].element?.attribute(by: "productName")?.text
                guard let meansOfTransportType = Int(partialRoute["itdMeansOfTransport"].element?.attribute(by: "type")?.text ?? "") else {
                    throw ParseError(reason: "means of transport type")
                }
                if meansOfTransportType <= 16 {
                    cancelled |= try processPublicLeg(partialRoute, &legs, departureTime, departureTargetTime, departureLocation, departurePosition, plannedDeparturePosition, arrivalTime, arrivalTargetTime, arrivalLocation, arrivalPosition, plannedArrivalPosition, legMessages)
                } else if meansOfTransportType == 97 && meansOfTransportProductName == "nicht umsteigen" {
                    if let last = legs.last as? PublicLeg {
                        var lastMessage = "Nicht umsteigen, Weiterfahrt im selben Fahrzeug möglich."
                        if let message = last.message?.emptyToNil {
                            lastMessage += "\n" + message
                        }
                        if let msg = legMessages.joined(separator: "\n").emptyToNil {
                            lastMessage += "\n" + msg
                        }
                        legs[legs.count - 1] = PublicLeg(line: last.line, destination: last.destination, departureStop: last.departureStop, arrivalStop: last.arrivalStop, intermediateStops: last.intermediateStops, message: lastMessage, path: last.path, journeyContext: last.journeyContext)
                    }
                } else if meansOfTransportType == 98 && meansOfTransportProductName == "gesicherter Anschluss" {
                    // ignore
                } else if meansOfTransportType == 99 && meansOfTransportProductName == "Fussweg" {
                    processIndividualLeg(partialRoute, &legs, .WALK, departureTime, departureLocation, arrivalTime, arrivalLocation)
                } else if meansOfTransportType == 100 && (meansOfTransportProductName == nil || meansOfTransportProductName == "Fussweg") {
                    processIndividualLeg(partialRoute, &legs, .WALK, departureTime, departureLocation, arrivalTime, arrivalLocation)
                } else if meansOfTransportType == 105 && meansOfTransportProductName == "Taxi" {
                    processIndividualLeg(partialRoute, &legs, .CAR, departureTime, departureLocation, arrivalTime, arrivalLocation)
                } else {
                    throw ParseError(reason: "unknown means of transport: \(meansOfTransportType) \(meansOfTransportProductName ?? "")")
                }
            }
            guard let from = firstDepartureLocation, let to = lastArrivalLocation else {
                throw ParseError(reason: "from/to location")
            }
            
            var fares: [Fare] = []
            if let elem = route["itdFare"]["itdSingleTicket"].element, let net = elem.attribute(by: "net")?.text, let currency = elem.attribute(by: "currency")?.text {
                let unitName = elem.attribute(by: "unitName")?.text.trimmingCharacters(in: .whitespaces)
                if let fareAdult = elem.attribute(by: "fareAdult")?.text, let fare = Float(fareAdult), fare != 0 {
                    let level = elem.attribute(by: "levelAdult")?.text.trimmingCharacters(in: .whitespaces)
                    let units = elem.attribute(by: "unitsAdult")?.text.trimmingCharacters(in: .whitespaces)
                    
                    fares.append(Fare(network: net.uppercased(), type: .adult, currency: currency, fare: fare, unitsName: level ?? "" != "" ? nil : (unitName ?? "" == "" ? nil : unitName), units: level ?? "" != "" ? level : units))
                }
                if let fareChild = elem.attribute(by: "fareChild")?.text, let fare = Float(fareChild), fare != 0 {
                    let level = elem.attribute(by: "levelChild")?.text.trimmingCharacters(in: .whitespaces)
                    let units = elem.attribute(by: "unitsChild")?.text.trimmingCharacters(in: .whitespaces)
                    
                    fares.append(Fare(network: net.uppercased(), type: .child, currency: currency, fare: fare, unitsName: level ?? "" != "" ? nil : (unitName ?? "" == "" ? nil : unitName), units: level ?? "" != "" ? level : units))
                }
            } else {
                let tickets = route["itdFare"]["itdUnifiedTicket"].all
                for ticket in tickets {
                    guard
                        let name = ticket.element?.attribute(by: "name")?.text,
                        name.starts(with: "Einzelfahrschein"),
                        let net = ticket.element?.attribute(by: "net")?.text,
                        let currency = ticket.element?.attribute(by: "currency")?.text,
                        let person = ticket.element?.attribute(by: "person")?.text,
                        let fareString = ticket.element?.attribute(by: "priceBrutto")?.text,
                        let fare = Float(fareString)
                    else {
                        continue
                    }
                    switch person {
                    case "ADULT":
                        fares.append(Fare(network: net.uppercased(), type: .adult, currency: currency, fare: fare, unitsName: nil, units: nil))
                    case "CHILD":
                        fares.append(Fare(network: net.uppercased(), type: .child, currency: currency, fare: fare, unitsName: nil, units: nil))
                    default: break
                    }
                        
                }
            }
            
            let context: EfaRefreshTripContext?
            if let sessionId = sessionId, let requestId = requestId {
                context = EfaRefreshTripContext(sessionId: sessionId, requestId: requestId, routeIndex: "\(trips.count + 1)")
            } else {
                context = nil
            }
            
            let trip = Trip(id: id, from: from, to: to, legs: legs, fares: fares, refreshContext: context)
            trips.append(trip)
        }
        if trips.count == 0 {
            completion(httpRequest, .noTrips)
            return
        }
        
        let context: Context?
        if let sessionId = sessionId, let requestId = requestId {
            if let previousContext = previousContext {
                context = Context(queryEarlierContext: later ? previousContext.queryEarlierContext : (sessionId: sessionId, requestId: requestId), queryLaterContext: !later ? previousContext.queryLaterContext : (sessionId: sessionId, requestId: requestId), desktopUrl: desktopUrl)
            } else {
                context = Context(queryEarlierContext: (sessionId: sessionId, requestId: requestId), queryLaterContext: (sessionId: sessionId, requestId: requestId), desktopUrl: desktopUrl)
            }
        } else {
            context = previousContext
        }
        
        completion(httpRequest, .success(context: context, from: from, via: via, to: to, trips: trips, messages: messages))
    }
    
    func handleQueryDeparturesResponse(httpRequest: HttpRequest, xml: XMLIndexer, departures: Bool, desktopUrl: URL?, completion: @escaping (HttpRequest, QueryDeparturesResult) -> Void) throws {
        let request = xml["itdRequest"]["itdDepartureMonitorRequest"]
        
        var result: [StationDepartures] = []
        
        let departureStop = request["itdOdv"]
        let nameState = try self.processItdOdv(odv: departureStop, expectedUsage: "dm", callback: { (nameState: String?, location: Location, matchQuality: Int) in
            if location.type == .station {
                if !result.contains(where: {$0.stopLocation.id == location.id}) {
                    result.append(StationDepartures(stopLocation: location, departures: [], lines: []))
                }
            }
        })
        
        if nameState != "identified" {
            completion(httpRequest, .invalidStation)
            return
        }
        
        for servingLine in request["itdServingLines"]["itdServingLine"].all {
            guard let (line, destination, _) = self.parseLine(xml: servingLine) else {
                throw ParseError(reason: "failed to parse line")
            }
            let assignedStopId = servingLine.element?.attribute(by: "assignedStopID")?.text
            result.first(where: {$0.stopLocation.id == assignedStopId})?.lines.append(ServingLine(line: line, destination: destination))
        }
        
        for departure in request[departures ? "itdDepartureList" : "itdArrivalList"][departures ? "itdDeparture" : "itdArrival"].all {
            let assignedStopId = departure.element?.attribute(by: "stopID")?.text
            let plannedTime = self.parseDate(xml: departure["itdDateTime"])
            let predictedTime = self.parseDate(xml: departure["itdRTDateTime"])
            guard let (line, destination, cancelled) = self.parseLine(xml: departure["itdServingLine"]) else {
                print("WRN - queryDepartures: Failed to parse departure line!")
                continue
            }
            if cancelled {
                continue
            }
            let predictedPosition = parsePosition(position: departure.element?.attribute(by: "platformName")?.text)
            let plannedPosition = parsePosition(position: departure.element?.attribute(by: "plannedPlatformName")?.text) ?? predictedPosition
            
            let context: EfaJourneyContext?
            let tripCode = departure["itdServingTrip"].element?.attribute(by: "tripCode")?.text ?? departure["itdServingLine"].element?.attribute(by: "key")?.text
            if let stopId = assignedStopId, let departureTime = plannedTime ?? predictedTime, let tripCode = tripCode, line.id != nil {
                context = EfaJourneyContext(stopId: stopId, stopDepartureTime: departureTime, line: line, tripCode: tripCode)
            } else {
                context = nil
            }
            
            let departure = Departure(plannedTime: plannedTime, predictedTime: predictedTime, line: line, position: predictedPosition, plannedPosition: plannedPosition, destination: destination, capacity: nil, message: line.message, journeyContext: context)
            result.first(where: {$0.stopLocation.id == assignedStopId})?.departures.append(departure)
        }
        
        completion(httpRequest, .success(departures: result, desktopUrl: desktopUrl))
    }
    
    func handleQueryDeparturesMobileResponse(httpRequest: HttpRequest, xml: XMLIndexer, departures: Bool, desktopUrl: URL?, completion: @escaping (HttpRequest, QueryDeparturesResult) -> Void) throws {
        if let error = xml["efa"]["ers"]["err"].element, let mod = error.attribute(by: "mod")?.text, let co = error.attribute(by: "co")?.text {
            throw ParseError(reason: "Efa error: " + mod + " " + co)
        }
        let departures = xml["efa"]["dps"]["dp"].all
        if departures.count == 0 {
            completion(httpRequest, .invalidStation)
            return
        }
        
        var result: [StationDepartures] = []
        for dp in departures {
            guard let assignedId = dp["r"]["id"].element?.text else { throw ParseError(reason: "failed to parse departure id") }
            
            let plannedTime = parseMobilePlannedTime(xml: dp["st"])
            let predictedTime = parseMobilePredictedTime(xml: dp["st"])
            
            let lineDestination = try parseMobileLineDestination(xml: dp, tyOrCo: true)
            let position = parsePosition(position: dp["r"]["pl"].element?.text)
            
            var stationDepartures = result.first(where: {$0.stopLocation.id == assignedId})
            if stationDepartures == nil, let location = Location(type: .station, id: assignedId) {
                stationDepartures = StationDepartures(stopLocation: location, departures: [], lines: [])
                result.append(stationDepartures!)
            }
            let context: EfaJourneyContext?
            let tripCode = dp["m"]["dv"]["tk"].element?.text
            if let departureTime = plannedTime ?? predictedTime, let tripCode = tripCode, lineDestination.line.id != nil {
                context = EfaJourneyContext(stopId: assignedId, stopDepartureTime: departureTime, line: lineDestination.line, tripCode: tripCode)
            } else {
                context = nil
            }
            
            stationDepartures?.departures.append(Departure(plannedTime: plannedTime, predictedTime: predictedTime, line: lineDestination.line, position: position, plannedPosition: position, destination: lineDestination.destination, journeyContext: context))
        }
        completion(httpRequest, .success(departures: result, desktopUrl: desktopUrl))
    }
    
    func handleQueryJourneyDetailResponse(httpRequest: HttpRequest, xml: XMLIndexer, line: Line, completion: @escaping (HttpRequest, QueryJourneyDetailResult) -> Void) throws {
        let request = xml["itdRequest"]["itdStopSeqCoordRequest"]["stopSeq"]
        var stops: [Stop] = []
        for point in request["itdPoint"].all {
            guard let stopLocation = processItdPointAttributes(point: point) else { continue }
            let stopPosition = parsePosition(position: point.element?.attribute(by: "platformName")?.text)
            
            let plannedStopArrivalTime = processItdDateTime(xml: point["itdDateTime"][0])
            let predictedStopArrivalTime = processItdDateTime(xml: point["itdDateTimeTarget"][0])
            let plannedStopDepartureTime = processItdDateTime(xml: point["itdDateTime"][1])
            let predictedStopDepartureTime = processItdDateTime(xml: point["itdDateTimeTarget"][1])
            
            let stop = Stop(location: stopLocation, plannedArrivalTime: plannedStopArrivalTime, predictedArrivalTime: predictedStopArrivalTime, plannedArrivalPlatform: stopPosition, predictedArrivalPlatform: nil, arrivalCancelled: false, plannedDepartureTime: plannedStopDepartureTime, predictedDepartureTime: predictedStopDepartureTime, plannedDeparturePlatform: stopPosition, predictedDeparturePlatform: nil, departureCancelled: false)
            
            stops.append(stop)
        }
        guard stops.count >= 2 else {
            throw ParseError(reason: "could not parse points")
        }
        let departureStop = stops.removeFirst()
        let arrivalStop = stops.removeLast()
        let path = processItdPathCoordinates(xml["itdRequest"]["itdStopSeqCoordRequest"]["itdPathCoordinates"]) ?? []
        let leg = PublicLeg(line: line, destination: arrivalStop.location, departureStop: departureStop, arrivalStop: arrivalStop, intermediateStops: stops, message: nil, path: path, journeyContext: nil)
        let trip = Trip(id: "", from: departureStop.location, to: arrivalStop.location, legs: [leg], fares: [])
        completion(httpRequest, .success(trip: trip, leg: leg))
    }
    
    // MARK: NetworkProvider mobile responses
    
    func handleMobileStopfinderResponse(httpRequest: HttpRequest, xml: XMLIndexer, completion: @escaping (HttpRequest, SuggestLocationsResult) -> Void) throws {
        var locations: [SuggestedLocation] = []
        for elem in xml["efa"]["sf"]["p"].all {
            guard let name = normalizeLocationName(name: elem["n"].element?.text), let ty = elem["ty"].element?.text else {
                throw ParseError(reason: "failed to parse stop")
            }
            guard let u = elem["u"].element?.text, u == "sf" else {
                throw ParseError(reason: "unknown usage \(elem["n"].element?.text ?? "")")
            }
            
            let locationType: LocationType
            switch ty {
            case "stop":
                locationType = .station
            case "poi":
                locationType = .poi
            case "loc":
                locationType = .coord
            case "street", "singlehouse":
                locationType = .address
            default:
                os_log("Unknown location type %{public}@", log: .requestLogger, type: .error, ty)
                locationType = .any
            }
            
            let r = elem["r"]
            guard let id = r["id"].element?.text, let stateless = r["stateless"].element?.text else {
                throw ParseError(reason: "failed to parse stop id")
            }
            let place = normalizeLocationName(name: r["pc"].element?.text)
            let coord = parseCoordinates(string: r["c"].element?.text)
            let qal = Int(elem["qal"].element?.text ?? "") ?? 0
            
            let location = Location(type: locationType, id: locationType == .station ? id : stateless, coord: coord, place: place, name: name)
            if let location = location {
                locations.append(SuggestedLocation(location: location, priority: qal))
            } else {
                throw ParseError(reason: "failed to parse stop")
            }
        }
        locations.sort {$0.priority > $1.priority}
        completion(httpRequest, .success(locations: locations))
    }
    
    func handleMobileCoordRequest(httpRequest: HttpRequest, xml: XMLIndexer, completion: @escaping (HttpRequest, NearbyLocationsResult) -> Void) throws {
        let request = xml["efa"]["ci"]
        
        var locations: [Location] = []
        for pi in request["pis"]["pi"].all {
            let name = normalizeLocationName(name: pi["de"].element?.text)
            let type = pi["ty"].element?.text
            let locationType: LocationType
            switch type ?? "" {
            case "STOP":
                locationType = .station
                break
            case "POI_POINT":
                locationType = .poi
            default:
                throw ParseError(reason: "unknown type \(type ?? "")")
            }
            
            let id = pi["id"].element?.text
            let stateless = pi["stateless"].element?.text
            let place = normalizeLocationName(name: pi["locality"].element?.text)
            let coord = parseCoordinates(string: pi["c"].element?.text)
            
            let location: Location?
            let locationId = locationType == .station ? id : stateless
            if let name = name {
                location = Location(type: locationType, id: locationId, coord: coord, place: place, name: name)
            } else {
                location = Location(type: locationType, id: locationId, coord: coord, place: nil, name: place)
            }
            if let location = location {
                locations.append(location)
            } else {
                throw ParseError(reason: "failed to parse location")
            }
        }
        completion(httpRequest, .success(locations: locations))
    }
    
    func handleMobileTripRequestResponse(httpRequest: HttpRequest, xml: XMLIndexer, desktopUrl: URL?, from: Location?, via: Location?, to: Location?, previousContext: Context?, later: Bool, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) throws {
        let request = xml["efa"]
        let requestId = request["pas"]["pa"].all.first(where: {$0["n"].element?.text == "requestID"})?["v"].element?.text
        let sessionId = request["pas"]["pa"].all.first(where: {$0["n"].element?.text == "sessionID"})?["v"].element?.text
        
        var trips: [Trip] = []
        for tp in request["ts"]["tp"].all {
            let tripId = ""
            
            var firstDepartureLocation: Location? = nil
            var lastArrivalLocation: Location? = nil
            
            
            var legs: [Leg] = []
            for l in tp["ls"]["l"].all {
                let realtime = l["realtime"].element?.text == "1"
                var departure: Stop? = nil
                var arrival: Stop? = nil
                for p in l["ps"]["p"].all {
                    let name = p["n"].element?.text
                    let id = p["r"]["id"].element?.text
                    let usage = p["u"].element?.text
                    
                    let plannedTime = parseMobilePlannedTime(xml: p["st"])
                    let predictedTime = realtime ? parseMobilePredictedTime(xml: p["st"]) : nil
                    
                    let position = parsePosition(position: p["r"]["pl"].element?.text)
                    let place = normalizeLocationName(name: p["r"]["pc"].element?.text)
                    let coord = parseCoordinates(string: p["r"]["c"].element?.text)
                    
                    let location: Location?
                    if id == "99999997" || id == "99999998" {
                        location = Location(type: .address, id: nil, coord: coord, place: place, name: name)
                    } else {
                        location = Location(type: .station, id: id, coord: coord, place: place, name: name)
                    }
                    if let location = location {
                        if usage == "departure" {
                            departure = Stop(location: location, plannedArrivalTime: nil, predictedArrivalTime: nil, plannedArrivalPlatform: nil, predictedArrivalPlatform: nil, arrivalCancelled: false, plannedDepartureTime: plannedTime, predictedDepartureTime: predictedTime, plannedDeparturePlatform: position, predictedDeparturePlatform: nil, departureCancelled: false)
                            if firstDepartureLocation == nil {
                                firstDepartureLocation = location
                            }
                        } else if usage == "arrival" {
                            arrival = Stop(location: location, plannedArrivalTime: plannedTime, predictedArrivalTime: predictedTime, plannedArrivalPlatform: position, predictedArrivalPlatform: nil, arrivalCancelled: false, plannedDepartureTime: nil, predictedDepartureTime: nil, plannedDeparturePlatform: nil, predictedDeparturePlatform: nil, departureCancelled: false)
                            lastArrivalLocation = location
                        } else {
                            throw ParseError(reason: "unknown usage \(usage ?? "")")
                        }
                    } else {
                        throw ParseError(reason: "failed to parse location")
                    }
                }
                
                if let arrival = arrival, let departure = departure {
                    let lineDestination = try parseMobileLineDestination(xml: l, tyOrCo: false)
                    let path: [LocationPoint]
                    if let coordString = l["pt"].element?.text {
                        path = processCoordinateStrings(coordString)
                    } else {
                        path = []
                    }
                    
                    var intermediateStops: [Stop] = []
                    
                    for stop in l["pss"]["s"].all {
                        guard let s = stop.element?.text else { throw ParseError(reason: "failed to parse stop") }
                        let intermediateParts = s.components(separatedBy: ";")
                        guard intermediateParts.count > 4 else { throw ParseError(reason: "failed to parse intermediate") }
                        let id = intermediateParts[0]
                        if id != departure.location.id && id != arrival.location.id {
                            let name = normalizeLocationName(name: intermediateParts[1])!
                            
                            var plannedTime: Date? = nil
                            var predictedTime: Date? = nil
                            if !(intermediateParts[2] == "0000-1" && intermediateParts[3] == "000-1") {
                                var dateComponents = DateComponents()
                                dateComponents.timeZone = timeZone
                                parseIsoDate(from: intermediateParts[2], dateComponents: &dateComponents)
                                parseIsoTime(from: intermediateParts[3], dateComponents: &dateComponents)
                                plannedTime = gregorianCalendar.date(from: dateComponents)
                                
                                if realtime {
                                    dateComponents = DateComponents()
                                    dateComponents.timeZone = timeZone
                                    parseIsoDate(from: intermediateParts[2], dateComponents: &dateComponents)
                                    parseIsoTime(from: intermediateParts[3], dateComponents: &dateComponents)
                                    predictedTime = gregorianCalendar.date(from: dateComponents)
                                    
                                    if intermediateParts.count > 5 && intermediateParts[5].length > 0 {
                                        if let delay = Int(intermediateParts[5]) {
                                            predictedTime = predictedTime?.addingTimeInterval(Double(delay) * 60.0)
                                        }
                                    }
                                }
                            }
                            let coordPart = intermediateParts[4]
                            let coords: LocationPoint?
                            if coordPart != "::" {
                                let coordParts = coordPart.components(separatedBy: ":")
                                if coordParts[2] == "WGS84", let lat = Double(coordParts[1]), let lon = Double(coordParts[0]) {
                                    coords = LocationPoint(lat: Int(round(lat)), lon: Int(round(lon)))
                                } else {
                                    coords = nil
                                }
                            } else {
                                coords = nil
                            }
                            
                            let location = Location(type: .station, id: id, coord: coords, place: nil, name: name)
                            if let location = location {
                                let stop = Stop(location: location, plannedArrivalTime: plannedTime, predictedArrivalTime: predictedTime, plannedArrivalPlatform: nil, predictedArrivalPlatform: nil, arrivalCancelled: false, plannedDepartureTime: nil, predictedDepartureTime: nil, plannedDeparturePlatform: nil, predictedDeparturePlatform: nil, departureCancelled: false)
                                intermediateStops.append(stop)
                            } else {
                                throw ParseError(reason: "failed to parse stop location")
                            }
                        }
                    }
                    let addTime: TimeInterval = !legs.isEmpty ? max(0, -departure.getMinTime().timeIntervalSince(legs.last!.getMaxTime())) : 0
                    if lineDestination.line === Line.FOOTWAY {
                        legs.append(IndividualLeg(type: .WALK, departureTime: departure.getMinTime().addingTimeInterval(addTime), departure: departure.location, arrival: arrival.location, arrivalTime: arrival.getMaxTime().addingTimeInterval(addTime), distance: 0, path: path))
                    } else if lineDestination.line === Line.TRANSFER {
                        legs.append(IndividualLeg(type: .TRANSFER, departureTime: departure.getMinTime().addingTimeInterval(addTime), departure: departure.location, arrival: arrival.location, arrivalTime: arrival.getMaxTime().addingTimeInterval(addTime), distance: 0, path: path))
                    } else if lineDestination.line === Line.DO_NOT_CHANGE {
                        if let last = legs.last as? PublicLeg {
                            var lastMessage = "Nicht umsteigen, Weiterfahrt im selben Fahrzeug möglich."
                            if let message = last.message?.emptyToNil {
                                lastMessage += "\n" + message
                            }
                            legs[legs.count - 1] = PublicLeg(line: last.line, destination: last.destination, departureStop: last.departureStop, arrivalStop: last.arrivalStop, intermediateStops: last.intermediateStops, message: lastMessage, path: last.path, journeyContext: last.journeyContext)
                        }
                    } else if lineDestination.line === Line.SECURE_CONNECTION {
                        // ignore
                    } else {
                        let journeyContext: EfaJourneyContext? = nil
                        legs.append(PublicLeg(line: lineDestination.line, destination: lineDestination.destination, departureStop: departure, arrivalStop: arrival, intermediateStops: intermediateStops, message: nil, path: path, journeyContext: journeyContext))
                    }
                } else {
                    throw ParseError(reason: "failed to parse stop")
                }
            }
            
            var fares: [Fare] = []
            for elem in tp["tcs"]["tc"].all {
                guard let net = elem["net"].element?.text, let type = elem["n"].element?.text, type == "SINGLE_TICKET" else { continue }
                let unitsName = elem["un"].element?.text
                if let fareAdult = elem["fa"].element?.text, let fare = Float(fareAdult), fare != 0 {
                    let unit = elem["ua"].element?.text
                    fares.append(Fare(network: net.uppercased(), type: .adult, currency: "EUR", fare: fare, unitsName: unitsName, units: unit))
                }
                if let fareChild = elem["fc"].element?.text, let fare = Float(fareChild), fare != 0 {
                    let unit = elem["uc"].element?.text
                    fares.append(Fare(network: net.uppercased(), type: .child, currency: "EUR", fare: fare, unitsName: unitsName, units: unit))
                }
                break
            }
            
            let context: EfaRefreshTripContext? = nil
            //            if let sessionId = sessionId, let requestId = requestId {
            //                context = EfaRefreshTripContext(sessionId: sessionId, requestId: requestId, routeIndex: "\(trips.count + 1)")
            //            } else {
            //                context = nil
            //            }
            if let firstDepartureLocation = firstDepartureLocation, let lastArrivalLocation = lastArrivalLocation {
                let trip = Trip(id: tripId, from: firstDepartureLocation, to: lastArrivalLocation, legs: legs, fares: fares, refreshContext: context)
                trips.append(trip)
            } else {
                throw ParseError(reason: "failed to parse trip from/to")
            }
        }
        if trips.count > 0 {
            let context: Context?
            if let sessionId = sessionId, let requestId = requestId {
                if let previousContext = previousContext {
                    context = Context(queryEarlierContext: later ? previousContext.queryEarlierContext : (sessionId: sessionId, requestId: requestId), queryLaterContext: !later ? previousContext.queryLaterContext : (sessionId: sessionId, requestId: requestId), desktopUrl: desktopUrl)
                } else {
                    context = Context(queryEarlierContext: (sessionId: sessionId, requestId: requestId), queryLaterContext: (sessionId: sessionId, requestId: requestId), desktopUrl: desktopUrl)
                }
            } else {
                context = nil
            }
            completion(httpRequest, .success(context: context, from: from, via: via, to: to, trips: trips, messages: []))
        } else {
            completion(httpRequest, .noTrips)
        }
    }
    
    func handleQueryJourneyDetailMobileResponse(httpRequest: HttpRequest, xml: XMLIndexer, line: Line, completion: @escaping (HttpRequest, QueryJourneyDetailResult) -> Void) throws {
        let request = xml["efa"]["stopSeqCoords"]
        var stops: [Stop] = []
        let format = DateFormatter()
        format.dateFormat = "yyyyMMdd HH:mm"
        for p in request["params"]["stopSeq"]["p"].all {
            guard let timeString = p["r"]["depDateTime"].element?.text ?? p["r"]["arrDateTime"].element?.text else { throw ParseError(reason: "failed to parse time") }
            let name = p["n"].element?.text
            let id = p["r"]["id"].element?.text
            
            let plannedTime = format.date(from: timeString)
            
            let position = parsePosition(position: p["r"]["pl"].element?.text)
            let place = normalizeLocationName(name: p["r"]["pc"].element?.text)
            let coord = parseCoordinates(string: p["r"]["c"].element?.text)
            
            guard let location = Location(type: .station, id: id, coord: coord, place: place, name: name) else { throw ParseError(reason: "failed to parse stop") }
            let stop = Stop(location: location, plannedArrivalTime: plannedTime, predictedArrivalTime: nil, plannedArrivalPlatform: nil, predictedArrivalPlatform: nil, arrivalCancelled: false, plannedDepartureTime: plannedTime, predictedDepartureTime: nil, plannedDeparturePlatform: position, predictedDeparturePlatform: nil, departureCancelled: false)
            stops.append(stop)
        }
        guard stops.count >= 2 else {
            throw ParseError(reason: "could not parse points")
        }
        let departureStop = stops.removeFirst()
        let arrivalStop = stops.removeLast()
        let path: [LocationPoint]
        if let coordString = request["c"]["pt"].element?.text {
            path = processCoordinateStrings(coordString)
        } else {
            path = []
        }
        let leg = PublicLeg(line: line, destination: arrivalStop.location, departureStop: departureStop, arrivalStop: arrivalStop, intermediateStops: stops, message: nil, path: path, journeyContext: nil)
        let trip = Trip(id: "", from: departureStop.location, to: arrivalStop.location, legs: [leg], fares: [])
        completion(httpRequest, .success(trip: trip, leg: leg))
    }
    
    // MARK: Request parameters
    
    func stopFinderRequestParameters(builder: UrlBuilder, constraint: String, types: [LocationType]?, maxLocations: Int, outputFormat: String) {
        appendCommonRequestParameters(builder: builder, outputFormat: outputFormat)
        builder.addParameter(key: "locationServerActive", value: 1)
        
        if includeRegionId {
            builder.addParameter(key: "regionID_sf", value: 1)
        }
        builder.addParameter(key: "type_sf", value: "any")
        builder.addParameter(key: "name_sf", value: constraint)
        if needsSpEncId {
            builder.addParameter(key: "SpEncId", value: 0)
        }
        // 1=place 2=stop 4=street 8=address 16=crossing 32=poi 64=postcode
        var filter = 0
        if types == nil || types!.contains(.station) {
            filter += 2
        }
        if types == nil || types!.contains(.poi) {
            filter += 32
        }
        if types == nil || types!.contains(.address) {
            filter += 4 + 8 + 16 + 64
        }
        builder.addParameter(key: "anyObjFilter_sf", value: filter)
        builder.addParameter(key: "reducedAnyPostcodeObjFilter_sf", value: 64)
        builder.addParameter(key: "reducedAnyTooManyObjFilter_sf", value: 2)
        builder.addParameter(key: "useHouseNumberList", value: true)
        if maxLocations > 0 {
            builder.addParameter(key: "anyMaxSizeHitList", value: maxLocations)
        }
    }
    
    func nearbyStationsRequestParameters(builder: UrlBuilder, stationId: String, maxLocations: Int) {
        appendCommonRequestParameters(builder: builder, outputFormat: "XML")
        builder.addParameter(key: "type_dm", value: "stop")
        builder.addParameter(key: "name_dm", value: normalize(stationId: stationId))
        builder.addParameter(key: "itOptionsActive", value: 1)
        builder.addParameter(key: "ptOptionsActive", value: 1)
        if useProxFootSearch {
            builder.addParameter(key: "useProxFootSearch", value: 1)
        }
        builder.addParameter(key: "mergeDep", value: 1)
        builder.addParameter(key: "useAllStops", value: 1)
        builder.addParameter(key: "mode", value: "direct")
    }
    
    func commandLink(builder: UrlBuilder, sessionId: String, requestId: String) {
        builder.addParameter(key: "sessionID", value: sessionId)
        builder.addParameter(key: "requestID", value: requestId)
        builder.addParameter(key: "calcNumberOfTrips", value: numTripsRequested)
    }
    
    func queryTripsParameters(builder: UrlBuilder, from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions, desktop: Bool) {
        appendCommonRequestParameters(builder: builder, outputFormat: desktop ? nil : "XML")
        builder.addParameter(key: "sessionID", value: 0)
        builder.addParameter(key: "requestID", value: 0)
        builder.addParameter(key: "coordListOutputFormat", value: "STRING")
        appendLocation(builder: builder, location: from, suffix: "origin")
        appendLocation(builder: builder, location: to, suffix: "destination")
        if let via = via {
            appendLocation(builder: builder, location: via, suffix: "via")
        }
        appendDate(builder: builder, date: date)
        builder.addParameter(key: "itdTripDateTimeDepArr", value: departure ? "dep" : "arr")
        builder.addParameter(key: "calcNumberOfTrips", value: numTripsRequested)
        builder.addParameter(key: "ptOptionsActive", value: 1) // enable public transport options
        builder.addParameter(key: "itOptionsActive", value: 1) // enable individual transport options
        
        if let optimize = tripOptions.optimize {
            switch optimize {
            case .leastDuration:
                builder.addParameter(key: "routeType", value: "LEASTTIME")
                break
            case .leastChanges:
                builder.addParameter(key: "routeType", value: "LEASTINTERCHANGE")
                break
            case .leastWalking:
                builder.addParameter(key: "routeType", value: "LEASTWALKING")
                break
            }
        }
        if let walkSpeed = tripOptions.walkSpeed {
            switch walkSpeed {
            case .slow:
                builder.addParameter(key: "changeSpeed", value: "slow")
                break
            case .normal:
                builder.addParameter(key: "changeSpeed", value: "normal")
                break
            case .fast:
                builder.addParameter(key: "changeSpeed", value: "fast")
                break
            }
        }
        if let accessibility = tripOptions.accessibility {
            if accessibility == .barrierFree {
                builder.addParameter(key: "imparedOptionsActive", value: 1)
                builder.addParameter(key: "wheelchair", value: "on")
                builder.addParameter(key: "noSolidStairs", value: "on")
            } else if accessibility == .limited {
                builder.addParameter(key: "imparedOptionsActive", value: 1)
                builder.addParameter(key: "wheelchair", value: "on")
                builder.addParameter(key: "lowPlatformVhcl", value: "on")
                builder.addParameter(key: "noSolidStairs", value: "on")
            }
        }
        
        if let products = tripOptions.products {
            builder.addParameter(key: "includedMeans", value: "checkbox")
            
            for product in products {
                switch product {
                case .highSpeedTrain, .regionalTrain:
                    builder.addParameter(key: "inclMOT_0", value: "on")
                    break
                case .suburbanTrain:
                    builder.addParameter(key: "inclMOT_1", value: "on")
                    break
                case .subway:
                    builder.addParameter(key: "inclMOT_2", value: "on")
                    break
                case .tram:
                    builder.addParameter(key: "inclMOT_3", value: "on")
                    builder.addParameter(key: "inclMOT_4", value: "on")
                    break
                case .bus:
                    builder.addParameter(key: "inclMOT_5", value: "on")
                    builder.addParameter(key: "inclMOT_6", value: "on")
                    builder.addParameter(key: "inclMOT_7", value: "on")
                    break
                case .onDemand:
                    builder.addParameter(key: "inclMOT_10", value: "on")
                    break
                case .ferry:
                    builder.addParameter(key: "inclMOT_9", value: "on")
                    break
                case .cablecar:
                    builder.addParameter(key: "inclMOT_8", value: "on")
                    break
                }
            }
            if useLineRestriction && products.contains(.regionalTrain) && !products.contains(.highSpeedTrain) {
                builder.addParameter(key: "lineRestriction", value: "403")
            }
        }
        
        if useProxFootSearch {
            builder.addParameter(key: "useProxFootSearch", value: 1) // walk if it makes journeys quicker
        }
        builder.addParameter(key: "trITMOTvalue100", value: 10) // maximum time to walk to first or from last stop
        
        if let options = tripOptions.options, options.contains(.bike) {
            builder.addParameter(key: "bikeTakeAlong", value: 1)
        }
        
        if let maxChanges = tripOptions.maxChanges {
            builder.addParameter(key: "maxChanges", value: maxChanges)
        }
        
        builder.addParameter(key: "locationServerActive", value: 1)
        builder.addParameter(key: "useRealtime", value: 1)
        builder.addParameter(key: "nextDepsPerLeg", value: 1)
    }
    
    private func coordRequestParameters(builder: UrlBuilder, types: [LocationType]?, lat: Int, lon: Int, maxDistance: Int, maxLocations: Int) {
        appendCommonRequestParameters(builder: builder, outputFormat: "XML")
        builder.addParameter(key: "coord", value: String(format: "%2.6f:%2.6f:WGS84", Double(lon) / 1e6, Double(lat) / 1e6))
        builder.addParameter(key: "coordListOutputFormat", value: "STRING")
        builder.addParameter(key: "max", value: maxLocations == 0 ? 50 : maxLocations)
        builder.addParameter(key: "inclFilter", value: 1)
        for (index, type) in (types ?? [.station]).enumerated() {
            builder.addParameter(key: "radius_\(index + 1)", value: maxDistance == 0 ? 1320 : maxDistance)
            builder.addParameter(key: "type_\(index + 1)", value: type == .poi ? "POI_POINT" : "STOP")
        }
    }
    
    func appendDate(builder: UrlBuilder, date: Date, dateParam: String = "itdDate", timeParam: String = "itdTime") {
        builder.addParameter(key: dateParam, value: dateFormatter.string(from: date))
        builder.addParameter(key: timeParam, value: timeFormatter.string(from: date))
    }
    
    func queryDeparturesParameters(builder: UrlBuilder, stationId: String, departures: Bool, time: Date?, maxDepartures: Int, equivs: Bool, desktop: Bool) {
        appendCommonRequestParameters(builder: builder, outputFormat: desktop ? nil : "XML")
        builder.addParameter(key: "type_dm", value: "stop")
        builder.addParameter(key: "name_dm", value: stationId)
        if let time = time {
            appendDate(builder: builder, date: time)
        }
        builder.addParameter(key: "useRealtime", value: 1)
        builder.addParameter(key: "mode", value: "direct")
        builder.addParameter(key: "ptOptionsActive", value: 1)
        builder.addParameter(key: "deleteAssignedStops_dm", value: equivs ? 0 : 1)
        if useProxFootSearch {
            builder.addParameter(key: "useProxFootSearch", value: equivs ? 1 : 0)
        }
        builder.addParameter(key: "mergeDep", value: 1)
        if maxDepartures > 0 {
            builder.addParameter(key: "limit", value: maxDepartures)
        }
        builder.addParameter(key: "itdDateTimeDepArr", value: departures ? "dep" : "arr")
    }
    
    private func appendCommonRequestParameters(builder: UrlBuilder, outputFormat: String? = "JSON") {
        if let outputFormat = outputFormat {
            builder.addParameter(key: "outputFormat", value: outputFormat)
        }
        builder.addParameter(key: "language", value: language)
        builder.addParameter(key: "stateless", value: 1)
        builder.addParameter(key: "coordOutputFormat", value: "WGS84")
    }
    
    func appendLocation(builder: UrlBuilder, location: Location, suffix: String) {
        switch (location.type, normalize(stationId: location.id), location.coord) {
        case let (.station, id?, _):
            builder.addParameter(key: "type_\(suffix)", value: "stop")
            builder.addParameter(key: "name_\(suffix)", value: id)
        case let (.poi, id?, _):
            builder.addParameter(key: "type_\(suffix)", value: "poi")
            builder.addParameter(key: "name_\(suffix)", value: id)
        case let (.address, id?, _):
            builder.addParameter(key: "type_\(suffix)", value: "address")
            builder.addParameter(key: "name_\(suffix)", value: id)
        case let (type, _, coord?) where type == .coord || type == .address:
            builder.addParameter(key: "type_\(suffix)", value: "coord")
            builder.addParameter(key: "name_\(suffix)", value: String(format: "%.6f:%.6f:WGS84", Double(coord.lon) / 1e6, Double(coord.lat) / 1e6))
        default:
            builder.addParameter(key: "type_\(suffix)", value: "any")
            builder.addParameter(key: "name_\(suffix)", value: location.getUniqueLongName())
        }
    }
    
    func locationValue(location: Location) -> String {
        return location.id ?? location.getUniqueLongName()
    }
    
    // MARK: Response parse methods
    
    func processItdOdv(odv: XMLIndexer, expectedUsage: String, callback: (_ nameState: String?, _ location: Location, _ matchQuality: Int) -> Void) throws -> String {
        guard let usage = odv.element?.attribute(by: "usage")?.text, usage == expectedUsage else {
            throw ParseError(reason: "expecting \(expectedUsage), got \(odv.element?.attribute(by: "usage")?.text ?? "unknown")")
        }
        
        let type = odv.element?.attribute(by: "type")?.text
        let place = try processItdOdvPlace(odv: odv["itdOdvPlace"])
        let nameState = odv["itdOdvName"].element?.attribute(by: "state")?.text
        if nameState == "identified" {
            let location = try processOdvNameElem(odv: odv["itdOdvName"]["odvNameElem"], type: type, defaultPlace: place)
            if let location = location {
                callback(nameState, location, Int(INT_MAX))
            }
        } else if nameState == "list" {
            for nameElem in odv["itdOdvName"]["odvNameElem"].all {
                let matchQuality = Int(nameElem.element?.attribute(by: "matchQuality")?.text ?? "") ?? Int(INT_MAX)
                let location = try processOdvNameElem(odv: nameElem, type: type, defaultPlace: place)
                if let location = location {
                    callback(nameState, location, matchQuality)
                }
            }
        } else if nameState != "notidentified" && nameState != "empty" {
            throw ParseError(reason: "cannot handle namestate \(nameState ?? "")")
        }
        
        for assignedStop in odv["itdOdvAssignedStops"]["itdOdvAssignedStop"].all {
            let stop = processItdOdvAssignedStop(odv: assignedStop)
            if let stop = stop {
                callback("assigned", stop, 0)
            }
        }
        
        return nameState ?? ""
    }
    
    func processItdOdvPlace(odv: XMLIndexer) throws -> String? {
        guard let placeState = odv.element?.attribute(by: "state")?.text else { throw ParseError(reason: "place state not found") }
        if placeState == "identified" {
            return odv["odvPlaceElem"].element?.text
        } else {
            return nil
        }
    }
    
    func processOdvNameElem(odv: XMLIndexer, type: String?, defaultPlace: String?) throws -> Location? {
        var type = type
        if type == "any" {
            type = odv.element?.attribute(by: "anyType")?.text
        }
        guard let id = odv.element?.attribute(by: "stateless")?.text else { throw ParseError(reason: "could not parse odv name id") }
        let locality = normalizeLocationName(name: odv.element?.attribute(by: "locality")?.text)
        let objectName = normalizeLocationName(name: odv.element?.attribute(by: "objectName")?.text)
        let buildingName = odv.element?.attribute(by: "buildingName")?.text
        let buildingNumber = odv.element?.attribute(by: "buildingNumber")?.text
        let postCode = odv.element?.attribute(by: "postCode")?.text
        let streetName = odv.element?.attribute(by: "streetName")?.text
        let coord = processCoordAttr(odv: odv)
        
        let nameElem = normalizeLocationName(name: odv.element?.text)
        
        let locationType: LocationType
        let place: String?
        let name: String?
        
        if type == "stop" {
            locationType = .station
            place = locality ?? defaultPlace
            name = objectName ?? nameElem
        } else if type == "poi" {
            locationType = .poi
            place = locality ?? defaultPlace
            name = objectName ?? nameElem
        } else if type == "loc" {
            if let locality = locality {
                locationType = .address
                place = nil
                name = locality
            } else if let nameElem = nameElem {
                locationType = .address
                place = nil
                name = nameElem
            } else if let _ = coord {
                locationType = .coord
                place = nil
                name = nil
            } else {
                throw ParseError(reason: "failed to parse location")
            }
        } else if type == "address" || type == "singlehouse" {
            locationType = .address
            place = locality ?? defaultPlace
            if let objectName = objectName, let buildingNumber = buildingNumber {
                name = objectName + " " + buildingNumber
            } else {
                name = objectName
            }
        } else if type == "street" || type == "crossing" {
            locationType = .address
            place = locality ?? defaultPlace
            name = objectName ?? nameElem
        } else if type == "postcode" {
            locationType = .address
            place = locality ?? defaultPlace
            name = postCode
        } else if type == "buildingname" {
            locationType = .address
            place = locality ?? defaultPlace
            name = buildingName ?? streetName
        } else if type == "coord" {
            locationType = .address
            place = defaultPlace
            name = nameElem
        } else {
            throw ParseError(reason: "unknown type \(type ?? "")")
        }
        
        return Location(type: locationType, id: id, coord: coord, place: place, name: name)
    }
    
    func processItdOdvAssignedStop(odv: XMLIndexer) -> Location? {
        guard let id = odv.element?.attribute(by: "stopID")?.text else { return nil }
        let coord = processCoordAttr(odv: odv)
        let place = normalizeLocationName(name: odv.element?.attribute(by: "place")?.text)
        guard let name = normalizeLocationName(name: odv.element?.text) else { return nil }
        
        return Location(type: .station, id: id, coord: coord, place: place, name: name)
    }
    
    func processItdPointAttributes(point: XMLIndexer) -> Location? {
        guard let id = point.element?.attribute(by: "stopID")?.text else { return nil }
        var place = normalizeLocationName(name: point.element?.attribute(by: "locality")?.text)
        if place == nil {
            place = normalizeLocationName(name: point.element?.attribute(by: "place")?.text)
        }
        var name = normalizeLocationName(name: point.element?.attribute(by: "nameWO")?.text)
        if name == nil || name == "???" || place == nil {
            name = normalizeLocationName(name: point.element?.attribute(by: "name")?.text)
        }
        let coord = processCoordAttr(odv: point)
        let isStop = id != "99999999" && id != "99999998" && id != "99999997"
        return Location(type: isStop ? .station : .any, id: isStop ? id : nil, coord: coord, place: place, name: name)
    }
    
    func processPublicLeg(_ xml: XMLIndexer, _ legs: inout [Leg], _ departureTime: Date, _ departureTargetTime: Date?, _ departureLocation: Location, _ departurePosition: String?, _ plannedDeparturePosition: String?, _ arrivalTime: Date, _ arrivalTargetTime: Date?, _ arrivalLocation: Location, _ arrivalPosition: String?, _ plannedArrivalPosition: String?, _ legMessages: [String]) throws -> Bool {
        let motSymbol = xml["itdMeansOfTransport"].element?.attribute(by: "symbol")?.text
        let motType = xml["itdMeansOfTransport"].element?.attribute(by: "motType")?.text
        let motShortName = xml["itdMeansOfTransport"].element?.attribute(by: "shortname")?.text
        let motName = xml["itdMeansOfTransport"].element?.attribute(by: "name")?.text
        let motTrainName = xml["itdMeansOfTransport"].element?.attribute(by: "trainName")?.text
        let motTrainType = xml["itdMeansOfTransport"].element?.attribute(by: "trainType")?.text
        let tripCode = xml["itdMeansOfTransport"].element?.attribute(by: "tC")?.text
        let number = xml["itdMeansOfTransport"].element?.attribute(by: "number")?.text
        let trainNum = xml["itdMeansOfTransport"].element?.attribute(by: "trainNum")?.text
        
        guard let divaNetwork = xml["itdMeansOfTransport"]["motDivaParams"].element?.attribute(by: "network")?.text, let divaLine = xml["itdMeansOfTransport"]["motDivaParams"].element?.attribute(by: "line")?.text, let divaDirection = xml["itdMeansOfTransport"]["motDivaParams"].element?.attribute(by: "direction")?.text else {
            throw ParseError(reason: "diva")
        }
        let divaSupplement = xml["itdMeansOfTransport"]["motDivaParams"].element?.attribute(by: "supplement")?.text ?? ""
        let divaProject = xml["itdMeansOfTransport"]["motDivaParams"].element?.attribute(by: "project")?.text ?? ""
        let lineId = divaNetwork + ":" + divaLine + ":" + divaSupplement + ":" + divaDirection + ":" + divaProject
        
        let line: Line
        if motSymbol == "AST" {
            line = Line(id: nil, network: divaNetwork, product: .onDemand, label: "AST")
        } else {
            line = parseLine(id: lineId, network: divaNetwork, mot: motType, symbol: motSymbol, name: motShortName, longName: motName, trainType: motTrainType, trainNum: motShortName, trainName: motTrainName)
        }
        
        var destinationName = stripLineFromDestination(line: line, destinationName: normalizeLocationName(name: xml["itdMeansOfTransport"].element?.attribute(by: "destination")?.text))
        var messages = Set<String>()
        if let destination = destinationName, destination.hasSuffix(" EILZUG") {
            destinationName = String(destination.dropLast(" EILZUG".count))
            messages.insert("Eilzug: Zug hält nicht überall.")
        }
        let destinationId = xml["itdMeansOfTransport"].element?.attribute(by: "destID")?.text
        let destination: Location?
        if let destinationId = destinationId, destinationId != "" {
            destination = Location(type: .station, id: destinationId, coord: nil, place: nil, name: destinationName)
        } else if let destinationName = destinationName {
            destination = Location(anyName: destinationName)
        } else {
            destination = nil
        }
        
        var lowFloorVehicle = false
        for infoText in xml["itdInfoTextList"]["infoTextListElem"].all {
            if let text = infoText.element?.text {
                if text.lowercased().hasPrefix("niederflurwagen") {
                    lowFloorVehicle = true
                } else if text.lowercased().contains("ruf") || text.lowercased().contains("anmeld") || text.lowercased().contains("ast") {
                    messages.insert(String(htmlEncodedString: text) ?? text)
                }
            }
        }
        
        if let infoText = xml["infoLink"]["infoLinkText"].element?.text {
            messages.insert(String(htmlEncodedString: infoText) ?? infoText)
        }
        messages = messages.union(legMessages)
        
        let rblDepartureDelay = Int(xml["itdRBLControlled"].element?.attribute(by: "delayMinutes")?.text ?? "")
        let rblArrivalDelay = Int(xml["itdRBLControlled"].element?.attribute(by: "delayMinutesArr")?.text ?? "")
        let cancelled = rblDepartureDelay == -9999 || rblArrivalDelay == -9999
        
        var stops: [Stop] = []
        for point in xml["itdStopSeq"]["itdPoint"].all {
            guard let stopLocation = processItdPointAttributes(point: point) else { continue }
            let stopPosition = parsePosition(position: point.element?.attribute(by: "platformName")?.text)
            
            let plannedStopArrivalTime = processItdDateTime(xml: point["itdDateTime"][0])
            var predictedStopArrivalTime = processItdDateTime(xml: point["itdDateTimeTarget"][0])
            var arrivalCancelled = cancelled
            if let delay = Int(point.element?.attribute(by: "arrDelay")?.text ?? ""), delay != -1, predictedStopArrivalTime == nil {
                if delay == -9999 {
                    arrivalCancelled = true
                } else {
                    predictedStopArrivalTime = plannedStopArrivalTime?.addingTimeInterval(TimeInterval(delay * 60))
                }
            }
            if let rblArrivalDelay = rblArrivalDelay, rblArrivalDelay != -9999, predictedStopArrivalTime == nil {
                predictedStopArrivalTime = plannedStopArrivalTime?.addingTimeInterval(TimeInterval(rblArrivalDelay * 60))
            }
            let plannedStopDepartureTime = point["itdDateTime"].all.count > 1 ? processItdDateTime(xml: point["itdDateTime"][1]) : plannedStopArrivalTime
            var predictedStopDepartureTime = point["itdDateTimeTarget"].all.count > 1 ? processItdDateTime(xml: point["itdDateTimeTarget"][1]) : predictedStopArrivalTime
            var departureCancelled = cancelled
            if let delay = Int(point.element?.attribute(by: "depDelay")?.text ?? ""), delay != -1, predictedStopDepartureTime == nil {
                if delay == -9999 {
                    departureCancelled = true
                } else {
                    predictedStopDepartureTime = plannedStopDepartureTime?.addingTimeInterval(TimeInterval(delay * 60))
                }
            }
            if let rblDepartureDelay = rblDepartureDelay, rblDepartureDelay != -9999, predictedStopDepartureTime == nil {
                predictedStopDepartureTime = plannedStopDepartureTime?.addingTimeInterval(TimeInterval(rblDepartureDelay * 60))
            }
            
            let stop = Stop(location: stopLocation, plannedArrivalTime: plannedStopArrivalTime, predictedArrivalTime: predictedStopArrivalTime, plannedArrivalPlatform: stopPosition, predictedArrivalPlatform: nil, arrivalCancelled: arrivalCancelled, plannedDepartureTime: plannedStopDepartureTime, predictedDepartureTime: predictedStopDepartureTime, plannedDeparturePlatform: stopPosition, predictedDeparturePlatform: nil, departureCancelled: departureCancelled)
            
            stops.append(stop)
        }
        
        let departure: Stop
        let arrival: Stop
        if stops.count >= 2 {
            if !stops.last!.location.isEqual(arrivalLocation) {
                throw ParseError(reason: "last intermediate stop is not arrival location!")
            }
            let a = stops.removeLast()
            // workaround for MVV sending wrong position for arrival and departure locations in intermediate stops
            // still use the time of the intermediate point because arrival and departure time is *always* sent as predicted, even when its not
            arrival = Stop(location: a.location, plannedArrivalTime: a.plannedArrivalTime, predictedArrivalTime: a.predictedArrivalTime, plannedArrivalPlatform: plannedArrivalPosition ?? a.plannedArrivalPlatform, predictedArrivalPlatform: arrivalPosition ?? a.predictedArrivalPlatform, arrivalCancelled: a.arrivalCancelled, plannedDepartureTime: nil, predictedDepartureTime: nil, plannedDeparturePlatform: nil, predictedDeparturePlatform: nil, departureCancelled: false, message: a.message, wagonSequenceContext: a.wagonSequenceContext)
            if !stops.first!.location.isEqual(departureLocation) {
                throw ParseError(reason: "first intermediate stop is not departure location!")
            }
            let d = stops.removeFirst()
            departure = Stop(location: d.location, plannedArrivalTime: nil, predictedArrivalTime: nil, plannedArrivalPlatform: nil, predictedArrivalPlatform: nil, arrivalCancelled: false, plannedDepartureTime: d.plannedDepartureTime, predictedDepartureTime: d.predictedDepartureTime, plannedDeparturePlatform: plannedDeparturePosition ?? d.plannedDeparturePlatform, predictedDeparturePlatform: departurePosition ?? d.predictedDeparturePlatform, departureCancelled: d.departureCancelled, message: d.message, wagonSequenceContext: d.wagonSequenceContext)
        } else {
            departure = Stop(location: departureLocation, plannedArrivalTime: nil, predictedArrivalTime: nil, plannedArrivalPlatform: nil, predictedArrivalPlatform: nil, arrivalCancelled: false, plannedDepartureTime: departureTargetTime ?? departureTime, predictedDepartureTime: departureTime, plannedDeparturePlatform: departurePosition, predictedDeparturePlatform: nil, departureCancelled: cancelled)
            arrival = Stop(location: arrivalLocation, plannedArrivalTime: arrivalTargetTime ?? arrivalTime, predictedArrivalTime: arrivalTime, plannedArrivalPlatform: arrivalPosition, predictedArrivalPlatform: nil, arrivalCancelled: cancelled, plannedDepartureTime: nil, predictedDepartureTime: nil, plannedDeparturePlatform: nil, predictedDeparturePlatform: nil, departureCancelled: false)
        }
        
        let path = processItdPathCoordinates(xml["itdPathCoordinates"])
        
        var lineAttrs: [Line.Attr] = []
        if lowFloorVehicle {
            lineAttrs.append(Line.Attr.wheelChairAccess)
        }
        
        let styledLine = Line(id: line.id, network: line.network, product: line.product, label: line.label, name: line.label, number: number, trainNumber: trainNum, style: lineStyle(network: divaNetwork, product: line.product, label: line.label), attr: lineAttrs, message: nil)
        
        let journeyContext: EfaJourneyContext?
        if let departureId = departureLocation.id, let tripCode = tripCode, styledLine.id != nil {
            journeyContext = EfaJourneyContext(stopId: departureId, stopDepartureTime: departureTargetTime ?? departureTime, line: styledLine, tripCode: tripCode)
        } else {
            journeyContext = nil
        }
        
        legs.append(PublicLeg(line: styledLine, destination: destination, departureStop: departure, arrivalStop: arrival, intermediateStops: stops, message: messages.joined(separator: "\n").emptyToNil, path: path ?? [LocationPoint](), journeyContext: journeyContext))
        return cancelled
    }
    
    func processIndividualLeg(_ xml: XMLIndexer, _ legs: inout [Leg], _ type: IndividualLeg.`Type`, _ departureTime: Date, _ departureLocation: Location, _ arrivalTime: Date, _ arrivalLocation: Location) {
        var path: [LocationPoint] = processItdPathCoordinates(xml["itdPathCoordinates"]) ?? []
        
        if let lastLeg = legs.last as? IndividualLeg, lastLeg.type == type {
            legs.removeLast()
            path.insert(contentsOf: lastLeg.path, at: 0)
            legs.append(IndividualLeg(type: type, departureTime: lastLeg.departureTime, departure: lastLeg.departure, arrival: arrivalLocation, arrivalTime: arrivalTime, distance: 0, path: path))
        } else {
            let addTime: TimeInterval = !legs.isEmpty ? max(0, -departureTime.timeIntervalSince(legs.last!.getMaxTime())) : 0
            let leg = IndividualLeg(type: type, departureTime: departureTime.addingTimeInterval(addTime), departure: departureLocation, arrival: arrivalLocation, arrivalTime: arrivalTime.addingTimeInterval(addTime), distance: 0, path: path)
            legs.append(leg)
        }
    }
    
    func processItdPathCoordinates(_ xml: XMLIndexer) -> [LocationPoint]? {
        guard let coordEllipsoid = xml["coordEllipsoid"].element?.text, coordEllipsoid == "WGS84", let type = xml["coordType"].element?.text, type == "GEO_DECIMAL" else { return nil }
        
        if let coordString = xml["itdCoordinateString"].element?.text {
            return processCoordinateStrings(coordString)
        } else if xml["itdCoordinateBaseElemList"].all.count > 0 {
            return processCoordinateBaseElems(xml)
        }
        return nil
    }
    
    func processCoordinateStrings(_ coordString: String) -> [LocationPoint] {
        var path: [LocationPoint] = []
        for coords in coordString.components(separatedBy: " ") {
            if coords.isEmpty { continue }
            path.append(parseCoord(coords))
        }
        return path
    }
    
    func processCoordinateBaseElems(_ xml: XMLIndexer) -> [LocationPoint] {
        var path: [LocationPoint] = []
        for elem in xml["itdCoordinateBaseElemList"].children {
            guard let latStr = elem["y"].element?.text, let lonStr = elem["x"].element?.text else { continue }
            guard let latDouble = Double(latStr), let lonDouble = Double(lonStr) else { continue }
            let lat = Int(round(latDouble))
            let lon = Int(round(lonDouble))
            path.append(LocationPoint(lat: lat, lon: lon))
        }
        return path
    }
    
    func processItdDateTime(xml: XMLIndexer) -> Date? {
        let date = xml["itdDate"].element
        let time = xml["itdTime"].element
        guard let year = Int(date?.attribute(by: "year")?.text ?? ""), let month = Int(date?.attribute(by: "month")?.text ?? ""), let day = Int(date?.attribute(by: "day")?.text ?? ""), let hour = Int(time?.attribute(by: "hour")?.text ?? ""), let minute = Int(time?.attribute(by: "minute")?.text ?? "") else { return nil }
        
        if year == 0 || day == -1 || hour == -1 || minute == -1 {
            return nil
        }
        //        let second = Int(time?.attribute(by: "second")?.text ?? "") ?? 0
        
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        dateComponents.hour = hour
        dateComponents.minute = minute
        //        dateComponents.second = second
        dateComponents.timeZone = timeZone
        return NSCalendar(calendarIdentifier: .gregorian)?.date(from: dateComponents)
    }
    
    func processCoordAttr(odv: XMLIndexer) -> LocationPoint? {
        guard let mapName = odv.element?.attribute(by: "mapName")?.text, mapName == "WGS84" else { return nil }
        
        let x = Int(round(Double(odv.element?.attribute(by: "x")?.text ?? "0") ?? 0))
        let y = Int(round(Double(odv.element?.attribute(by: "y")?.text ?? "0") ?? 0))
        
        return LocationPoint(lat: y, lon: x)
    }
    
    func parseCoord(_ coordStr: String) -> LocationPoint {
        let parts = coordStr.components(separatedBy: ",")
        let lat = Int(Double(parts[1]) ?? 0)
        let lon = Int(Double(parts[0]) ?? 0)
        
        return LocationPoint(lat: lat, lon: lon)
    }
    
    let P_STATION_NAME_WHITESPACE = try! NSRegularExpression(pattern: "\\s+", options: .caseInsensitive)
    
    func normalizeLocationName(name: String?) -> String? {
        guard let name = name else { return nil }
        let result = P_STATION_NAME_WHITESPACE.stringByReplacingMatches(in: name, options: [], range: NSMakeRange(0, name.count), withTemplate: " ")
        if result == "" {
            return nil
        }
        return result
    }
    
    func split(directionName: String?) -> (name: String?, place: String?) {
        return (directionName, nil)
    }
    
    private func parseDate(xml: XMLIndexer) -> Date? {
        let date = xml["itdDate"]
        let time = xml["itdTime"]
        
        guard let yearStr = date.element?.attribute(by: "year")?.text, let year = Int(yearStr), let monthStr = date.element?.attribute(by: "month")?.text, let month = Int(monthStr), let dayStr = date.element?.attribute(by: "day")?.text, let day = Int(dayStr), let hourStr = time.element?.attribute(by: "hour")?.text, let hour = Int(hourStr), let minuteStr = time.element?.attribute(by: "minute")?.text, let minute = Int(minuteStr) else {
            return nil
        }
        var dateComponents = DateComponents()
        dateComponents.timeZone = timeZone
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        dateComponents.hour = hour
        dateComponents.minute = minute
        return NSCalendar(calendarIdentifier: .gregorian)?.date(from: dateComponents)
    }
    
    private func parseCoordinates(string: String?) -> LocationPoint? {
        if let string = string {
            let coordArr = string.components(separatedBy: ",")
            if coordArr.count == 2, let x = Double(coordArr[0]), let y = Double(coordArr[1]) {
                return LocationPoint(lat: Int(y), lon: Int(x))
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    let P_POSITION = try! NSRegularExpression(pattern: "(?:Gleis|Gl\\.|Bahnsteig|Bstg\\.|Bussteig|Busstg\\.|Steig|Hp\\.|Stop|Pos\\.|Zone|Platform|Stand|Bay|Stance)?\\s*(.+)", options: .caseInsensitive)
    
    override func parsePosition(position: String?) -> String? {
        guard let position = position else { return nil }
        if position.hasPrefix("Ri.") || position.hasPrefix("Richtung ") { return nil }
        if let match = position.match(pattern: P_POSITION) {
            return super.parsePosition(position: match[0])
        } else {
            return super.parsePosition(position: position)
        }
    }
    
    // MARK: Response mobile parse methods
    
    func parseMobilePlannedTime(xml: XMLIndexer) -> Date? {
        guard let timeString = xml["t"].element?.text, let dateString = xml["da"].element?.text else { return nil }
        
        var dateComponents = DateComponents()
        dateComponents.timeZone = timeZone
        parseIsoTime(from: timeString, dateComponents: &dateComponents)
        parseIsoDate(from: dateString, dateComponents: &dateComponents)
        
        return gregorianCalendar.date(from: dateComponents)
    }
    
    func parseMobilePredictedTime(xml: XMLIndexer) -> Date? {
        guard let timeString = xml["rt"].element?.text, let dateString = xml["rda"].element?.text else { return nil }
        
        var dateComponents = DateComponents()
        dateComponents.timeZone = timeZone
        parseIsoTime(from: timeString, dateComponents: &dateComponents)
        parseIsoDate(from: dateString, dateComponents: &dateComponents)
        
        return gregorianCalendar.date(from: dateComponents)
    }
    
    let P_MOBILE_M_SYMBOL = try! NSRegularExpression(pattern: "([^\\s]*)\\s+([^\\s]*)")
    
    func parseMobileLineDestination(xml: XMLIndexer, tyOrCo: Bool) throws -> LineDestination {
        let productNu = xml["m"]["nu"].element?.text
        let ty = xml["m"]["ty"].element?.text
        let n = xml["m"]["n"].element?.text
        
        let line: Line
        let destination: Location?
        if ty == "100" || ty == "99" {
            destination = nil
            line = Line.FOOTWAY
        } else if ty == "105" {
            destination = nil
            line = Line.TRANSFER
        } else if ty == "98" {
            destination = nil
            line = Line.SECURE_CONNECTION
        } else if ty == "97" {
            destination = nil
            line = Line.DO_NOT_CHANGE
        } else {
            guard let co = xml["m"]["co"].element?.text else { throw ParseError(reason: "failed to parse co") }
            let productType = tyOrCo ? ty : co
            let destinationName = normalizeLocationName(name: xml["m"]["des"].element?.text)
            if let destinationName = destinationName {
                destination = Location(anyName: destinationName)
            } else {
                destination = nil
            }
            let de = xml["m"]["de"].element?.text
            let productName = n ?? de
            let lineId = try parseMobileDiva(xml: xml["m"])
            
            let symbol: String
            if let productName = productName, productNu == nil {
                symbol = productName
            } else if let productName = productName, let productNu = productNu, productNu.hasSuffix(" " + productName) {
                symbol = String(productNu[..<productNu.index(productNu.startIndex, offsetBy: productNu.length - productName.length - 1)])
            } else {
                symbol = productNu!
            }
            
            let trainType: String?
            let trainNum: String?
            if let match = symbol.match(pattern: P_MOBILE_M_SYMBOL) {
                trainType = match[0]
                trainNum = match[1]
            } else {
                trainType = nil
                trainNum = nil
            }
            
            let network = xml["m"]["dv"]["ne"].element?.text
            let parsedLine = parseLine(id: lineId, network: network, mot: productType, symbol: symbol, name: symbol, longName: nil, trainType: trainType, trainNum: trainNum, trainName: productName)
            line = Line(id: parsedLine.id, network: parsedLine.network, product: parsedLine.product, label: parsedLine.label, name: parsedLine.name, style: lineStyle(network: parsedLine.network, product: parsedLine.product, label: parsedLine.label), attr: nil, message: nil)
        }
        
        return LineDestination(line: line, destination: destination)
    }
    
    func parseMobileDiva(xml: XMLIndexer) throws -> String {
        if let stateless = xml["dv"]["stateless"].element?.text, stateless.contains(":") {
            return stateless
        }
        guard let lineIdLi = xml["dv"]["li"].element?.text, let lineIdSu = xml["dv"]["su"].element?.text, let lineIdPr = xml["dv"]["pr"].element?.text, let lineIdDct = xml["dv"]["dct"].element?.text, let lineIdNe = xml["dv"]["ne"].element?.text else { throw ParseError(reason: "could not parse line diva") }
        let branch = xml["dv"]["branch"].element?.text ?? ""
        return lineIdNe + ":" + branch + lineIdLi + ":" + lineIdSu + ":" + lineIdDct + ":" + lineIdPr
    }
    
    // MARK: Line styles
    
    func parseLine(id: String?, network: String?, mot: String?, symbol: String?, name: String?, longName: String?, trainType: String?, trainNum: String?, trainName: String?) -> Line {
        if mot == nil {
            if let trainName = trainName {
                let name = name == nil ? "" : name
                switch trainName {
                case "S-Bahn":
                    return Line(id: id, network: network, product: .suburbanTrain, label: name)
                case "U-Bahn":
                    return Line(id: id, network: network, product: .subway, label: name)
                case "Straßenbahn", "Badner Bahn":
                    return Line(id: id, network: network, product: .tram, label: name)
                case "Stadtbus", "Citybus", "Regionalbus", "ÖBB-Postbus", "Autobus", "Discobus", "Nachtbus", "Anrufsammeltaxi", "Ersatzverkehr", "Vienna Airport Lines":
                    return Line(id: id, network: network, product: .bus, label: name)
                default:
                    break
                }
            }
        } else {
            let mot = mot!
            if mot == "0" {
                let trainNum = trainNum ?? ""
                let trainName = trainName ?? ""
                let trainType = trainType  ?? ""
                let symbol = symbol ?? ""
                
                if ("EC" == trainType || "EuroCity" == trainName || "Eurocity" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "EC" + trainNum)
                } else if ("EN" == trainType || "EuroNight" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "EN" + trainNum)
                } else if ("IC" == trainType || "IC" == trainName || "InterCity" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "IC" + trainNum)
                } else if ("ICE" == trainType || "ICE" == trainName || "Intercity-Express" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "ICE" + trainNum)
                } else if ("ICN" == trainType || "InterCityNight" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "ICN" + trainNum)
                } else if ("X" == trainType || "InterConnex" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "X" + trainNum)
                } else if ("CNL" == trainType || "CityNightLine" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "CNL" + trainNum)
                } else if ("THA" == trainType || "Thalys" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "THA" + trainNum)
                } else if "RHI" == trainType && trainNum != "" {
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "RHI" + trainNum)
                } else if ("TGV" == trainType || "TGV" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "TGV" + trainNum)
                } else if "TGD" == trainType && trainNum != "" {
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "TGD" + trainNum)
                } else if "INZ" == trainType && trainNum != "" {
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "INZ" + trainNum)
                } else if ("RJ" == trainType || "railjet" == trainName) { // railjet
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "RJ" + trainNum)
                } else if ("RJX" == trainType || "railjet xpress" == trainName) { // railjet
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "RJX" + trainNum)
                } else if ("WB" == trainType || "WESTbahn" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "WB" + trainNum)
                } else if ("HKX" == trainType || "Hamburg-Köln-Express" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "HKX" + trainNum)
                } else if "INT" == trainType && trainNum != "" { // SVV, VAGFR
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "INT" + trainNum)
                } else if ("SC" == trainType || "SC Pendolino" == trainName) && trainNum != "" { // SuperCity
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "SC" + trainNum)
                } else if "ECB" == trainType && trainNum != "" { // EC, Verona-München
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "ECB" + trainNum)
                } else if "ES" == trainType && trainNum != "" { // Eurostar Italia
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "ES" + trainNum)
                } else if ("EST" == trainType || "EUROSTAR" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "EST" + trainNum)
                } else if "EIC" == trainType && trainNum != "" { // Ekspres InterCity, Polen
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "EIC" + trainNum)
                } else if "MT" == trainType && "Schnee-Express" == trainName && trainNum != "" {
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "MT" + trainNum)
                } else if ("TLK" == trainType || "Tanie Linie Kolejowe" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "TLK" + trainNum)
                } else if "DNZ" == trainType && trainNum != "" { // Nacht-Schnellzug
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "DNZ" + trainNum)
                } else if "AVE" == trainType && trainNum != "" { // klimatisierter Hochgeschwindigkeitszug
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "DNZ" + trainNum)
                } else if "ARC" == trainType && trainNum != "" { // Arco/Alvia/Avant (Renfe), Spanien
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "ARC" + trainNum)
                } else if "HOT" == trainType && trainNum != "" { // Spanien, Nacht
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "HOT" + trainNum)
                } else if "LCM" == trainType && "Locomore" == trainName && trainNum != "" {
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "LCM" + trainNum)
                } else if "Locomore" == longName {
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "LOC" + trainNum)
                    
                } else if "IR" == trainType || "Interregio" == trainName || "InterRegio" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "IR" + trainNum)
                } else if "IRE" == trainType || "Interregio-Express" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "IRE" + trainNum)
                } else if "InterRegioExpress" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "IRE" + trainNum)
                } else if "RE" == trainType || "Regional-Express" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "RE" + trainNum)
                } else if trainType == "" && trainNum != "" && (trainNum =~ "RE ?\\d+") {
                    return Line(id: id, network: network, product: .regionalTrain, label: trainNum)
                } else if "RE6a" == trainNum && trainType == "" && trainName == "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: trainNum)
                } else if "RE3 / RB30" == trainNum && trainType == "" && trainName == "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "RE3/RB30");
                } else if "Regionalexpress" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: symbol)
                } else if "R-Bahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: symbol)
                } else if "RB-Bahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: symbol)
                } else if trainType == "" && "RB67/71" == trainNum {
                    return Line(id: id, network: network, product: .regionalTrain, label: trainNum)
                } else if trainType == "" && "RB65/68" == trainNum {
                    return Line(id: id, network: network, product: .regionalTrain, label: trainNum)
                } else if "RE-Bahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: symbol)
                } else if "REX" == trainType { // RegionalExpress, Österreich
                    return Line(id: id, network: network, product: .regionalTrain, label: "REX" + trainNum)
                } else if ("RB" == trainType || "Regionalbahn" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "RB" + trainNum)
                } else if trainType == "" && trainNum != "" && (trainNum =~ "RB ?\\d+") {
                    return Line(id: id, network: network, product: .regionalTrain, label: trainNum)
                } else if "Abellio-Zug" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: symbol)
                } else if "Westfalenbahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: symbol)
                } else if "Chiemseebahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: symbol)
                } else if "R" == trainType || "Regionalzug" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "R" + trainNum)
                } else if trainType == "" && trainNum != "" && (trainNum =~ "R ?\\d+") {
                    return Line(id: id, network: network, product: .regionalTrain, label: trainNum)
                } else if "D" == trainType || "Schnellzug" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "D" + trainNum)
                } else if "E" == trainType || "Eilzug" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "E" + trainNum)
                } else if "WFB" == trainType || "WestfalenBahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "WFB" + trainNum)
                } else if ("NWB" == trainType || "NordWestBahn" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "NWB" + trainNum)
                } else if "WES" == trainType || "Westbahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "WES" + trainNum)
                } else if "ERB" == trainType || "eurobahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "ERB" + trainNum)
                } else if "CAN" == trainType || "cantus Verkehrsgesellschaft" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "CAN" + trainNum)
                } else if "HEX" == trainType || "Veolia Verkehr Sachsen-Anhalt" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "HEX" + trainNum)
                } else if "EB" == trainType || "Erfurter Bahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "EB" + trainNum)
                } else if "Erfurter Bahn" == longName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "EB")
                } else if "EBx" == trainType || "Erfurter Bahn Express" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "EBx" + trainNum)
                } else if "Erfurter Bahn Express" == longName && symbol == "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "EBx")
                } else if "MR" == trainType && "Märkische Regiobahn" == trainName && trainNum != "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "MR" + trainNum)
                } else if "MRB" == trainType || "Mitteldeutsche Regiobahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "MRB" + trainNum)
                } else if "ABR" == trainType || "ABELLIO Rail NRW GmbH" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "ABR" + trainNum)
                } else if "NEB" == trainType || "NEB Niederbarnimer Eisenbahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "NEB" + trainNum)
                } else if "OE" == trainType || "Ostdeutsche Eisenbahn GmbH" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "OE" + trainNum)
                } else if "Ostdeutsche Eisenbahn GmbH" == longName && symbol == "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "OE");
                } else if "ODE" == trainType && symbol != "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: symbol)
                } else if "OLA" == trainType || "Ostseeland Verkehr GmbH" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "OLA" + trainNum)
                } else if "UBB" == trainType || "Usedomer Bäderbahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "UBB" + trainNum)
                } else if "EVB" == trainType || "ELBE-WESER GmbH" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "EVB" + trainNum)
                } else if "RTB" == trainType || "Rurtalbahn GmbH" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "RTB" + trainNum)
                } else if "STB" == trainType || "Süd-Thüringen-Bahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "STB" + trainNum)
                } else if "HTB" == trainType || "Hellertalbahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "HTB" + trainNum)
                } else if "VBG" == trainType || "Vogtlandbahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "VBG" + trainNum)
                } else if "CB" == trainType || "City-Bahn Chemnitz" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "CB" + trainNum)
                } else if trainType == "" && ("C11" == trainNum || "C13" == trainNum || "C14" == trainNum
                    || "C15" == trainNum) {
                    return Line(id: id, network: network, product: .regionalTrain, label: trainNum)
                } else if "VEC" == trainType || "vectus Verkehrsgesellschaft" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "VEC" + trainNum)
                } else if "HzL" == trainType || "Hohenzollerische Landesbahn AG" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "HzL" + trainNum)
                } else if "SBB" == trainType || "SBB GmbH" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "SBB" + trainNum)
                } else if "MBB" == trainType || "Mecklenburgische Bäderbahn Molli" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "MBB" + trainNum)
                } else if "OS" == trainType {  // Osobní vlak
                    return Line(id: id, network: network, product: .regionalTrain, label: "OS" + trainNum)
                } else if "SP" == trainType || "Sp" == trainType { // Spěšný vlak
                    return Line(id: id, network: network, product: .regionalTrain, label: "SP" + trainNum)
                } else if "Dab" == trainType || "Daadetalbahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "Dab" + trainNum)
                } else if "FEG" == trainType || "Freiberger Eisenbahngesellschaft" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "FEG" + trainNum)
                } else if "ARR" == trainType || "ARRIVA" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "ARR" + trainNum)
                } else if "HSB" == trainType || "Harzer Schmalspurbahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "HSB" + trainNum)
                } else if "ALX" == trainType || "alex - Länderbahn und Vogtlandbahn GmbH" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "ALX" + trainNum)
                } else if "EX" == trainType || "Fatra" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "EX" + trainNum)
                } else if "ME" == trainType || "metronom" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "ME" + trainNum)
                } else if "metronom" == longName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "ME");
                } else if "MEr" == trainType {
                    return Line(id: id, network: network, product: .regionalTrain, label: "MEr" + trainNum)
                } else if "AKN" == trainType || "AKN Eisenbahn AG" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "AKN" + trainNum)
                } else if "SOE" == trainType || "Sächsisch-Oberlausitzer Eisenbahngesellschaft" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "SOE" + trainNum)
                } else if "VIA" == trainType || "VIAS GmbH" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "VIA" + trainNum)
                } else if "BRB" == trainType || "Bayerische Regiobahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "BRB" + trainNum)
                } else if "BLB" == trainType || "Berchtesgadener Land Bahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "BLB" + trainNum)
                } else if "HLB" == trainType || "Hessische Landesbahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "HLB" + trainNum)
                } else if "NOB" == trainType || "NordOstseeBahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "NOB" + trainNum)
                } else if "NBE" == trainType || "Nordbahn Eisenbahngesellschaft" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "NBE" + trainNum)
                } else if "VEN" == trainType || "Rhenus Veniro" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "VEN" + trainType);
                } else if "DPN" == trainType || "Nahreisezug" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "DPN" + trainNum)
                } else if "RBG" == trainType || "Regental Bahnbetriebs GmbH" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "RBG" + trainNum)
                } else if "BOB" == trainType || "Bodensee-Oberschwaben-Bahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "BOB" + trainNum)
                } else if "VE" == trainType || "Vetter" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "VE" + trainNum)
                } else if "SDG" == trainType || "SDG Sächsische Dampfeisenbahngesellschaft mbH" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "SDG" + trainNum)
                } else if "PRE" == trainType || "Pressnitztalbahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "PRE" + trainNum)
                } else if "VEB" == trainType || "Vulkan-Eifel-Bahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "VEB" + trainNum)
                } else if "neg" == trainType || "Norddeutsche Eisenbahn Gesellschaft" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "neg" + trainNum)
                } else if "AVG" == trainType || "Felsenland-Express" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "AVG" + trainNum)
                } else if "P" == trainType || "BayernBahn Betriebs-GmbH" == trainName
                    || "Brohltalbahn" == trainName || "Kasbachtalbahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "P" + trainNum)
                } else if "SBS" == trainType || "Städtebahn Sachsen" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "SBS" + trainNum)
                } else if "SES" == trainType || "Städteexpress Sachsen" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "SES" + trainNum)
                } else if "SB-" == trainType { // Städtebahn Sachsen
                    return Line(id: id, network: network, product: .regionalTrain, label: "SB" + trainNum)
                } else if "ag" == trainType { // agilis
                    return Line(id: id, network: network, product: .regionalTrain, label: "ag" + trainNum)
                } else if "agi" == trainType || "agilis" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "agi" + trainNum)
                } else if "as" == trainType || "agilis-Schnellzug" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "as" + trainNum)
                } else if "TLX" == trainType || "TRILEX" == trainName { // Trilex (Vogtlandbahn)
                    return Line(id: id, network: network, product: .regionalTrain, label: "TLX" + trainNum)
                } else if "MSB" == trainType || "Mainschleifenbahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "MSB" + trainNum)
                } else if "BE" == trainType || "Bentheimer Eisenbahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "BE" + trainNum)
                } else if "erx" == trainType || "erixx - Der Heidesprinter" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "erx" + trainNum)
                } else if ("ERX" == trainType || "Erixx" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "ERX" + trainNum)
                } else if ("SWE" == trainType || "Südwestdeutsche Verkehrs-AG" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "SWE" + trainNum)
                } else if "SWEG-Zug" == trainName { // Südwestdeutschen Verkehrs-Aktiengesellschaft
                    return Line(id: id, network: network, product: .regionalTrain, label: "SWEG" + trainNum)
                } else if let longName = longName, longName.hasPrefix("SWEG-Zug") {
                    return Line(id: id, network: network, product: .regionalTrain, label: "SWEG" + trainNum)
                } else if "EGP Eisenbahngesellschaft Potsdam" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "EGP" + trainNum)
                } else if "ÖBB" == trainType || "ÖBB" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "ÖBB" + trainNum)
                } else if "CAT" == trainType { // City Airport Train Wien
                    return Line(id: id, network: network, product: .regionalTrain, label: "CAT" + trainNum)
                } else if "DZ" == trainType || "Dampfzug" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "DZ" + trainNum)
                } else if "CD" == trainType { // Tschechien
                    return Line(id: id, network: network, product: .regionalTrain, label: "CD" + trainNum)
                } else if "VR" == trainType { // Polen
                    return Line(id: id, network: network, product: .regionalTrain, label: symbol)
                } else if "PR" == trainType { // Polen
                    return Line(id: id, network: network, product: .regionalTrain, label: symbol)
                } else if "KD" == trainType { // Koleje Dolnośląskie (Niederschlesische Eisenbahn)
                    return Line(id: id, network: network, product: .regionalTrain, label: symbol)
                } else if "Koleje Dolnoslaskie" == trainName && symbol != "" { // Koleje Dolnośląskie
                    return Line(id: id, network: network, product: .regionalTrain, label: symbol)
                } else if "OO" == trainType || "Ordinary passenger (o.pas.)" == trainName { // GB
                    return Line(id: id, network: network, product: .regionalTrain, label: "OO" + trainNum)
                } else if "XX" == trainType || "Express passenger    (ex.pas.)" == trainName { // GB
                    return Line(id: id, network: network, product: .regionalTrain, label: "XX" + trainNum)
                } else if "XZ" == trainType || "Express passenger sleeper" == trainName { // GB
                    return Line(id: id, network: network, product: .regionalTrain, label: "XZ" + trainNum)
                } else if "ATB" == trainType { // Autoschleuse Tauernbahn
                    return Line(id: id, network: network, product: .regionalTrain, label: "ATB" + trainNum)
                } else if "ATZ" == trainType { // Autozug
                    return Line(id: id, network: network, product: .regionalTrain, label: "ATZ" + trainNum)
                } else if "AZ" == trainType || "Auto-Zug" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "AZ" + trainNum)
                } else if "AZS" == trainType && trainNum != "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "AZS" + trainNum)
                } else if "DWE" == trainType || "Dessau-Wörlitzer Eisenbahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "DWE" + trainNum)
                } else if "KTB" == trainType || "Kandertalbahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "KTB" + trainNum)
                } else if "CBC" == trainType || "CBC" == trainName { // City-Bahn Chemnitz
                    return Line(id: id, network: network, product: .regionalTrain, label: "CBC" + trainNum)
                } else if "Bernina Express" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: trainNum)
                } else if "STR" == trainType { // Harzquerbahn, Nordhausen
                    return Line(id: id, network: network, product: .regionalTrain, label: "STR" + trainNum)
                } else if "EXT" == trainType || "Extrazug" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "EXT" + trainNum)
                } else if "Heritage Railway" == trainName { // GB
                    return Line(id: id, network: network, product: .regionalTrain, label: symbol)
                } else if "WTB" == trainType || "Wutachtalbahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "WTB" + trainNum)
                } else if "DB" == trainType || "DB Regio" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "DB" + trainNum)
                } else if "M" == trainType && "Meridian" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "M" + trainNum)
                } else if "M" == trainType && "Messezug" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "M" + trainNum)
                } else if "EZ" == trainType { // ÖBB Erlebniszug
                    return Line(id: id, network: network, product: .regionalTrain, label: "EZ" + trainNum)
                } else if "DPF" == trainType {
                    return Line(id: id, network: network, product: .regionalTrain, label: "DPF" + trainNum)
                } else if "WBA" == trainType || "Waldbahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "WBA" + trainNum)
                } else if "ÖB" == trainType && "Öchsle-Bahn-Betriebsgesellschaft mbH" == trainName && trainNum != "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "ÖB" + trainNum)
                } else if "ÖBA" == trainType && trainNum != "" { // Eisenbahn-Betriebsgesellschaft Ochsenhausen
                    return Line(id: id, network: network, product: .regionalTrain, label: "ÖBA" + trainNum)
                } else if ("UEF" == trainType || "Ulmer Eisenbahnfreunde" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "UEF" + trainNum)
                } else if ("DBG" == trainType || "Döllnitzbahn" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "DBG" + trainNum)
                } else if ("TL" == trainType || "Trilex" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "TL" + trainNum)
                } else if ("OPB" == trainType || "oberpfalzbahn" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "OPB" + trainNum)
                } else if ("OPX" == trainType || "oberpfalz-express" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "OPX" + trainNum)
                } else if ("LEO" == trainType || "Chiemgauer Lokalbahn" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "LEO" + trainNum)
                } else if ("VAE" == trainType || "Voralpen-Express" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "VAE" + trainNum)
                } else if ("V6" == trainType || "vlexx" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "vlexx" + trainNum)
                } else if ("ARZ" == trainType || "Autoreisezug" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "ARZ" + trainNum)
                } else if "RR" == trainType {
                    return Line(id: id, network: network, product: .regionalTrain, label: "RR" + trainNum)
                } else if ("TER" == trainType || "Train Express Regional" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "TER" + trainNum)
                } else if ("ENO" == trainType || "enno" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "ENO" + trainNum)
                } else if "enno" == longName && symbol == "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "enno");
                } else if ("PLB" == trainType || "Pinzgauer Lokalbahn" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "PLB" + trainNum)
                } else if ("NX" == trainType || "National Express" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "NX" + trainNum)
                } else if ("SE" == trainType || "ABELLIO Rail Mitteldeutschland GmbH" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "SE" + trainNum)
                } else if "DNA" == trainType, trainNum != "" { // Dieselnetz Augsburg
                    return Line(id: id, network: network, product: .regionalTrain, label: "DNA" + trainNum)
                } else if "Dieselnetz" == trainType && "Augsburg" == trainNum {
                    return Line(id: id, network: network, product: .regionalTrain, label: "DNA")
                    
                } else if ("BSB" == trainType || "Breisgau-S-Bahn Gmbh" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "BSB" + trainNum)
                } else if "BSB-Zug" == trainName && trainNum != "" { // Breisgau-S-Bahn
                    return Line(id: id, network: network, product: .suburbanTrain, label: trainNum)
                } else if "BSB-Zug" == trainName && trainNum == "" {
                    return Line(id: id, network: network, product: .suburbanTrain, label: "BSB")
                } else if let longName = longName, longName.hasPrefix("BSB-Zug") {
                    return Line(id: id, network: network, product: Product.suburbanTrain, label: "BSB")
                } else if "RSB" == trainType { // Regionalschnellbahn, Wien
                    return Line(id: id, network: network, product: Product.suburbanTrain, label: "RSB" + trainNum)
                } else if "RER" == trainName && symbol != "" && symbol.count == 1 { // Réseau Express Régional
                    return Line(id: id, network: network, product: .suburbanTrain, label: symbol)
                } else if "S" == trainType {
                    return Line(id: id, network: network, product: .suburbanTrain, label: "S" + trainNum)
                } else if "S-Bahn" == trainName {
                    return Line(id: id, network: network, product: .suburbanTrain, label: "S" + trainNum)
                    
                } else if "RT" == trainType || "RegioTram" == trainName {
                    return Line(id: id, network: network, product: .tram, label: "RT" + trainNum)
                    
                } else if "Bus" == trainType && trainNum != "" {
                    return Line(id: id, network: network, product: .bus, label: trainNum)
                } else if "Bus" == longName && symbol == "" {
                    return Line(id: id, network: network, product: .bus, label: longName)
                } else if "SEV" == trainType || "SEV" == trainNum || "SEV" == trainName || "SEV" == symbol
                    || "BSV" == trainType || "Ersatzverkehr" == trainName
                    || "Schienenersatzverkehr" == trainName {
                    return Line(id: id, network: network, product: .bus, label: "SEV" + trainNum);
                } else if "Bus replacement" == trainName { // GB
                    return Line(id: id, network: network, product: .bus, label: "BR");
                } else if "BR" == trainType && trainName != "" && trainName.hasPrefix("Bus") { // GB
                    return Line(id: id, network: network, product: .bus, label: "BR" + trainNum)
                } else if "EXB" == trainType && trainNum != "" {
                    return Line(id: id, network: network, product: .bus, label: "EXB" + trainNum)
                    
                } else if "GB" == trainType { // Gondelbahn
                    return Line(id: id, network: network, product: .cablecar, label: "GB" + trainNum)
                } else if "SB" == trainType { // Seilbahn
                    return Line(id: id, network: network, product: .suburbanTrain, label: "SB" + trainNum)
                    
                } else if "Zug" == trainName && symbol != "" {
                    return Line(id: id, network: network, product: nil, label: symbol)
                } else if "Zug" == longName && symbol == "" {
                    return Line(id: id, network: network, product: nil, label: "Zug")
                } else if "Zuglinie" == trainName && symbol != "" {
                    return Line(id: id, network: network, product: nil, label: symbol)
                } else if "ZUG" == trainType && trainNum != "" {
                    return Line(id: id, network: network, product: nil, label: trainNum)
                } else if symbol != "" && (symbol =~ "\\d+") && trainType == "" && trainName == "" {
                    return Line(id: id, network: network, product: nil, label: symbol)
                } else if "N" == trainType && trainName == "" && symbol == "" {
                    return Line(id: id, network: network, product: nil, label: "N" + trainNum)
                } else if "Train" == trainName {
                    return Line(id: id, network: network, product: nil, label: nil)
                } else if "PPN" == trainType && "Osobowy" == trainName, trainNum != "" {
                    return Line(id: id, network: network, product: nil, label: "PPN" + trainNum)
                }
                
                // generic
                if trainName != "" && trainType == "" && trainNum == "" {
                    return Line(id: id, network: network, product: nil, label: trainName + trainNum)
                }
            } else if mot == "1" {
                if let symbol = symbol, symbol =~ "S ?\\d+" {
                    return Line(id: id, network: network, product: .suburbanTrain, label: symbol)
                } else if let name = name, name =~ "S ?\\d+" {
                    return Line(id: id, network: network, product: .suburbanTrain, label: name)
                } else if trainName == "S-Bahn" {
                    return Line(id: id, network: network, product: .suburbanTrain, label: "S" + (trainNum ?? ""))
                    //                } else if let symbol = symbol, name == symbol, symbol =~ "(S\\d+) \\((?:DB Regio AG)\\)" {
                    //                    return Line(id: id, network: network, product: .SUBURBAN_TRAIN, label: "")
                } else if "REX" == trainType {
                    return Line(id: id, network: network, product: .regionalTrain, label: "REX\(trainNum ?? "")")
                }
                return Line(id: id, network: network, product: .regionalTrain, label: (symbol ?? "") + (name ?? ""))
            } else if mot == "2" {
                return Line(id: id, network: network, product: .subway, label: symbol ?? "" != "" ? symbol! : name)
            } else if mot == "3" || mot == "4" {
                return Line(id: id, network: network, product: .tram, label: symbol ?? "" != "" ? symbol! : name)
            } else if mot == "5" || mot == "6" || mot == "7" {
                if name == "Schienenersatzverkehr" {
                    return Line(id: id, network: network, product: .bus, label: "SEV")
                } else {
                    return Line(id: id, network: network, product: .bus, label: symbol ?? "" != "" ? symbol! : name)
                }
            } else if mot == "10" {
                return Line(id: id, network: network, product: .onDemand, label: symbol ?? "" != "" ? symbol! : name)
            } else if mot == "8" {
                return Line(id: id, network: network, product: .cablecar, label: name)
            } else if mot == "9" {
                return Line(id: id, network: network, product: .ferry, label: name)
            } else if mot == "11" {
                return Line(id: id, network: network, product: nil, label: symbol ?? "" != "" ? symbol! : name)
            } else if mot == "13" {
                return Line(id: id, network: network, product: .suburbanTrain, label: symbol)
            } else if mot == "17" {
                if trainNum == nil, let trainName = trainName,  trainName.hasPrefix("Schienenersatz") {
                    return Line(id: id, network: network, product: .bus, label: "SEV")
                }
            } else if mot == "19" {
                if trainName == "Bürgerbus" || trainName == "BürgerBus" {
                    return Line(id: id, network: network, product: .bus, label: symbol);
                }
            }
        }
        return Line(id: id, network: network, product: nil, label: name)
    }
    
    private func parseLine(xml: XMLIndexer) -> (line: Line, destination: Location?, cancelled: Bool)? {
        guard let motType = xml.element?.attribute(by: "motType")?.text else {
            print("WNR - queryDepartures: Failed to parse line type!")
            return nil
        }
        let symbol = xml.element?.attribute(by: "symbol")?.text
        let number = xml.element?.attribute(by: "number")?.text
        let stateless = xml.element?.attribute(by: "stateless")?.text
        var trainType = xml.element?.attribute(by: "trainType")?.text
        var trainName = xml.element?.attribute(by: "trainName")?.text
        let trainNum = xml.element?.attribute(by: "trainNum")?.text
        let network = xml["motDivaParams"].element?.attribute(by: "network")?.text
        let dir = xml["motDivaParams"].element?.attribute(by: "direction")?.text
        let direction: Line.Direction?
        if let dir = dir {
            switch dir {
            case "H": direction = .outward
            case "R": direction = .return
            default:  direction = nil
            }
        } else {
            direction = nil
        }
        
        var delay: String? = nil
        var message: String = ""
        if let train = xml["itdTrain"].element {
            if let name = train.attribute(by: "name")?.text {
                trainName = name
            }
            if let type = train.attribute(by: "type")?.text {
                trainType = type
            }
            delay = train.attribute(by: "delay")?.text
        }
        if let train = xml["itdNoTrain"].element {
            if let name = train.attribute(by: "name")?.text {
                trainName = name
            }
            if let type = train.attribute(by: "type")?.text {
                trainType = type
            }
            delay = train.attribute(by: "delay")?.text
            if let trainName = trainName, trainName.lowercased().contains("ruf") {
                message = train.text
            } else if train.text.lowercased().contains("ruf") {
                message = train.text
            }
        }
        
        let line = self.parseLine(id: stateless, network: network, mot: motType, symbol: symbol, name: number, longName: number, trainType: trainType, trainNum: trainNum, trainName: trainName)
        
        let destinationIdStr = xml.element?.attribute(by: "destID")?.text
        let destinationId = "-1" != destinationIdStr ? destinationIdStr : nil
        var destinationName = stripLineFromDestination(line: line, destinationName: xml.element?.attribute(by: "direction")?.text)
        if let destination = destinationName, destination.hasSuffix(" EILZUG") {
            destinationName = String(destination.dropLast(" EILZUG".count))
            if message.isEmpty {
                message = "Eilzug: Zug hält nicht überall."
            } else {
                message = "Eilzug: Zug hält nicht überall.\n" + message
            }
        }
        let nameAndPlace = split(directionName: destinationName)
        let destination: Location?
        if let id = destinationId, id != "" {
            destination = Location(type: .station, id: id, coord: nil, place: nameAndPlace.place, name: nameAndPlace.name)
        } else {
            if let name = nameAndPlace.name {
                destination = Location(type: .any, id: nil, coord: nil, place: nameAndPlace.place, name: name)
            } else {
                destination = nil
            }
        }
        
        let cancelled = delay == "-9999"
        
        return (Line(id: line.id, network: line.network, product: line.product, label: line.label, name: nil, number: number, trainNumber: trainNum, style: self.lineStyle(network: line.network, product: line.product, label: line.label), attr: nil, message: message.emptyToNil, direction: direction), destination, cancelled)
    }
    
    public class Context: QueryTripsContext {
        
        public override var canQueryEarlier: Bool { return true }
        public override var canQueryLater: Bool { return true }
        
        public let queryEarlierContext: (sessionId: String, requestId: String)
        public let queryLaterContext: (sessionId: String, requestId: String)
        
        init(queryEarlierContext: (sessionId: String, requestId: String), queryLaterContext: (sessionId: String, requestId: String), desktopUrl: URL?) {
            self.queryEarlierContext = queryEarlierContext
            self.queryLaterContext = queryLaterContext
            super.init()
            self.desktopUrl = desktopUrl
        }
        
        public required convenience init?(coder aDecoder: NSCoder) {
            guard
                let earlierSession = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.queryEarlierContextSession) as String?,
                let earlierRequest = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.queryEarlierContextRequest) as String?,
                let laterSession = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.queryLaterContextSession) as String?,
                let laterRequest = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.queryLaterContextRequest) as String?
                else {
                    return nil
            }
            let url = URL(string: aDecoder.decodeObject(of: NSString.self, forKey: QueryTripsContext.PropertyKey.desktopUrl) as String? ?? "")
            self.init(queryEarlierContext: (sessionId: earlierSession, requestId: earlierRequest), queryLaterContext: (sessionId: laterSession, requestId: laterRequest), desktopUrl: url)
        }
        
        public override func encode(with aCoder: NSCoder) {
            aCoder.encode(queryEarlierContext.sessionId, forKey: PropertyKey.queryEarlierContextSession)
            aCoder.encode(queryEarlierContext.requestId, forKey: PropertyKey.queryEarlierContextRequest)
            aCoder.encode(queryLaterContext.sessionId, forKey: PropertyKey.queryLaterContextSession)
            aCoder.encode(queryLaterContext.requestId, forKey: PropertyKey.queryLaterContextRequest)
            aCoder.encode(desktopUrl?.absoluteString, forKey: QueryTripsContext.PropertyKey.desktopUrl)
        }
        
        struct PropertyKey {
            static let queryEarlierContextSession = "earlierSession"
            static let queryEarlierContextRequest = "earlierRequest"
            static let queryLaterContextSession = "laterSession"
            static let queryLaterContextRequest = "laterRequest"
        }
        
    }
    
    fileprivate struct ServingLineState {
        let line: Line
        let destination: Location?
        let cancelled: Bool
    }
    
}

public class EfaJourneyContext: QueryJourneyDetailContext {
    
    public override class var supportsSecureCoding: Bool { return true }
    
    let stopId: String
    let stopDepartureTime: Date
    let line: Line
    let tripCode: String
    
    init(stopId: String, stopDepartureTime: Date, line: Line, tripCode: String) {
        self.stopId = stopId
        self.stopDepartureTime = stopDepartureTime
        self.line = line
        self.tripCode = tripCode
        super.init()
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let stopId = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.stopId) as String?, let stopDepartureTime = aDecoder.decodeObject(of: NSDate.self, forKey: PropertyKey.stopDepartureTime) as Date?, let line = aDecoder.decodeObject(of: Line.self, forKey: PropertyKey.line), let tripCode = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.tripCode) as String? else { return nil }
        
        self.init(stopId: stopId, stopDepartureTime: stopDepartureTime, line: line, tripCode: tripCode)
    }
    
    public override func encode(with aCoder: NSCoder) {
        aCoder.encode(stopId, forKey: PropertyKey.stopId)
        aCoder.encode(stopDepartureTime, forKey: PropertyKey.stopDepartureTime)
        aCoder.encode(line, forKey: PropertyKey.line)
        aCoder.encode(tripCode, forKey: PropertyKey.tripCode)
    }
    
    struct PropertyKey {
        
        static let stopId = "stopId"
        static let stopDepartureTime = "stopDepartureTime"
        static let line = "line"
        static let tripCode = "tripCode"
        
    }
    
}

public class EfaRefreshTripContext: RefreshTripContext {
    
    public override class var supportsSecureCoding: Bool { return true }
    
    let sessionId: String
    let requestId: String
    let routeIndex: String
    
    init(sessionId: String, requestId: String, routeIndex: String) {
        self.sessionId = sessionId
        self.requestId = requestId
        self.routeIndex = routeIndex
        super.init()
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let sessionId = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.sessionId) as String?, let requestId = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.requestId) as String?, let routeIndex = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.routeIndex) as String? else { return nil }
        self.init(sessionId: sessionId, requestId: requestId, routeIndex: routeIndex)
    }
    
    public override func encode(with aCoder: NSCoder) {
        aCoder.encode(sessionId, forKey: PropertyKey.sessionId)
        aCoder.encode(requestId, forKey: PropertyKey.requestId)
        aCoder.encode(routeIndex, forKey: PropertyKey.routeIndex)
    }
    
    public override var description: String {
        return "\(sessionId):\(requestId):\(routeIndex)"
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? EfaRefreshTripContext else { return false }
        if self === other { return true }
        return self.sessionId == other.sessionId && self.requestId == other.requestId && self.routeIndex == other.routeIndex
    }
    
    struct PropertyKey {
        
        static let sessionId = "sessionId"
        static let requestId = "requestId"
        static let routeIndex = "routeIndex"
        
    }
    
}
