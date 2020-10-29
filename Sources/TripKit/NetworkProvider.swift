import Foundation

public protocol NetworkProvider {
    
    var id: NetworkId { get }
    var supportedQueryTraits: Set<QueryTrait> { get }
    
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
    @discardableResult func suggestLocations(constraint: String, types: [LocationType]?, maxLocations: Int, completion: @escaping (HttpRequest, SuggestLocationsResult) -> Void) -> AsyncRequest
    
    /**
    Find locations near to given location. At least one of lat/lon pair or station id must be present in that location.
 
    - Parameter types: types of locations to find, or nil if only stops should be found
    - Parameter location: location to determine nearby stations
    - Parameter maxDistance: maximum distance in meters, or 0
    - Parameter maxLocations: maximum number of locations, or 0
    - Parameter completion: nearby stations.

    - Returns: A reference to a cancellable http request.
     */
    @discardableResult func queryNearbyLocations(location: Location, types: [LocationType]?, maxDistance: Int, maxLocations: Int, completion: @escaping (HttpRequest, NearbyLocationsResult) -> Void) -> AsyncRequest
    
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
    @available(*, deprecated)
    func queryTrips(from: Location, via: Location?, to: Location, date: Date, departure: Bool, products: [Product]?, optimize: Optimize?, walkSpeed: WalkSpeed?, accessibility: Accessibility?, options: [Option]?, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest
    
    /**
       Query trips, asking for any ambiguousnesses
    
       - Parameter from: location to route from.
       - Parameter via: location to route via, may be nil.
       - Parameter to: location to route to.
       - Parameter date: desired date for departing.
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
 
    - Parameter stationId: id of the station. TODO: replace with location object
    - Parameter departures: true for departures, false for arrivals.
    - Parameter time: desired time for departing, or nil for the provider default.
    - Parameter maxDepartures: maximum number of departures to get or 0.
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

public class TripOptions: NSObject, NSSecureCoding {
    
    public static var supportsSecureCoding: Bool = true
    
    public var products: [Product]?
    public var optimize: Optimize?
    public var walkSpeed: WalkSpeed?
    public var accessibility: Accessibility?
    public var options: [Option]?
    public var maxChanges: Int?
    public var minChangeTime: Int? // in minutes
    
    public init(products: [Product]? = nil, optimize: Optimize? = nil, walkSpeed: WalkSpeed? = nil, accessibility: Accessibility? = nil, options: [Option]? = nil, maxChanges: Int? = nil, minChangeTime: Int? = nil) {
        self.products = products
        self.optimize = optimize
        self.accessibility = accessibility
        self.options = options
        self.maxChanges = maxChanges
        self.minChangeTime = minChangeTime
    }
    
    public required convenience init?(coder aDecoder: NSCoder) {
        let productsString = aDecoder.decodeObject(of: [NSArray.self, NSString.self], forKey: PropertyKey.products) as? [String]
        let products = productsString?.compactMap { Product(rawValue: $0) }
        let optimize = Optimize(rawValue: aDecoder.decodeObject(of: NSNumber.self, forKey: PropertyKey.optimize) as? Int ?? -1)
        let walkSpeed = WalkSpeed(rawValue: aDecoder.decodeObject(of: NSNumber.self, forKey: PropertyKey.walkSpeed) as? Int ?? -1)
        let accessibility = Accessibility(rawValue: aDecoder.decodeObject(of: NSNumber.self, forKey: PropertyKey.accessibility) as? Int ?? -1)
        let optionsInt = aDecoder.decodeObject(of: [NSArray.self], forKey: PropertyKey.options) as? [Int]
        let options = optionsInt?.compactMap { Option(rawValue: $0) }
        let maxChanges = aDecoder.decodeObject(of: NSNumber.self, forKey: PropertyKey.maxChanges) as? Int
        let minChangeTime = aDecoder.decodeObject(of: NSNumber.self, forKey: PropertyKey.minChangeTime) as? Int
        self.init(products: products, optimize: optimize, walkSpeed: walkSpeed, accessibility: accessibility, options: options, maxChanges: maxChanges, minChangeTime: minChangeTime)
    }
    
    public func encode(with aCoder: NSCoder) {
        if let products = products {
            aCoder.encode(products.map { $0.rawValue }, forKey: PropertyKey.products)
        }
        aCoder.encode(optimize?.rawValue, forKey: PropertyKey.optimize)
        aCoder.encode(walkSpeed?.rawValue, forKey: PropertyKey.walkSpeed)
        aCoder.encode(accessibility?.rawValue, forKey: PropertyKey.accessibility)
        aCoder.encode(options?.map { $0.rawValue }, forKey: PropertyKey.options)
        aCoder.encode(maxChanges, forKey: PropertyKey.maxChanges)
        aCoder.encode(minChangeTime, forKey: PropertyKey.minChangeTime)
    }
    
    struct PropertyKey {
        static let products = "products"
        static let optimize = "optimize"
        static let walkSpeed = "walkSpeed"
        static let accessibility = "accessibility"
        static let options = "options"
        static let maxChanges = "maxChanges"
        static let minChangeTime = "minChangeTime"
    }
}

public enum QueryTrait: Int {
    case maxChanges, minChangeTime
}
