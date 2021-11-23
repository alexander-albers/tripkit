import Foundation

public class Departure: NSObject, NSSecureCoding {
    
    public static var supportsSecureCoding: Bool = true
    
    public let plannedTime: Date? // TODO: planned time should be never nil
    public let predictedTime: Date?
    public let line: Line
    public var position: String? {
        return predictedPosition ?? plannedPosition
    }
    public let predictedPosition: String?
    public let plannedPosition: String?
    public let destination: Location?
    public let capacity: [Int]?
    public let message: String?
    public let journeyContext: QueryJourneyDetailContext?
    public let wagonSequenceContext: URL?
    
    public init(plannedTime: Date?, predictedTime: Date?, line: Line, position: String?, plannedPosition: String?, destination: Location?, capacity: [Int]?, message: String?, journeyContext: QueryJourneyDetailContext?, wagonSequenceContext: URL? = nil) {
        self.plannedTime = plannedTime
        self.predictedTime = predictedTime
        self.line = line
        self.predictedPosition = position
        self.plannedPosition = plannedPosition
        self.destination = destination
        self.capacity = capacity
        self.message = message
        self.journeyContext = journeyContext
        self.wagonSequenceContext = wagonSequenceContext
    }
    
    convenience init(plannedTime: Date?, predictedTime: Date?, line: Line, position: String?, plannedPosition: String?, destination: Location?, journeyContext: QueryJourneyDetailContext?, wagonSequenceContext: URL? = nil) {
        self.init(plannedTime: plannedTime, predictedTime: predictedTime, line: line, position: position, plannedPosition: plannedPosition, destination: destination, capacity: nil, message: nil, journeyContext: journeyContext, wagonSequenceContext: wagonSequenceContext)
    }
    
    public required convenience init?(coder aDecoder: NSCoder) {
        guard let line = aDecoder.decodeObject(of: Line.self, forKey: PropertyKey.lineKey) else { return nil}
        let plannedTime = aDecoder.decodeObject(of: NSDate.self, forKey: PropertyKey.plannedTimeKey) as Date?
        let predictedTime = aDecoder.decodeObject(of: NSDate.self, forKey: PropertyKey.predictedTimeKey) as Date?
        let position = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.positionKey) as String?
        let plannedPosition = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.plannedPositionKey) as String?
        let destination = aDecoder.decodeObject(of: Location.self, forKey: PropertyKey.destinationKey) as Location?
        let capacity = aDecoder.decodeObject(of: [NSArray.self, NSNumber.self], forKey: PropertyKey.capacityKey) as? [Int]
        let message = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.messageKey) as String?
        let journeyContext = aDecoder.decodeObject(of: QueryJourneyDetailContext.self, forKey: PropertyKey.journeyIdKey)
        let wagonSequenceContextPath = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.wagonSequenceContext) as String?
        let wagonSequenceContext = wagonSequenceContextPath != nil ? URL(string: wagonSequenceContextPath!) : nil
        self.init(plannedTime: plannedTime, predictedTime: predictedTime, line: line, position: position, plannedPosition: plannedPosition, destination: destination, capacity: capacity, message: message, journeyContext: journeyContext, wagonSequenceContext: wagonSequenceContext)
    }
    
    public func encode(with aCoder: NSCoder) {
        if let plannedTime = plannedTime {
            aCoder.encode(plannedTime, forKey: PropertyKey.plannedTimeKey)
        }
        if let predictedTime = predictedTime {
            aCoder.encode(predictedTime, forKey: PropertyKey.predictedTimeKey)
        }
        aCoder.encode(line, forKey: PropertyKey.lineKey)
        if let position = position {
            aCoder.encode(position, forKey: PropertyKey.positionKey)
        }
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
            aCoder.encode(wagonSequenceContext.absoluteString, forKey: PropertyKey.wagonSequenceContext)
        }
    }

    public func getTime() -> Date {
        return predictedTime ?? plannedTime ?? Date()
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
            return "\(plannedTime ?? Date()):\(destination?.getUniqueShortName() ?? ""):\(line.product?.rawValue ?? ""):\(line.label ?? ""):\(line.network ?? "")".hash
        }
    }
    
    public override var description: String {
        return "Departure position=\(position ?? ""), plannedTime=\(String(describing: plannedTime)), predictedTime=\(String(describing: predictedTime)), destination=\(String(describing: destination)), message=\(message ?? ""), line=\(line)"
    }
    
    struct PropertyKey {
        
        static let plannedTimeKey = "plannedTime"
        static let predictedTimeKey = "predictedTime"
        static let lineKey = "line"
        static let positionKey = "position"
        static let plannedPositionKey = "plannedPosition"
        static let destinationKey = "destination"
        static let capacityKey = "capacity"
        static let messageKey = "message"
        static let journeyIdKey = "journeyId"
        static let wagonSequenceContext = "wagonSequenceContext"
        
    }
    
}
