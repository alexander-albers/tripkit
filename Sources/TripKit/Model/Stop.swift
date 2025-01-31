import Foundation
import os.log

public class Stop: NSObject, NSSecureCoding {
    
    public static var supportsSecureCoding: Bool = true
    
    /// Information about the station of the stop.
    public let location: Location
    
    /// Information about the arrival of this stop. Contains time, platform and a bool indicating if the stop has been cancelled.
    ///
    /// This value may be nil if *usually* the stop is taken but for this specific trip the stop is *planned to be skipped*, i.e. no arrival time has been scheduled in the first place.
    /// If the stop has already been scheduled, but due to delays or other factors the stop is skipped, this value is *not nil*. Instead, the value contains the planned arrival time and the `cancelled`-flag is set to `true`.
    ///
    /// If arrival is non-nil than departure should also be non-nil and vice-versa.
    public var arrival: StopEvent?
    /// Information about the departure of this stop. Contains time, platform and a bool indicating if the stop has been cancelled.
    ///
    /// This value may be nil if *usually* the stop is taken but for this specific trip the stop is *planned to be skipped*, i.e. no departure time has been scheduled in the first place.
    /// If the stop has already been scheduled, but due to delays or other factors the stop is skipped, this value is *not nil*. Instead, the value contains the planned departure time and the `cancelled`-flag is set to `true`.
    ///
    /// If arrival is non-nil than departure should also be non-nil and vice-versa.
    public var departure: StopEvent?
    
    /// Message specific to this stop.
    public let message: String?
    
    /// Returns the earliest time of the stop, either departure or arrival.
    public var minTime: Date? {
        if let departure = departure, let arrival = arrival {
            return min(departure.minTime, arrival.minTime)
        } else if let departure = departure {
            return departure.minTime
        } else if let arrival = arrival {
            return arrival.minTime
        } else {
            return nil
        }
    }
    
    /// Returns the latest time of the stop, either departure or arrival.
    public var maxTime: Date? {
        if let departure = departure, let arrival = arrival {
            return max(departure.maxTime, arrival.maxTime)
        } else if let departure = departure {
            return departure.maxTime
        } else if let arrival = arrival {
            return arrival.maxTime
        } else {
            return nil
        }
    }
    
    public init(location: Location, departure: StopEvent?, arrival: StopEvent?, message: String?) {
        departure?.message = message
        arrival?.message = message
        
        self.location = location
        self.departure = departure
        self.arrival = arrival
        self.message = message
    }
    
    required convenience public init?(coder aDecoder: NSCoder) {
        guard let location = aDecoder.decodeObject(of: Location.self, forKey: PropertyKey.location) else {
            os_log("failed to decode stop location", log: .default, type: .error)
            return nil
        }
        
        let message = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.message) as String?
        
        let departure: StopEvent?
        if let plannedDepartureTime = aDecoder.decodeObject(of: NSDate.self, forKey: PropertyKey.plannedDepartureTime) as Date? {
            departure = StopEvent(
                location: location,
                plannedTime: plannedDepartureTime,
                predictedTime: aDecoder.decodeObject(of: NSDate.self, forKey: PropertyKey.predictedDepartureTime) as Date?,
                plannedPlatform: aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.plannedDeparturePlatform) as String?,
                predictedPlatform: aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.predictedDeparturePlatform) as String?,
                cancelled: aDecoder.decodeBool(forKey: PropertyKey.departureCancelled),
                undefinedDelay: aDecoder.decodeBool(forKey: PropertyKey.departureUndefinedDelay)
            )
        } else {
            departure = nil
        }
        
        let arrival: StopEvent?
        if let plannedArrivalTime = aDecoder.decodeObject(of: NSDate.self, forKey: PropertyKey.plannedArrivalTime) as Date? {
            arrival = StopEvent(
                location: location,
                plannedTime: plannedArrivalTime,
                predictedTime: aDecoder.decodeObject(of: NSDate.self, forKey: PropertyKey.predictedArrivalTime) as Date?,
                plannedPlatform: aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.plannedArrivalPlatform) as String?,
                predictedPlatform: aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.predictedArrivalPlatform) as String?,
                cancelled: aDecoder.decodeBool(forKey: PropertyKey.arrivalCancelled),
                undefinedDelay: aDecoder.decodeBool(forKey: PropertyKey.arrivalUndefinedDelay)
            )
        } else {
            arrival = nil
        }
        
        self.init(location: location, departure: departure, arrival: arrival, message: message)
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(location, forKey: PropertyKey.location)
        
        if let departure = departure {
            aCoder.encode(departure.plannedTime, forKey: PropertyKey.plannedDepartureTime)
            aCoder.encode(departure.predictedTime, forKey: PropertyKey.predictedDepartureTime)
            aCoder.encode(departure.plannedPlatform, forKey: PropertyKey.plannedDeparturePlatform)
            aCoder.encode(departure.predictedPlatform, forKey: PropertyKey.predictedDeparturePlatform)
            aCoder.encode(departure.cancelled, forKey: PropertyKey.departureCancelled)
            aCoder.encode(departure.undefinedDelay, forKey: PropertyKey.departureUndefinedDelay)
        }
        
        if let arrival = arrival {
            aCoder.encode(arrival.plannedTime, forKey: PropertyKey.plannedArrivalTime)
            aCoder.encode(arrival.predictedTime, forKey: PropertyKey.predictedArrivalTime)
            aCoder.encode(arrival.plannedPlatform, forKey: PropertyKey.plannedArrivalPlatform)
            aCoder.encode(arrival.predictedPlatform, forKey: PropertyKey.predictedArrivalPlatform)
            aCoder.encode(arrival.cancelled, forKey: PropertyKey.arrivalCancelled)
            aCoder.encode(arrival.undefinedDelay, forKey: PropertyKey.arrivalUndefinedDelay)
        }
        
        aCoder.encode(message, forKey: PropertyKey.message)
    }
    
    open override func isEqual(_ other: Any?) -> Bool {
        guard let other = other as? Stop else { return false }
        if self === other { return true }
        if self.location != other.location {
            return false
        }
        return self.departure == other.departure && self.arrival == other.arrival
    }
    
    struct PropertyKey {
        
        static let location = "location"
        static let plannedArrivalTime = "plannedArrivalTime"
        static let predictedArrivalTime = "predictedArrivalTime"
        static let plannedArrivalPlatform = "plannedArrivalPlatform"
        static let predictedArrivalPlatform = "predictedArrivalPlatform"
        static let arrivalCancelled = "arrivalCancelled"
        static let arrivalUndefinedDelay = "arrivalUndefinedDelay"
        static let plannedDepartureTime = "plannedDepartureTime"
        static let predictedDepartureTime = "predictedDepartureTime"
        static let plannedDeparturePlatform = "plannedDeparturePlatform"
        static let predictedDeparturePlatform = "predictedDeparturePlatform"
        static let departureCancelled = "departureCancelled"
        static let departureUndefinedDelay = "departureUndefinedDelay"
        static let message = "message"
        
    }
    
}

// MARK: deprecated properties and methods
extension Stop {
    @available(*, deprecated, renamed: "arrival.plannedTime")
    public var plannedArrivalTime: Date? { arrival?.plannedTime }
    @available(*, deprecated, renamed: "arrival.predictedTime")
    public var predictedArrivalTime: Date? { arrival?.predictedTime }
    @available(*, deprecated, renamed: "arrival.plannedPlatform")
    public var plannedArrivalPlatform: String? { arrival?.plannedPlatform }
    @available(*, deprecated, renamed: "arrival.predictedPlatform")
    public var predictedArrivalPlatform: String? { arrival?.predictedPlatform }
    @available(*, deprecated, renamed: "arrival.canceleld")
    public var arrivalCancelled: Bool {
        get { return arrival?.cancelled ?? false }
        set { arrival?.cancelled = newValue }
    }
    @available(*, deprecated, renamed: "departure.plannedTime")
    public var plannedDepartureTime: Date? { departure?.plannedTime }
    @available(*, deprecated, renamed: "departure.predictedTime")
    public var predictedDepartureTime: Date? { departure?.predictedTime }
    @available(*, deprecated, renamed: "departure.plannedPlatform")
    public var plannedDeparturePlatform: String? { departure?.plannedPlatform}
    @available(*, deprecated, renamed: "departure.predictedPlatform")
    public var predictedDeparturePlatform: String? { departure?.predictedPlatform }
    @available(*, deprecated, renamed: "departure.cancelled")
    public var departureCancelled: Bool {
        get { return departure?.cancelled ?? false }
        set { departure?.cancelled = newValue }
    }
    
    @available(*, deprecated, renamed: "init(location:departure:arrival:message:)")
    public convenience init(location: Location, plannedArrivalTime: Date?, predictedArrivalTime: Date?, plannedArrivalPlatform: String?, predictedArrivalPlatform: String?, arrivalCancelled: Bool, plannedDepartureTime: Date?, predictedDepartureTime: Date?, plannedDeparturePlatform: String?, predictedDeparturePlatform: String?, departureCancelled: Bool, message: String? = nil, wagonSequenceContext: URL? = nil) {
        let departure: StopEvent?
        if let plannedDepartureTime = plannedDepartureTime {
            departure = StopEvent(location: location, plannedTime: plannedDepartureTime, predictedTime: predictedDepartureTime, plannedPlatform: plannedDeparturePlatform, predictedPlatform: predictedDeparturePlatform, cancelled: departureCancelled)
        } else {
            departure = nil
        }
        let arrival: StopEvent?
        if let plannedArrivalTime = plannedArrivalTime {
            arrival = StopEvent(location: location, plannedTime: plannedArrivalTime, predictedTime: predictedArrivalTime, plannedPlatform: plannedArrivalPlatform, predictedPlatform: predictedArrivalPlatform, cancelled: arrivalCancelled)
        } else {
            arrival = nil
        }
        self.init(location: location, departure: departure, arrival: arrival, message: message)
    }
    
    @available(*, deprecated, renamed: "minTime")
    public func getMinTime() -> Date {
        return minTime!
    }
    
    @available(*, deprecated, renamed: "maxTime")
    public func getMaxTime() -> Date {
        return maxTime!
    }
}
