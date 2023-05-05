import Foundation

protocol QueryJourneyDetailManually {}

public class QueryJourneyDetailManuallyContext: QueryJourneyDetailContext {
    
    public override class var supportsSecureCoding: Bool { return true }
    
    let from: Location
    let to: Location
    let time: Date
    let plannedTime: Date
    let product: Product?
    let line: Line?
    
    init(from: Location, to: Location, time: Date, plannedTime: Date, product: Product?, line: Line?) {
        self.from = from
        self.to = to
        self.time = time
        self.plannedTime = plannedTime
        self.product = product
        self.line = line
        super.init()
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard
            let from = aDecoder.decodeObject(of: Location.self, forKey: PropertyKey.from),
            let to = aDecoder.decodeObject(of: Location.self, forKey: PropertyKey.to),
            let time = aDecoder.decodeObject(of: NSDate.self, forKey: PropertyKey.time) as Date?,
            let plannedTime = aDecoder.decodeObject(of: NSDate.self, forKey: PropertyKey.plannedTime) as Date?
        else {
            return nil
        }
        let product = Product(rawValue: aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.product) as String? ?? "")
        let line = aDecoder.decodeObject(of: Line.self, forKey: PropertyKey.line)
        
        self.init(from: from, to: to, time: time, plannedTime: plannedTime, product: product, line: line)
    }
    
    public override func encode(with aCoder: NSCoder) {
        aCoder.encode(from, forKey: PropertyKey.from)
        aCoder.encode(to, forKey: PropertyKey.to)
        aCoder.encode(time, forKey: PropertyKey.time)
        aCoder.encode(plannedTime, forKey: PropertyKey.plannedTime)
        if let product = product {
            aCoder.encode(product.rawValue, forKey: PropertyKey.product)
        }
        if let line = line {
            aCoder.encode(line, forKey: PropertyKey.line)
        }
    }
    
    struct PropertyKey {
        
        static let from = "from"
        static let to = "to"
        static let time = "time"
        static let plannedTime = "plannedTime"
        static let product = "product"
        static let line = "line"
        
    }
}

extension NetworkProvider where Self: QueryJourneyDetailManually {
    func queryJourneyDetailManually(context: QueryJourneyDetailContext, completion: @escaping (HttpRequest, QueryJourneyDetailResult) -> Void) -> AsyncRequest {
        guard let context = context as? QueryJourneyDetailManuallyContext else {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .invalidId)
            return AsyncRequest(task: nil)
        }
        let task = AsyncRequest(task: nil)
        task.task = queryTrips(from: context.from, via: nil, to: context.to, date: context.plannedTime, departure: true, tripOptions: TripOptions(products: context.product != nil ? [context.product!] : Product.allCases, optimize: nil, walkSpeed: nil, accessibility: nil, options: nil, maxChanges: nil, minChangeTime: nil, maxFootpathTime: nil, maxFootpathDist: nil, tariffProfile: nil), completion: { (request, result) in
            switch result {
            case .success(_, _, _, _, let trips, _):
                let trip = trips.first(where: { (trip) -> Bool in
                    guard trip.legs.filter({$0 is PublicLeg}).count == 1 else { return false }
                    guard let leg = trip.legs.filter({$0 is PublicLeg}).first as? PublicLeg else { return false }
                    guard leg.departureStop.plannedTime == context.plannedTime || leg.departureStop.predictedTime == context.time else { return false }
                    guard leg.line == context.line else { return false }
                    return true
                })
                let leg = trip?.legs.first(where: {$0 is PublicLeg})
                if let trip = trip, let leg = leg as? PublicLeg {
                    completion(request, .success(trip: trip, leg: leg))
                } else {
                    completion(request, .invalidId)
                }
            case .ambiguous(_, _, let ambiguousTo):
                if let destination = ambiguousTo.first {
                    task.task = self.queryTrips(from: context.from, via: nil, to: destination, date: context.plannedTime, departure: true, tripOptions: TripOptions(products: context.product != nil ? [context.product!] : Product.allCases, optimize: nil, walkSpeed: nil, accessibility: nil, options: nil, maxChanges: nil, minChangeTime: nil, maxFootpathTime: nil, maxFootpathDist: nil, tariffProfile: nil), completion: { (request2, result2) in
                        switch result2 {
                        case .success(_, _, _, _, let trips, _):
                            let trip = trips.first(where: { (trip) -> Bool in
                                guard trip.legs.filter({$0 is PublicLeg}).count == 1 else { return false }
                                guard let leg = trip.legs.filter({$0 is PublicLeg}).first as? PublicLeg else { return false }
                                guard leg.departureStop.plannedTime == context.plannedTime || leg.departureStop.predictedTime == context.time else { return false }
                                guard leg.line == context.line else { return false }
                                return true
                            })
                            let leg = trip?.legs.first(where: {$0 is PublicLeg})
                            if let trip = trip, let leg = leg as? PublicLeg {
                                completion(request2, .success(trip: trip, leg: leg))
                            } else {
                                completion(request2, .invalidId)
                            }
                        default:
                            completion(request2, .invalidId)
                        }
                    }).task
                } else {
                    completion(request, .invalidId)
                }
            case .failure(let err):
                completion(request, .failure(err))
            default:
                completion(request, .invalidId)
            }
        }).task
        return task
    }
}
