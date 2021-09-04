import Foundation
import os.log

public class Trip: NSObject, NSSecureCoding {
    
    public static var supportsSecureCoding: Bool = true
    
    var id: String
    public let from: Location
    public let to: Location
    public let legs: [Leg]
    public let fares: [Fare]
    public var refreshContext: RefreshTripContext?
    
    public var isCancelled: Bool {
        for leg in legs {
            guard let leg = leg as? PublicLeg else { continue }
            if leg.departureStop.departureCancelled || leg.arrivalStop.arrivalCancelled {
                return true
            }
        }
        return false
    }
    
    public init(id: String, from: Location, to: Location, legs: [Leg], fares: [Fare], refreshContext: RefreshTripContext? = nil) {
        self.id = id
        self.from = from
        self.to = to
        self.legs = legs
        self.fares = fares
        self.refreshContext = refreshContext
    }
    
    required convenience public init?(coder aDecoder: NSCoder) {
        guard let id = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.id) as String?, let from = aDecoder.decodeObject(of: Location.self, forKey: PropertyKey.from), let to = aDecoder.decodeObject(of: Location.self, forKey: PropertyKey.to), let legs = aDecoder.decodeObject(of: [NSArray.self, PublicLeg.self, IndividualLeg.self], forKey: PropertyKey.legs) as? [Leg], let fares = aDecoder.decodeObject(of: [NSArray.self, Fare.self], forKey: PropertyKey.fares) as? [Fare] else {
            os_log("failed to decode trip", log: .default, type: .error)
            return nil
        }
        let refreshContext = aDecoder.decodeObject(of: RefreshTripContext.self, forKey: PropertyKey.refreshContext)
        self.init(id: id, from: from, to: to, legs: legs, fares: fares, refreshContext: refreshContext)
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(id, forKey: PropertyKey.id)
        aCoder.encode(from, forKey: PropertyKey.from)
        aCoder.encode(to, forKey: PropertyKey.to)
        aCoder.encode(legs, forKey: PropertyKey.legs)
        aCoder.encode(fares, forKey: PropertyKey.fares)
        if let refreshContext = refreshContext {
            aCoder.encode(refreshContext, forKey: PropertyKey.refreshContext)
        }
    }
    
    public func getId() -> String {
        if id != "" {
            return id
        } else {
            id = buildSubstituteId()
            return id
        }
    }
    
    private func buildSubstituteId() -> String {
        var result = ""
        for leg in legs {
            result += "\(leg.departure.getUniqueLongName())-"
            result += "\(leg.arrival.getUniqueLongName())-"
            
            if let _ = leg as? IndividualLeg {
                result += "Individual"
            } else if let leg = leg as? PublicLeg {
                if let plannedDeparture = leg.departureStop.plannedDepartureTime {
                    result += "\(plannedDeparture.timeIntervalSince1970)-"
                }
                if let plannedArrival = leg.arrivalStop.plannedArrivalTime {
                    result += "\(plannedArrival.timeIntervalSince1970)-"
                }
                result += "\(leg.line.product?.rawValue ?? "")-\(leg.line.label ?? "")"
            }
            result += "|"
        }
        return result
    }
    
    public func getDepartureTime() -> Date {
        return legs.first!.getDepartureTime()
    }
    
    public func getArrivalTime() -> Date {
        return legs.last!.getArrivalTime()
    }
    
    public func getPlannedDepartureTime() -> Date {
        return legs.first!.getPlannedDepartureTime()
    }
    
    public func getPlannedArrivalTime() -> Date {
        return legs.last!.getPlannedArrivalTime()
    }
    
    public func isDeparturingLate() -> Bool {
        if let leg = legs.first(where: {$0 is PublicLeg}) as? PublicLeg {
            if let plannedTime = leg.departureStop.plannedDepartureTime, let predictedTime = leg.departureStop.predictedDepartureTime, Int(predictedTime.timeIntervalSince(plannedTime) / 60) != 0 {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }
    
    public func isArrivingLate() -> Bool {
        if let leg = legs.reversed().first(where: {$0 is PublicLeg}) as? PublicLeg {
            if let plannedTime = leg.arrivalStop.plannedArrivalTime, let predictedTime = leg.arrivalStop.predictedArrivalTime, Int(predictedTime.timeIntervalSince(plannedTime) / 60) != 0 {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }
    
    public func isPredictedDepartureTime() -> Bool {
        if let leg = legs.first(where: {$0 is PublicLeg}) as? PublicLeg {
            return leg.departureStop.predictedDepartureTime != nil
        } else {
            return false
        }
    }
    
    public func isPredictedArrivalTime() -> Bool {
        if let leg = legs.reversed().first(where: {$0 is PublicLeg}) as? PublicLeg {
            return leg.arrivalStop.predictedArrivalTime != nil
        } else {
            return false
        }
    }
    
    public func getMinTime() -> Date {
        guard let firstLeg = legs.first else { return Date() }
        var minTime = firstLeg.getMinTime()
        for i in 1..<legs.count {
            if legs[i].getMinTime() < minTime {
                minTime = legs[i].getMinTime()
            }
        }
        return minTime
    }
    
    public func getMaxTime() -> Date {
        guard let firstLeg = legs.first else { return Date() }
        var maxTime = firstLeg.getMaxTime()
        for i in 1..<legs.count {
            if legs[i].getMaxTime() > maxTime {
                maxTime = legs[i].getMaxTime()
            }
        }
        return maxTime
    }
    
    public override var description: String {
        return "Trip id=\(getId()) legs=\(legs)"
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? Trip else { return false }
        return other.getId() == getId()
    }
    
    public override var hash: Int {
        return getId().hash
    }
    
    struct PropertyKey {
        
        static let id = "id"
        static let from = "from"
        static let to = "to"
        static let legs = "legs"
        static let fares = "fares"
        static let refreshContext = "refreshContext"
        
    }
    
    
}
