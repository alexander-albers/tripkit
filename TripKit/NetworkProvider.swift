import Foundation

public protocol NetworkProvider {
    
    var id: NetworkId { get }
    
    var styles: [String: LineStyle] { get set }
    var timeZone: TimeZone { get set }
    
    /**
    Meant for auto-completion of location names.

    - Parameter constraint: input by user
    - Parameter types: types of locations to find, or nil if provider default should be used
    - Parameter maxLocations: maximum number of locations, or 0
    - Parameter completion: location suggestions.

    - Returns: A reference to a cancellable http request.
     */
    func suggestLocations(constraint: String, types: [LocationType]?, maxLocations: Int, completion: @escaping (SuggestLocationsResult) -> Void) -> AsyncRequest
    
    /**
    Find locations near to given location. At least one of lat/lon pair or station id must be present in that location.
 
    - Parameter types: types of locations to find, or nil if only stops should be found
    - Parameter location: location to determine nearby stations
    - Parameter maxDistance: maximum distance in meters, or 0
    - Parameter maxLocations: maximum number of locations, or 0
    - Parameter completion: nearby stations.

    - Returns: A reference to a cancellable http request.
     */
    func queryNearbyLocations(location: Location, types: [LocationType]?, maxDistance: Int, maxLocations: Int, completion: @escaping (NearbyLocationsResult) -> Void) -> AsyncRequest
    
    /**
    Query trips, asking for any ambiguousnesses
 
    - Parameter from: location to route from.
    - Parameter via: location to route via, may be nil.
    - Parameter to: location to route to.
    - Parameter date: desired date for departing.
    - Parameter departure: date is departure date? true for departure, false for arrival.
    - Parameter products: products to take into account, or nil for the provider default.
    - Parameter optimize: optimize trip for one aspect, e.g. duration, or nil for the provider default.
    - Parameter walkSpeed: walking ability, or nil for the provider default.
    - Parameter accessibility: route accessibility, or nil for the provider default.
    - Parameter options: additional options, or nil for the provider default.
    - Parameter completion: result object that can contain alternatives to clear up ambiguousnesses, or contains possible trips.
 
    - Returns: A reference to a cancellable http request.
     */
    func queryTrips(from: Location, via: Location?, to: Location, date: Date, departure: Bool, products: [Product]?, optimize: Optimize?, walkSpeed: WalkSpeed?, accessibility: Accessibility?, options: [Option]?, completion: @escaping (QueryTripsResult) -> Void) -> AsyncRequest
    
    /**
    Query more trips (e.g. earlier or later)

    - Parameter context: context to query more trips from.
    - Parameter later: true for get next trips, false for get previous trips.
    - Parameter completion: object that contains possible trips.
 
    - Returns: A reference to a cancellable http request.
     */
    func queryMoreTrips(context: QueryTripsContext, later: Bool, completion: @escaping (QueryTripsResult) -> Void) -> AsyncRequest
    
    /**
    Reloads a trip to update delays etc.
 
    - Parameter context: context to reload the trip from.
    - Parameter completion: object that contains the single trip.
 
    - Returns: A reference to a cancellable http request.
     */
    func refreshTrip(context: RefreshTripContext, completion: @escaping (QueryTripsResult) -> Void) -> AsyncRequest
    
    /**
    Get departures at a given station.
 
    - Parameter stationId: id of the station. TODO: replace with location object
    - Parameter departures: true for departures, false for arrivals.
    - Parameter time: desired time for departing, or nil for the provider default.
    - Parameter maxDepartures: maximum number of departures to get or 0.
    - Parameter equivs: also query equivalent stations?
    - Parameter completion: object containing the departures.
 
    - Returns: A reference to a cancellable http request.
     */
    func queryDepartures(stationId: String, departures: Bool, time: Date?, maxDepartures: Int, equivs: Bool, completion: @escaping (QueryDeparturesResult) -> Void) -> AsyncRequest
    
    /**
    Get details of a line journey.

     - Parameter context: context to get the journey detail from.
     - Parameter completion: object containing the journey detail.
 
     - Returns: A reference to a cancellable http request.
     */
    func queryJourneyDetail(context: QueryJourneyDetailContext, completion: @escaping (QueryJourneyDetailResult) -> Void) -> AsyncRequest
    
}

public enum Optimize: Int {
    case leastDuration, leastChanges, leastWalking
}

public enum WalkSpeed: Int {
    case slow, normal, fast
}

public enum Accessibility: Int {
    case neutral, limited, barrierFree
}

public enum Option: Int {
    case bike
}
