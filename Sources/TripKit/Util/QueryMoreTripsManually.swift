//

import Foundation

protocol QueryMoreTripsManually {
    func queryTrips(from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions, context: QueryTripsContext?, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest
}

public class QueryMoreTripsManuallyContext: QueryTripsContext {
    public override class var supportsSecureCoding: Bool { return true }
    
    public override var canQueryLater: Bool { return queryLater }
    public override var canQueryEarlier: Bool { return queryEarlier }
    
    var queryLater = true, queryEarlier = true
    
    public var lastDeparture: Date?
    public var firstArrival: Date?
    public var from: Location!
    public var via: Location?
    public var to: Location!
    public var tripOptions: TripOptions?
    
    public override init() {
        super.init()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        guard
            let from = aDecoder.decodeObject(of: Location.self, forKey: PropertyKey.from),
            let to = aDecoder.decodeObject(of: Location.self, forKey: PropertyKey.to)
            else {
                return nil
        }
        let lastDeparture = aDecoder.decodeObject(of: NSDate.self, forKey: PropertyKey.lastDeparture) as Date?
        let firstArrival = aDecoder.decodeObject(of: NSDate.self, forKey: PropertyKey.firstArrival) as Date?
        let via = aDecoder.decodeObject(of: Location.self, forKey: PropertyKey.via)
        let tripOptions = aDecoder.decodeObject(of: TripOptions.self, forKey: PropertyKey.tripOptions)
        let queryLater = aDecoder.decodeBool(forKey: PropertyKey.queryLater)
        let queryEarlier = aDecoder.decodeBool(forKey: PropertyKey.queryEarlier)
        super.init()
        self.lastDeparture = lastDeparture
        self.firstArrival = firstArrival
        self.from = from
        self.via = via
        self.to = to
        self.tripOptions = tripOptions
        self.queryLater = queryLater
        self.queryEarlier = queryEarlier
    }
    
    public override func encode(with aCoder: NSCoder) {
        aCoder.encode(lastDeparture, forKey: PropertyKey.lastDeparture)
        aCoder.encode(firstArrival, forKey: PropertyKey.firstArrival)
        aCoder.encode(from, forKey: PropertyKey.from)
        aCoder.encode(via, forKey: PropertyKey.via)
        aCoder.encode(to, forKey: PropertyKey.to)
        aCoder.encode(tripOptions, forKey: PropertyKey.tripOptions)
    }
    
    func departure(date: Date?) {
        guard let date = date else { return }
        if lastDeparture == nil || lastDeparture! < date {
            lastDeparture = date
        }
    }
    
    func arrival(date: Date?) {
        guard let date = date else { return }
        if firstArrival == nil || firstArrival! > date {
            firstArrival = date
        }
    }
    
    struct PropertyKey {
        static let lastDeparture = "lastDeparture"
        static let firstArrival = "firstArrival"
        static let from = "from"
        static let via = "via"
        static let to = "to"
        static let tripOptions = "tripOptions"
        static let queryLater = "queryLater"
        static let queryEarlier = "queryEarlier"
    }
}

extension NetworkProvider where Self: QueryMoreTripsManually {
    func queryMoreTripsManually(context: QueryTripsContext, later: Bool, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        guard let context = context as? QueryMoreTripsManuallyContext else {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .sessionExpired)
            return AsyncRequest(task: nil)
        }
        return queryTrips(from: context.from, via: context.via, to: context.to, date: (later ? context.lastDeparture : context.firstArrival) ?? Date(), departure: later, tripOptions: context.tripOptions ?? TripOptions(), context: context, completion: completion)
    }
}
