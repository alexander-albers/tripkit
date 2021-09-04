import Foundation
import os.log

public protocol Leg {
    
    var departure: Location {get}
    var arrival: Location {get}
    var path: [LocationPoint] {get}
    
    func getDepartureTime() -> Date
    
    func getArrivalTime() -> Date
    
    func getPlannedDepartureTime() -> Date
    
    func getPlannedArrivalTime() -> Date
    
    func getMinTime() -> Date
    
    func getMaxTime() -> Date
    
}

public class PublicLeg: NSObject, Leg, NSSecureCoding {
    
    public static var supportsSecureCoding: Bool = true
    
    public var departure: Location
    public var arrival: Location
    public let line: Line
    public let destination: Location?
    public let departureStop: Stop
    public let arrivalStop: Stop
    public let intermediateStops: [Stop]
    public let message: String?
    public let path: [LocationPoint]
    public let journeyContext: QueryJourneyDetailContext?
    
    public init(line: Line, destination: Location?, departureStop: Stop, arrivalStop: Stop, intermediateStops: [Stop], message: String?, path: [LocationPoint] = [], journeyContext: QueryJourneyDetailContext?) {
        self.departure = departureStop.location
        self.arrival = arrivalStop.location
        self.line = line
        self.destination = destination
        self.departureStop = departureStop
        self.arrivalStop = arrivalStop
        self.intermediateStops = intermediateStops
        self.message = message
        self.path = path
        self.journeyContext = journeyContext
    }
    
    required convenience public init?(coder aDecoder: NSCoder) {
        guard let line = aDecoder.decodeObject(of: Line.self, forKey: PropertyKey.line), let departureStop = aDecoder.decodeObject(of: Stop.self, forKey: PropertyKey.departureStop), let arrivalStop = aDecoder.decodeObject(of: Stop.self, forKey: PropertyKey.arrivalStop), let intermediateStops = aDecoder.decodeObject(of: [NSArray.self, Stop.self], forKey: PropertyKey.intermediateStops) as? [Stop] else {
            os_log("failed to decode public leg", log: .default, type: .error)
            return nil
        }
        let destination = aDecoder.decodeObject(of: Location.self, forKey: PropertyKey.destination)
        let message = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.message) as String?
        let encodedPath = aDecoder.decodeObject(of: [NSArray.self], forKey: PropertyKey.path) as? [Int] ?? []
        let path = stride(from: 0, to: encodedPath.count % 2 == 0 ? encodedPath.count : 0, by: 2).map {
            LocationPoint(lat: encodedPath[$0], lon: encodedPath[$0 + 1])
        }
        let journeyContext = aDecoder.decodeObject(of: QueryJourneyDetailContext.self, forKey: PropertyKey.journeyContext)
        self.init(line: line, destination: destination, departureStop: departureStop, arrivalStop: arrivalStop, intermediateStops: intermediateStops, message: message, path: path, journeyContext: journeyContext)
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(line, forKey: PropertyKey.line)
        if let destination = destination {
            aCoder.encode(destination, forKey: PropertyKey.destination)
        }
        aCoder.encode(departureStop, forKey: PropertyKey.departureStop)
        aCoder.encode(arrivalStop, forKey: PropertyKey.arrivalStop)
        aCoder.encode(intermediateStops, forKey: PropertyKey.intermediateStops)
        if let message = message {
            aCoder.encode(message, forKey: PropertyKey.message)
        }
        aCoder.encode(path.flatMap({[$0.lat, $0.lon]}), forKey: PropertyKey.path)
        if let journeyContext = journeyContext {
            aCoder.encode(journeyContext, forKey: PropertyKey.journeyContext)
        }
    }
    
    public func getDepartureTime() -> Date {
        return (departureStop.predictedDepartureTime != nil ? departureStop.predictedDepartureTime : departureStop.plannedDepartureTime)!
    }
    
    public func getArrivalTime() -> Date {
        return (arrivalStop.predictedArrivalTime != nil ? arrivalStop.predictedArrivalTime : arrivalStop.plannedArrivalTime)!
    }
    
    public func getPlannedDepartureTime() -> Date {
        return (departureStop.plannedDepartureTime ?? departureStop.predictedDepartureTime)!
    }
    
    public func getPlannedArrivalTime() -> Date {
        return (arrivalStop.plannedArrivalTime ?? arrivalStop.predictedArrivalTime)!
    }
    
    public func getMinTime() -> Date {
        return departureStop.getMinTime()
    }
    
    public func getMaxTime() -> Date {
        return arrivalStop.getMaxTime()
    }
    
    public override var description: String {
        return "Public departure=\(departure), arrival=\(arrival))"
    }
    
    struct PropertyKey {
        
        static let line = "line"
        static let destination = "destination"
        static let departureStop = "departureStop"
        static let arrivalStop = "arrivalStop"
        static let intermediateStops = "intermediateStops"
        static let message = "message"
        static let path = "path"
        static let journeyContext = "journeyContext"
        
    }
    
}

public class IndividualLeg: NSObject, Leg, NSSecureCoding {
    
    public static var supportsSecureCoding: Bool = true
    
    public let type: Type
    public var departure: Location
    public var arrival: Location
    public let departureTime: Date
    public let arrivalTime: Date
    public let min: Int
    public let distance: Int
    public let path: [LocationPoint]
    
    public init(type: Type, departureTime: Date, departure: Location, arrival: Location, arrivalTime: Date, distance: Int, path: [LocationPoint]) {
        self.type = type
        self.departure = departure
        self.arrival = arrival
        self.departureTime = departureTime
        self.arrivalTime = arrivalTime
        self.min = Int(arrivalTime.timeIntervalSince(departureTime) / 60.0)
        self.distance = distance
        self.path = path
    }
    
    required convenience public init?(coder aDecoder: NSCoder) {
        guard let type = Type(rawValue: aDecoder.decodeInteger(forKey: PropertyKey.type)), let departure = aDecoder.decodeObject(of: Location.self, forKey: PropertyKey.departure), let arrival = aDecoder.decodeObject(of: Location.self, forKey: PropertyKey.arrival), let departureTime = aDecoder.decodeObject(of: NSDate.self, forKey: PropertyKey.departureTime) as Date?, let arrivalTime = aDecoder.decodeObject(of: NSDate.self, forKey: PropertyKey.arrivalTime) as Date? else {
            os_log("failed to decode individual leg", log: .default, type: .error)
            return nil
        }
        let encodedPath = aDecoder.decodeObject(of: [NSArray.self], forKey: PropertyKey.path) as? [Int] ?? []
        let path = stride(from: 0, to: encodedPath.count % 2 == 0 ? encodedPath.count : 0, by: 2).map {
            LocationPoint(lat: encodedPath[$0], lon: encodedPath[$0 + 1])
        }
        let distance = aDecoder.decodeInteger(forKey: PropertyKey.distance)
        self.init(type: type, departureTime: departureTime, departure: departure, arrival: arrival, arrivalTime: arrivalTime, distance: distance, path: path)
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(type.rawValue, forKey: PropertyKey.type)
        aCoder.encode(departure, forKey: PropertyKey.departure)
        aCoder.encode(arrival, forKey: PropertyKey.arrival)
        aCoder.encode(departureTime, forKey: PropertyKey.departureTime)
        aCoder.encode(arrivalTime, forKey: PropertyKey.arrivalTime)
        aCoder.encode(distance, forKey: PropertyKey.distance)
        aCoder.encode(path.flatMap({[$0.lat, $0.lon]}), forKey: PropertyKey.path)
    }
    
    public func getDepartureTime() -> Date {
        return departureTime
    }
    
    public func getArrivalTime() -> Date {
        return arrivalTime
    }
    
    public func getPlannedDepartureTime() -> Date {
        return departureTime
    }
    
    public func getPlannedArrivalTime() -> Date {
        return arrivalTime
    }
    
    public func getMinTime() -> Date {
        return departureTime
    }
    
    public func getMaxTime() -> Date {
        return arrivalTime
    }
    
    public enum `Type`: Int {
        case WALK, BIKE, CAR, TRANSFER
    }
    
    struct PropertyKey {
        
        static let type = "type"
        static let departure = "departure"
        static let arrival = "arrival"
        static let departureTime = "departureTime"
        static let arrivalTime = "arrivalTime"
        static let distance = "distance"
        static let path = "path"
        
    }
    
}
