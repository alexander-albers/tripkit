import Foundation

public class Departure: NSObject, NSSecureCoding {
    
    public static var supportsSecureCoding: Bool = true
    
    /// Scheduled time of departure.
    public let plannedTime: Date
    /// Actual, prognosed time of departure.
    public let predictedTime: Date?
    /// Predicted time if available, otherwise the planned time.
    public var time: Date { return predictedTime ?? plannedTime }
    /// Means of transport of this departure.
    public let line: Line
    /// Actual departure platform of a station.
    public let predictedPlatform: String?
    /// Scheduled departure platform of a station.
    public let plannedPlatform: String?
    /// Predicted platform if available, otherwise the planned platform if available.
    public var platform: String? {
        return predictedPlatform ?? plannedPlatform
    }
    /// True if the stop has been planned originally, but is now cancelled.
    public let cancelled: Bool
    /// The destination location of the line.
    public let destination: Location?
    /// Currently unused.
    public let capacity: [Int]?
    /// Message specific to this departure.
    public let message: String?
    /// Context for querying the journey of the line. See `NetworkProvider.queryJourneyDetail`
    public let journeyContext: QueryJourneyDetailContext?
    /// URL for querying the wagon sequence of a train.
    /// See `DbProvider.getWagonSequenceUrl()`
    public let wagonSequenceContext: QueryWagonSequenceContext?
    
    public init(plannedTime: Date, predictedTime: Date?, line: Line, position: String?, plannedPosition: String?, cancelled: Bool, destination: Location?, capacity: [Int]?, message: String?, journeyContext: QueryJourneyDetailContext?, wagonSequenceContext: QueryWagonSequenceContext? = nil) {
        self.plannedTime = plannedTime
        self.predictedTime = predictedTime
        self.line = line
        self.predictedPlatform = position
        self.plannedPlatform = plannedPosition
        self.cancelled = cancelled
        self.destination = destination
        self.capacity = capacity
        self.message = message
        self.journeyContext = journeyContext
        self.wagonSequenceContext = wagonSequenceContext
    }
    
    convenience init(plannedTime: Date, predictedTime: Date?, line: Line, position: String?, plannedPosition: String?, cancelled: Bool, destination: Location?, journeyContext: QueryJourneyDetailContext?, wagonSequenceContext: QueryWagonSequenceContext? = nil) {
        self.init(plannedTime: plannedTime, predictedTime: predictedTime, line: line, position: position, plannedPosition: plannedPosition, cancelled: cancelled, destination: destination, capacity: nil, message: nil, journeyContext: journeyContext, wagonSequenceContext: wagonSequenceContext)
    }
    
    public required convenience init?(coder aDecoder: NSCoder) {
        guard let line = aDecoder.decodeObject(of: Line.self, forKey: PropertyKey.lineKey) else { return nil}
        guard let plannedTime = aDecoder.decodeObject(of: NSDate.self, forKey: PropertyKey.plannedTimeKey) as Date? else { return nil }
        let predictedTime = aDecoder.decodeObject(of: NSDate.self, forKey: PropertyKey.predictedTimeKey) as Date?
        let position = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.positionKey) as String?
        let plannedPosition = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.plannedPositionKey) as String?
        let cancelled = aDecoder.decodeBool(forKey: PropertyKey.cancelledKey)
        let destination = aDecoder.decodeObject(of: Location.self, forKey: PropertyKey.destinationKey) as Location?
        let capacity = aDecoder.decodeObject(of: [NSArray.self, NSNumber.self], forKey: PropertyKey.capacityKey) as? [Int]
        let message = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.messageKey) as String?
        let journeyContext = aDecoder.decodeObject(of: QueryJourneyDetailContext.self, forKey: PropertyKey.journeyIdKey)
        let wagonSequenceContext = aDecoder.decodeObject(of: QueryWagonSequenceContext.self, forKey: PropertyKey.wagonSequenceContext)
        self.init(plannedTime: plannedTime, predictedTime: predictedTime, line: line, position: position, plannedPosition: plannedPosition, cancelled: cancelled, destination: destination, capacity: capacity, message: message, journeyContext: journeyContext, wagonSequenceContext: wagonSequenceContext)
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(plannedTime, forKey: PropertyKey.plannedTimeKey)
        if let predictedTime = predictedTime {
            aCoder.encode(predictedTime, forKey: PropertyKey.predictedTimeKey)
        }
        aCoder.encode(line, forKey: PropertyKey.lineKey)
        if let position = predictedPlatform {
            aCoder.encode(position, forKey: PropertyKey.positionKey)
        }
        if let position = plannedPlatform {
            aCoder.encode(position, forKey: PropertyKey.plannedPositionKey)
        }
        aCoder.encode(cancelled, forKey: PropertyKey.cancelledKey)
        if let destination = destination {
            aCoder.encode(destination, forKey: PropertyKey.destinationKey)
        }
        if let capacity = capacity {
            aCoder.encode(capacity, forKey: PropertyKey.capacityKey)
        }
        if let message = message {
            aCoder.encode(message, forKey: PropertyKey.messageKey)
        }
        if let journeyContext = journeyContext {
            aCoder.encode(journeyContext, forKey: PropertyKey.journeyIdKey)
        }
        if let wagonSequenceContext = wagonSequenceContext {
            aCoder.encode(wagonSequenceContext, forKey: PropertyKey.wagonSequenceContext)
        }
    }

    @available(*, deprecated, renamed: "time")
    public func getTime() -> Date {
        return time
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? Departure else { return false }
        if self === other { return true }
        if self.plannedTime != other.plannedTime { return false }
        if self.destination != other.destination { return false }
        if self.line != other.line { return false }
        
        return true
    }
    
    public override var hash: Int {
        get {
            return "\(plannedTime):\(destination?.getUniqueShortName() ?? ""):\(line.product?.rawValue ?? ""):\(line.label ?? ""):\(line.network ?? "")".hash
        }
    }
    
    public override var description: String {
        return "Departure position=\(platform ?? ""), plannedTime=\(String(describing: plannedTime)), predictedTime=\(String(describing: predictedTime)), destination=\(String(describing: destination)), message=\(message ?? ""), line=\(line)"
    }
    
    struct PropertyKey {
        
        static let plannedTimeKey = "plannedTime"
        static let predictedTimeKey = "predictedTime"
        static let lineKey = "line"
        static let positionKey = "position"
        static let plannedPositionKey = "plannedPosition"
        static let cancelledKey = "cancelled"
        static let destinationKey = "destination"
        static let capacityKey = "capacity"
        static let messageKey = "message"
        static let journeyIdKey = "journeyId"
        static let wagonSequenceContext = "wagonSequenceContext"
        
    }
    
}

// MARK: deprecated properties and methods
extension Departure {
    @available(*, deprecated, renamed: "predictedPlatform")
    public var predictedPosition: String? { predictedPlatform }
    @available(*, deprecated, renamed: "plannedPlatform")
    public var plannedPosition: String? { plannedPlatform }
    @available(*, deprecated, renamed: "platform")
    public var position: String? { platform }
}
