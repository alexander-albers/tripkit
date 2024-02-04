import Foundation

public protocol NetworkProvider {
    
    /// Enum of this network provider.
    var id: NetworkId { get }
    /// Set of supported trip options.
    var supportedQueryTraits: Set<QueryTrait> { get }
    /// Objects which reduce the displayed tariff rate, like for example a loyalty cards.
    var tariffReductionTypes: [TariffReduction] { get }
    /// Set of supported language codes.
    var supportedLanguages: Set<String> { get }
    /// Language code that will be used if no other language has been specified. This value either corresponds``Locale.current.languageCode`` (i.e. to the device language) or to a language from ``supportedLanguages`` if the device language is not supported by the network provider.
    var defaultLanguage: String { get }
    /// Overrides the language code that should be queried in requests. If the language code is not supported, the ``defaultLanguage`` will be used instead.
    var queryLanguage: String? { get set }
    
    /// Map of line label to line style (used when parsing a line from a provider response).
    var styles: [String: LineStyle] { get }
    /// Time zone of this network provider.
    ///
    /// All `Date` objects need to be used with respect to this time zone of the network provider but must refer to the local time. This can be quite confusing, so here's an example:
    ///
    /// Say, you are currently in London and you want to find trips from London (GMT) to Paris (GMT+1). Let's further say that this timeZone object returns GMT+1 (i.e. the time zone of the network provider is Europe/Paris GMT+1). If you want to request trips departing at 15:00 o'clock GMT from London, the request `Date` object must be set to 15:00 *GMT+1*.
    ///
    /// This convention also applies to all response dates. Let's further say that you found a trip that arrives at 17:00 London time, or 18:00 local time in Paris. The `Date` object that will be returned will be 18:00 GMT+1 and *not* 17:00 GMT, even if you are currently still in London. The departure time (15:00 GMT) will also be in GMT+1 but in London local time, i.e. 15:00 *GMT+1*.
    var timeZone: TimeZone { get }
    
    /**
    Meant for auto-completion of location names.

    - Parameter constraint: input by user.
    - Parameter types: types of locations to find, or `nil` if provider default should be used.
    - Parameter maxLocations: maximum number of locations, or `0` for default value.
    - Parameter completion: location suggestions.

    - Returns: A reference to a cancellable http request.
     */
    @discardableResult func suggestLocations(constraint: String, types: [LocationType]?, maxLocations: Int, completion: @escaping (HttpRequest, SuggestLocationsResult) -> Void) -> AsyncRequest
    
    /**
    Find locations near to given location. At least one of lat/lon pair or station id must be present in that location.
 
    - Parameter types: types of locations to find, or nil if only stops should be found.
    - Parameter location: location to determine nearby stations.
    - Parameter maxDistance: maximum distance in meters, or `0` for default value.
    - Parameter maxLocations: maximum number of locations, or `0` for default value.
    - Parameter completion: nearby stations.

    - Returns: A reference to a cancellable http request.
     */
    @discardableResult func queryNearbyLocations(location: Location, types: [LocationType]?, maxDistance: Int, maxLocations: Int, completion: @escaping (HttpRequest, NearbyLocationsResult) -> Void) -> AsyncRequest
    
    /**
    Query trips, asking for any ambiguousnesses
 
    - Parameter from: location to route from.
    - Parameter via: location to route via, may be nil.
    - Parameter to: location to route to.
    - Parameter date: desired date for departing. See ``NetworkProvider/timeZone`` for a discussion about how to correctly handle time zones.
    - Parameter departure: date is departure date? true for departure, false for arrival.
    - Parameter products: products to take into account, or nil for the provider default.
    - Parameter optimize: optimize trip for one aspect, e.g. duration, or nil for the provider default.
    - Parameter walkSpeed: walking ability, or nil for the provider default.
    - Parameter accessibility: route accessibility, or nil for the provider default.
    - Parameter options: additional options, or nil for the provider default.
    - Parameter completion: result object that can contain alternatives to clear up ambiguousnesses, or contains possible trips.
 
    - Returns: A reference to a cancellable http request.
     */
    @available(*, deprecated)
    func queryTrips(from: Location, via: Location?, to: Location, date: Date, departure: Bool, products: [Product]?, optimize: Optimize?, walkSpeed: WalkSpeed?, accessibility: Accessibility?, options: [Option]?, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest
    
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
    @discardableResult func queryTrips(from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest
    
    /**
    Query more trips (e.g. earlier or later)

    - Parameter context: context to query more trips from.
    - Parameter later: true for get next trips, false for get previous trips.
    - Parameter completion: object that contains possible trips.
 
    - Returns: A reference to a cancellable http request.
     */
    @discardableResult func queryMoreTrips(context: QueryTripsContext, later: Bool, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest
    
    /**
    Reloads a trip to update delays etc.
 
    - Parameter context: context to reload the trip from.
    - Parameter completion: object that contains the single trip.
 
    - Returns: A reference to a cancellable http request.
     */
    @discardableResult func refreshTrip(context: RefreshTripContext, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest
    
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
    @discardableResult func queryDepartures(stationId: String, departures: Bool, time: Date?, maxDepartures: Int, equivs: Bool, completion: @escaping (HttpRequest, QueryDeparturesResult) -> Void) -> AsyncRequest
    
    /**
    Get details of a line journey.

     - Parameter context: context to get the journey detail from.
     - Parameter completion: object containing the journey detail.
 
     - Returns: A reference to a cancellable http request.
     */
    @discardableResult func queryJourneyDetail(context: QueryJourneyDetailContext, completion: @escaping (HttpRequest, QueryJourneyDetailResult) -> Void) -> AsyncRequest
    
    /**
    Get the wagon sequence of a train.
     - Parameter context: context to get the wagon sequence from.
     - Parameter completion: object containing the wagon sequence.
     
     - Returns: A reference to a cancellable http request.
     */
    @discardableResult func queryWagonSequence(context: QueryWagonSequenceContext, completion: @escaping (HttpRequest, QueryWagonSequenceResult) -> Void) -> AsyncRequest
    
}
