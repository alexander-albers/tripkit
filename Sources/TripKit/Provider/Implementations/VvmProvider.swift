import Foundation

public class VvmProvider: AbstractEfaProvider {
    
    static let API_BASE = "https://mobile.defas-fgi.de/vvmapp/"
    static let DEPARTURE_MONITOR_ENDPOINT = "XML_DM_REQUEST"
    static let TRIP_ENDPOINT = "XML_TRIP_REQUEST2"
    static let STOP_FINDER_ENDPOINT = "XML_STOPFINDER_REQUEST"
    
    public init() {
        super.init(networkId: .VVM, apiBase: VvmProvider.API_BASE, departureMonitorEndpoint: VvmProvider.DEPARTURE_MONITOR_ENDPOINT, tripEndpoint: VvmProvider.TRIP_ENDPOINT, stopFinderEndpoint: VvmProvider.STOP_FINDER_ENDPOINT, coordEndpoint: nil, tripStopTimesEndpoint: nil)
    }
    
    override public func queryNearbyLocations(location: Location, types: [LocationType]?, maxDistance: Int, maxLocations: Int, completion: @escaping (HttpRequest, NearbyLocationsResult) -> Void) -> AsyncRequest {
        if let coord = location.coord {
            return mobileCoordRequest(types: types, lat: coord.lat, lon: coord.lon, maxDistance: maxDistance, maxLocations: maxLocations, completion: completion)
        } else {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .invalidId)
            return AsyncRequest(task: nil)
        }
    }
    
    override func queryNearbyLocationsByCoordinateParsing(request: HttpRequest, location: Location, types: [LocationType]?, maxDistance: Int, maxLocations: Int, completion: @escaping (HttpRequest, NearbyLocationsResult) -> Void) throws {
        try queryNearbyLocationsByCoordinateParsingMobile(request: request, completion: completion)
    }
    
    override public func queryDepartures(stationId: String, departures: Bool, time: Date?, maxDepartures: Int, equivs: Bool, completion: @escaping (HttpRequest, QueryDeparturesResult) -> Void) -> AsyncRequest {
        return queryDeparturesMobile(stationId: stationId, departures: departures, time: time, maxDepartures: maxDepartures, equivs: equivs, completion: completion)
    }
    
    override func queryDeparturesParsing(request: HttpRequest, stationId: String, departures: Bool, time: Date?, maxDepartures: Int, equivs: Bool, completion: @escaping (HttpRequest, QueryDeparturesResult) -> Void) throws {
        try queryDeparturesParsingMobile(request: request, stationId: stationId, departures: departures, time: time, maxDepartures: maxDepartures, equivs: equivs, completion: completion)
    }
    
    override public func queryJourneyDetail(context: QueryJourneyDetailContext, completion: @escaping (HttpRequest, QueryJourneyDetailResult) -> Void) -> AsyncRequest {
        return queryJourneyDetailMobile(context: context, completion: completion)
    }
    
    override func queryJourneyDetailParsing(request: HttpRequest, context: QueryJourneyDetailContext, completion: @escaping (HttpRequest, QueryJourneyDetailResult) -> Void) throws {
        try queryJourneyDetailParsingMobile(request: request, context: context, completion: completion)
    }
    
    override public func suggestLocations(constraint: String, types: [LocationType]?, maxLocations: Int, completion: @escaping (HttpRequest, SuggestLocationsResult) -> Void) -> AsyncRequest {
        return mobileStopfinderRequest(constraint: constraint, types: types, maxLocations: maxLocations, completion: completion)
    }
    
    override func suggestLocationsParsing(request: HttpRequest, constraint: String, types: [LocationType]?, maxLocations: Int, completion: @escaping (HttpRequest, SuggestLocationsResult) -> Void) throws {
        try suggestLocationsParsingMobile(request: request, completion: completion)
    }
    
    public override func queryTrips(from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        return queryTripsMobile(from: from, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions, completion: completion)
    }
    
    override func queryTripsParsing(request: HttpRequest, from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions, previousContext: QueryTripsContext?, later: Bool, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) throws {
        try queryTripsParsingMobile(request: request, from: from, via: via, to: to, previousContext: previousContext, later: later, completion: completion)
    }
    
    override public func queryMoreTrips(context: QueryTripsContext, later: Bool, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        return queryMoreTripsMobile(context: context, later: later, completion: completion)
    }
    
    public override func refreshTrip(context: RefreshTripContext, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        return refreshTripMobile(context: context, completion: completion)
    }
    
    override func refreshTripParsing(request: HttpRequest, context: RefreshTripContext, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) throws {
        try refreshTripParsingMobile(request: request, context: context, completion: completion)
    }
    
}
