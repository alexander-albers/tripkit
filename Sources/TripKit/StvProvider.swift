import Foundation

public class StvProvider: AbstractEfaProvider {
    
    static let API_BASE = "http://appefa10.verbundlinie.at/android/"
    
    public init() {
        super.init(networkId: .STV, apiBase: StvProvider.API_BASE)
        supportsDesktopTrips = false
        supportsDesktopDepartures = false

        includeRegionId = false
    }
    
    public override func queryNearbyLocations(location: Location, types: [LocationType]?, maxDistance: Int, maxLocations: Int, completion: @escaping (HttpRequest, NearbyLocationsResult) -> Void) -> AsyncRequest {
        if let coord = location.coord {
            return mobileCoordRequest(types: types, lat: coord.lat, lon: coord.lon, maxDistance: maxDistance, maxLocations: maxLocations, completion: completion)
        } else {
            return super.queryNearbyLocations(location: location, types: types, maxDistance: maxDistance, maxLocations: maxLocations, completion: completion)
        }
    }
    
    public override func queryDepartures(stationId: String, departures: Bool, time: Date?, maxDepartures: Int, equivs: Bool, completion: @escaping (HttpRequest, QueryDeparturesResult) -> Void) -> AsyncRequest {
        return queryDeparturesMobile(stationId: stationId, departures: departures, time: time, maxDepartures: maxDepartures, equivs: equivs, completion: completion)
    }
    
    override public func queryJourneyDetail(context: QueryJourneyDetailContext, completion: @escaping (HttpRequest, QueryJourneyDetailResult) -> Void) -> AsyncRequest {
        return queryJourneyDetailMobile(context: context, completion: completion)
    }
    
    public override func suggestLocations(constraint: String, types: [LocationType]?, maxLocations: Int, completion: @escaping (HttpRequest, SuggestLocationsResult) -> Void) -> AsyncRequest {
        return mobileStopfinderRequest(constraint: constraint, types: types, maxLocations: maxLocations, completion: completion)
    }
    
    public override func queryTrips(from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        return queryTripsMobile(from: from, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions, completion: completion)
    }
    
    public override func queryMoreTrips(context: QueryTripsContext, later: Bool, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        return queryMoreTripsMobile(context: context, later: later, completion: completion)
    }
    
    public override func refreshTrip(context: RefreshTripContext, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        return refreshTripMobile(context: context, completion: completion)
    }
    
}
