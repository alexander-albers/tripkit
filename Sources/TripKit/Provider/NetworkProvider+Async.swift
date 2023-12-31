import Foundation

@available(iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, *)
public extension NetworkProvider {
    /**
    Meant for auto-completion of location names.

    - Parameter constraint: input by user
    - Parameter types: types of locations to find. Use `nil` for provider default and `.any` for all location types
    - Parameter maxLocations: maximum number of locations, or `0` for default value
    - Parameter completion: location suggestions.

    - Returns: A reference to a cancellable http request.
     */
    func suggestLocations(constraint: String, types: [LocationType]? = nil, maxLocations: Int = 0) async -> (HttpRequest, SuggestLocationsResult) {
        return await withCheckedContinuation { continuation in
            suggestLocations(constraint: constraint, types: types, maxLocations: maxLocations) { request, result in
                continuation.resume(with: .success((request, result)))
            }
        }
    }
    
    /**
    Find locations near to given location. At least one of lat/lon pair or station id must be present in that location.
 
    - Parameter types: types of locations to find, or `nil` if only stops should be found.
    - Parameter location: location to determine nearby stations.
    - Parameter maxDistance: maximum distance in meters, or `0` for default value.
    - Parameter maxLocations: maximum number of locations, or `0` for default value.
    - Parameter completion: nearby stations.

    - Returns: A reference to a cancellable http request.
     */
    func queryNearbyLocations(location: Location, types: [LocationType]? = nil, maxDistance: Int = 0, maxLocations: Int = 0) async -> (HttpRequest, NearbyLocationsResult) {
        return await withCheckedContinuation { continuation in
            queryNearbyLocations(location: location, types: types, maxDistance: maxDistance, maxLocations: maxLocations) { request, result in
                continuation.resume(with: .success((request, result)))
            }
        }
    }
    
    /**
       Query trips, asking for any ambiguousnesses
    
       - Parameter from: location to route from.
       - Parameter via: location to route via, may be nil.
       - Parameter to: location to route to.
       - Parameter date: desired date for departing. See ``NetworkProvider/timeZone`` for a discussion about how to correctly handle time zones.
       - Parameter departure: date is departure date? true for departure, false for arrival.
       - Parameter tripOptions: additional options.
       - Parameter completion: result object that can contain alternatives to clear up ambiguousnesses, or contains possible trips.
    
       - Returns: A reference to a cancellable http request.
    */
    func queryTrips(from: Location, via: Location?, to: Location, date: Date = Date(), departure: Bool = true, tripOptions: TripOptions = TripOptions()) async -> (HttpRequest, QueryTripsResult) {
        return await withCheckedContinuation { continuation in
            queryTrips(from: from, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions) { request, result in
                continuation.resume(with: .success((request, result)))
            }
        }
    }
    
    /**
    Query more trips (e.g. earlier or later)

    - Parameter context: context to query more trips from.
    - Parameter later: true for get next trips, false for get previous trips.
    - Parameter completion: object that contains possible trips.
 
    - Returns: A reference to a cancellable http request.
     */
    func queryMoreTrips(context: QueryTripsContext, later: Bool) async -> (HttpRequest, QueryTripsResult) {
        return await withCheckedContinuation { continuation in
            queryMoreTrips(context: context, later: later) { request, result in
                continuation.resume(with: .success((request, result)))
            }
        }
    }
    
    /**
    Reloads a trip to update delays etc.
 
    - Parameter context: context to reload the trip from.
    - Parameter completion: object that contains the single trip.
 
    - Returns: A reference to a cancellable http request.
     */
    func refreshTrip(context: RefreshTripContext) async -> (HttpRequest, QueryTripsResult) {
        return await withCheckedContinuation { continuation in
            refreshTrip(context: context) { request, result in
                continuation.resume(with: .success((request, result)))
            }
        }
    }
    
    /**
    Get departures at a given station.
 
    - Parameter stationId: id of the station.
    - Parameter departures: true for departures, false for arrivals.
    - Parameter time: desired time for departing, or `nil` for the provider default. See ``NetworkProvider/timeZone`` for a discussion about how to correctly handle time zones.
    - Parameter maxDepartures: maximum number of departures to get or `0`.
    - Parameter equivs: also query equivalent stations?
    - Parameter completion: object containing the departures.
 
    - Returns: A reference to a cancellable http request.
     */
    func queryDepartures(stationId: String, departures: Bool = true, time: Date? = nil, maxDepartures: Int = 0, equivs: Bool = false) async -> (HttpRequest, QueryDeparturesResult) {
        return await withCheckedContinuation { continuation in
            queryDepartures(stationId: stationId, departures: departures, time: time, maxDepartures: maxDepartures, equivs: equivs) { request, result in
                continuation.resume(with: .success((request, result)))
            }
        }
    }
    
    /**
    Get details of a line journey.

     - Parameter context: context to get the journey detail from.
     - Parameter completion: object containing the journey detail.
 
     - Returns: A reference to a cancellable http request.
     */
    func queryJourneyDetail(context: QueryJourneyDetailContext) async -> (HttpRequest, QueryJourneyDetailResult) {
        return await withCheckedContinuation { continuation in
            queryJourneyDetail(context: context) { request, result in
                continuation.resume(with: .success((request, result)))
            }
        }
    }
    
    /**
    Get the wagon sequence of a train. Currently only implemented in DbProvider.
     - Parameter line: the line from which to get the the wagon sequence.
     - Parameter stationId: location id of the station where the train departs.
     - Parameter departureTime: planned departure time of the train from the supplied station.
     - Parameter completion: object containing the wagon sequence.
     
     - Returns: A reference to a cancellable http request.
     */
    @discardableResult func queryWagonSequence(line: Line, stationId: String, departureTime: Date) async -> (HttpRequest, QueryWagonSequenceResult) {
        return await withCheckedContinuation { continuation in
            queryWagonSequence(line: line, stationId: stationId, departureTime: departureTime) { request, result in
                continuation.resume(with: .success((request, result)))
            }
        }
    }
}
