import Foundation
import os.log

public class Stop: NSObject, NSSecureCoding {
    
    public static var supportsSecureCoding: Bool = true
    
    public let location: Location
    // TODO: separate arrival and departure
    public let plannedArrivalTime: Date? // TODO: planned time should be never nil
    public let predictedArrivalTime: Date?
    public let plannedArrivalPlatform: String?
    public let predictedArrivalPlatform: String?
    public var arrivalCancelled: Bool
    public let plannedDepartureTime: Date? // TODO: planned time should be never nil
    public let predictedDepartureTime: Date?
    public let plannedDeparturePlatform: String?
    public let predictedDeparturePlatform: String?
    public var departureCancelled: Bool
    public let message: String?
    public let wagonSequenceContext: URL?
    
    public init(location: Location, plannedArrivalTime: Date?, predictedArrivalTime: Date?, plannedArrivalPlatform: String?, predictedArrivalPlatform: String?, arrivalCancelled: Bool, plannedDepartureTime: Date?, predictedDepartureTime: Date?, plannedDeparturePlatform: String?, predictedDeparturePlatform: String?, departureCancelled: Bool, message: String? = nil, wagonSequenceContext: URL? = nil) {
        self.location = location
        self.plannedArrivalTime = plannedArrivalTime
        self.predictedArrivalTime = predictedArrivalTime
        self.plannedArrivalPlatform = plannedArrivalPlatform
        self.predictedArrivalPlatform = predictedArrivalPlatform
        self.arrivalCancelled = arrivalCancelled
        self.plannedDepartureTime = plannedDepartureTime
        self.predictedDepartureTime = predictedDepartureTime
        self.plannedDeparturePlatform = plannedDeparturePlatform
        self.predictedDeparturePlatform = predictedDeparturePlatform
        self.departureCancelled = departureCancelled
        self.message = message
        self.wagonSequenceContext = wagonSequenceContext
    }
    
    required convenience public init?(coder aDecoder: NSCoder) {
        guard let location = aDecoder.decodeObject(of: Location.self, forKey: PropertyKey.location) else {
            os_log("failed to decode stop", log: .default, type: .error)
            return nil
        }
        let plannedArrivalTime = aDecoder.decodeObject(of: NSDate.self, forKey: PropertyKey.plannedArrivalTime) as Date?
        let predictedArrivalTime = aDecoder.decodeObject(of: NSDate.self, forKey: PropertyKey.predictedArrivalTime) as Date?
        let plannedArrivalPlatform = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.plannedArrivalPlatform) as String?
        let predictedArrivalPlatform = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.predictedArrivalPlatform) as String?
        let arrivalCancelled = aDecoder.decodeBool(forKey: PropertyKey.arrivalCancelled)
        let plannedDepartureTime = aDecoder.decodeObject(of: NSDate.self, forKey: PropertyKey.plannedDepartureTime) as Date?
        let predictedDepartureTime = aDecoder.decodeObject(of: NSDate.self, forKey: PropertyKey.predictedDepartureTime) as Date?
        let plannedDeparturePlatform = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.plannedDeparturePlatform) as String?
        let predictedDeparturePlatform = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.predictedDeparturePlatform) as String?
        let departureCancelled = aDecoder.decodeBool(forKey: PropertyKey.departureCancelled)
        let message = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.message) as String?
        let wagonSequenceContextPath = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.wagonSequenceContext) as String?
        let wagonSequenceContext = wagonSequenceContextPath != nil ? URL(string: wagonSequenceContextPath!) : nil
        
        self.init(location: location, plannedArrivalTime: plannedArrivalTime, predictedArrivalTime: predictedArrivalTime, plannedArrivalPlatform: plannedArrivalPlatform, predictedArrivalPlatform: predictedArrivalPlatform, arrivalCancelled: arrivalCancelled, plannedDepartureTime: plannedDepartureTime, predictedDepartureTime: predictedDepartureTime, plannedDeparturePlatform: plannedDeparturePlatform, predictedDeparturePlatform: predictedDeparturePlatform, departureCancelled: departureCancelled, message: message, wagonSequenceContext: wagonSequenceContext)
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(location, forKey: PropertyKey.location)
        if let plannedArrivalTime = plannedArrivalTime {
            aCoder.encode(plannedArrivalTime, forKey: PropertyKey.plannedArrivalTime)
        }
        if let predictedArrivalTime = predictedArrivalTime {
            aCoder.encode(predictedArrivalTime, forKey: PropertyKey.predictedArrivalTime)
        }
        if let plannedArrivalPlatform = plannedArrivalPlatform {
            aCoder.encode(plannedArrivalPlatform, forKey: PropertyKey.plannedArrivalPlatform)
        }
        if let predictedArrivalPlatform = predictedArrivalPlatform {
            aCoder.encode(predictedArrivalPlatform, forKey: PropertyKey.predictedArrivalPlatform)
        }
        aCoder.encode(arrivalCancelled, forKey: PropertyKey.arrivalCancelled)
        if let plannedDepartureTime = plannedDepartureTime {
            aCoder.encode(plannedDepartureTime, forKey: PropertyKey.plannedDepartureTime)
        }
        if let predictedDepartureTime = predictedDepartureTime {
            aCoder.encode(predictedDepartureTime, forKey: PropertyKey.predictedDepartureTime)
        }
        if let plannedDeparturePlatform = plannedDeparturePlatform {
            aCoder.encode(plannedDeparturePlatform, forKey: PropertyKey.plannedDeparturePlatform)
        }
        if let predictedDeparturePlatform = predictedDeparturePlatform {
            aCoder.encode(predictedDeparturePlatform, forKey: PropertyKey.predictedDeparturePlatform)
        }
        aCoder.encode(departureCancelled, forKey: PropertyKey.departureCancelled)
        if let message = message {
            aCoder.encode(message, forKey: PropertyKey.message)
        }
        if let wagonSequenceContext = wagonSequenceContext {
            aCoder.encode(wagonSequenceContext.absoluteString, forKey: PropertyKey.wagonSequenceContext)
        }
    }
    
    public func getMinTime() -> Date {
        if plannedDepartureTime == nil || (predictedDepartureTime != nil && predictedDepartureTime! < plannedDepartureTime!) {
            return predictedDepartureTime!
        } else {
            return plannedDepartureTime!
        }
    }
    
    public func getMaxTime() -> Date {
        if plannedArrivalTime == nil || (predictedArrivalTime != nil && predictedArrivalTime! > plannedArrivalTime!) {
            return predictedArrivalTime!
        } else {
            return plannedArrivalTime!
        }
    }
    
    open override func isEqual(_ other: Any?) -> Bool {
        guard let other = other as? Stop else { return false }
        if self === other { return true }
        if self.location != other.location {
            return false
        }
        if !(self.plannedArrivalTime == other.plannedArrivalTime && self.predictedArrivalTime == other.predictedArrivalTime && self.plannedArrivalPlatform == other.plannedArrivalPlatform && self.predictedArrivalPlatform == other.predictedArrivalPlatform && self.arrivalCancelled == other.arrivalCancelled) {
            return false
        }
        if !(self.plannedDepartureTime == other.plannedDepartureTime && self.predictedDepartureTime == other.predictedDepartureTime && self.plannedDeparturePlatform == other.plannedDeparturePlatform && self.predictedDeparturePlatform == other.predictedDeparturePlatform && self.departureCancelled == other.departureCancelled) {
            return false
        }
        return true
    }
    
    struct PropertyKey {
        
        static let location = "location"
        static let plannedArrivalTime = "plannedArrivalTime"
        static let predictedArrivalTime = "predictedArrivalTime"
        static let plannedArrivalPlatform = "plannedArrivalPlatform"
        static let predictedArrivalPlatform = "predictedArrivalPlatform"
        static let arrivalCancelled = "arrivalCancelled"
        static let plannedDepartureTime = "plannedDepartureTime"
        static let predictedDepartureTime = "predictedDepartureTime"
        static let plannedDeparturePlatform = "plannedDeparturePlatform"
        static let predictedDeparturePlatform = "predictedDeparturePlatform"
        static let departureCancelled = "departureCancelled"
        static let message = "message"
        static let wagonSequenceContext = "wagonSequenceContext"
        
    }
    
}
