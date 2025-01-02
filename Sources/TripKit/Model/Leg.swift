import Foundation
import os.log

/// A leg represents a partial, direct trip between two locations. A leg can be an `IndividualLeg` or a `PublicLeg`.
public protocol Leg {
    
    /// Departure location or station.
    var departure: Location { get }
    /// Arrival location or station.
    var arrival: Location { get }
    /// Coordinate sequence of this leg.
    var path: [LocationPoint] { get }
    
    /// Predicted departure time, if available, otherwise the planned time.
    ///
    /// See ``NetworkProvider/timeZone`` for a discussion about how to correctly handle time zones.
    var departureTime: Date { get }
    var departureTimeZone: TimeZone? { get }
    
    /// Predicted departure time, if available, otherwise the planned time.
    /// See ``NetworkProvider/timeZone`` for a discussion about how to correctly handle time zones.
    var arrivalTime: Date { get }
    var arrivalTimeZone: TimeZone? { get }
    
    /// Returns always the planned departure time.
    ///
    /// See ``NetworkProvider/timeZone`` for a discussion about how to correctly handle time zones.
    var plannedDepartureTime: Date { get }
    /// Returns always the planned arrival time.
    ///
    /// See ``NetworkProvider/timeZone`` for a discussion about how to correctly handle time zones.
    var plannedArrivalTime: Date { get }
    
    /// Returns the earliest departure time.
    ///
    /// This may be either the predicted or the planned time, depending on what is smaller.
    /// 
    /// See ``NetworkProvider/timeZone`` for a discussion about how to correctly handle time zones.
    var minTime: Date { get }
    /// Returns the latest arrival time.
    ///
    /// This may be either the predicted or the planned time, depending on what is marger.
    ///
    /// See ``NetworkProvider/timeZone`` for a discussion about how to correctly handle time zones.
    var maxTime: Date { get }
}

public extension Leg {
    @available(*, deprecated, renamed: "departureTime")
    func getDepartureTime() -> Date { departureTime }
    @available(*, deprecated, renamed: "arrivalTime")
    func getArrivalTime() -> Date { arrivalTime }
    @available(*, deprecated, renamed: "plannedDepartureTime")
    func getPlannedDepartureTime() -> Date { plannedDepartureTime }
    @available(*, deprecated, renamed: "plannedArrivalTime")
    func getPlannedArrivalTime() -> Date { plannedArrivalTime }
    @available(*, deprecated, renamed: "minTime")
    func getMinTime() -> Date { minTime }
    @available(*, deprecated, renamed: "maxTime")
    func getMaxTime() -> Date { maxTime }
}

/// A leg using a public means of transport.
public class PublicLeg: NSObject, Leg, NSSecureCoding {
    
    public static var supportsSecureCoding: Bool = true
    
    public var departure: Location { departureStop.location }
    public var arrival: Location { arrivalStop.location }
    public let path: [LocationPoint]
    public var departureTime: Date { departureStop.predictedTime ?? departureStop.plannedTime }
    public var departureTimeZone: TimeZone? { departureStop.timeZone }
    public var arrivalTime: Date { arrivalStop.predictedTime ?? arrivalStop.plannedTime }
    public var arrivalTimeZone: TimeZone? { arrivalStop.timeZone }
    public var plannedDepartureTime: Date { departureStop.plannedTime }
    public var plannedArrivalTime: Date { arrivalStop.plannedTime }
    public var minTime: Date { departureStop.minTime }
    public var maxTime: Date { arrivalStop.maxTime }
    
    /// Means of transport of this leg.
    public let line: Line
    /// The destination location of the line.
    public let destination: Location?
    /// Information about the departure of this stop. Contains time, platform and a bool indicating if the stop has been cancelled.
    public let departureStop: StopEvent
    /// Information about the arrival of this stop. Contains time, platform and a bool indicating if the stop has been cancelled.
    public let arrivalStop: StopEvent
    /// List of all intermediate stops in between the departure and arrival location.
    public let intermediateStops: [Stop]
    /// Message regarding this whole leg.
    public let message: String?
    /// Context for querying the journey of the line. See `NetworkProvider.queryJourneyDetail`
    public let journeyContext: QueryJourneyDetailContext?
    /// Context for querying the wagon sequence of the line. See `NetworkProvider.queryWagonSequence`
    public let wagonSequenceContext: QueryWagonSequenceContext?
    /// Load factor tells the expected train capacity utilisation of a train of the DB provider.
    public let loadFactor: LoadFactor?
    
    /// Returns true if either the departure or arrival stop have been cancelled.
    public var isCancelled: Bool {
        return departureStop.cancelled || arrivalStop.cancelled
    }
    
    public init(line: Line, destination: Location?, departure: StopEvent, arrival: StopEvent, intermediateStops: [Stop], message: String?, path: [LocationPoint], journeyContext: QueryJourneyDetailContext?, wagonSequenceContext: QueryWagonSequenceContext?, loadFactor: LoadFactor?) {
        self.line = line
        self.destination = destination
        self.departureStop = departure
        self.arrivalStop = arrival
        self.intermediateStops = intermediateStops
        self.message = message
        self.path = path
        self.journeyContext = journeyContext
        self.wagonSequenceContext = wagonSequenceContext
        self.loadFactor = loadFactor
    }
    
    required convenience public init?(coder aDecoder: NSCoder) {
        guard
            let line = aDecoder.decodeObject(of: Line.self, forKey: PropertyKey.line),
            let departureStop = aDecoder.decodeObject(of: Stop.self, forKey: PropertyKey.departureStop)?.departure,
            let arrivalStop = aDecoder.decodeObject(of: Stop.self, forKey: PropertyKey.arrivalStop)?.arrival,
            let intermediateStops = aDecoder.decodeObject(of: [NSArray.self, Stop.self], forKey: PropertyKey.intermediateStops) as? [Stop]
        else {
            os_log("failed to decode public leg", log: .default, type: .error)
            return nil
        }
        let destination = aDecoder.decodeObject(of: Location.self, forKey: PropertyKey.destination)
        let message = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.message) as String?
        let encodedPath = aDecoder.decodeObject(of: [NSArray.self, NSNumber.self], forKey: PropertyKey.path) as? [Int] ?? []
        let path = stride(from: 0, to: encodedPath.count % 2 == 0 ? encodedPath.count : 0, by: 2).map {
            LocationPoint(lat: encodedPath[$0], lon: encodedPath[$0 + 1])
        }
        let journeyContext = aDecoder.decodeObject(of: QueryJourneyDetailContext.self, forKey: PropertyKey.journeyContext)
        let wagonSequenceContext = aDecoder.decodeObject(of: QueryWagonSequenceContext.self, forKey: PropertyKey.wagonSequenceContext)
        let loadFactor = LoadFactor(rawValue: aDecoder.decodeInteger(forKey: PropertyKey.loadFactor))
        self.init(line: line, destination: destination, departure: departureStop, arrival: arrivalStop, intermediateStops: intermediateStops, message: message, path: path, journeyContext: journeyContext, wagonSequenceContext: wagonSequenceContext, loadFactor: loadFactor)
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(line, forKey: PropertyKey.line)
        if let destination = destination {
            aCoder.encode(destination, forKey: PropertyKey.destination)
        }
        aCoder.encode(Stop(location: departureStop.location, departure: departureStop, arrival: nil, message: departureStop.message), forKey: PropertyKey.departureStop)
        aCoder.encode(Stop(location: arrivalStop.location, departure: nil, arrival: arrivalStop, message: arrivalStop.message), forKey: PropertyKey.arrivalStop)
        aCoder.encode(intermediateStops, forKey: PropertyKey.intermediateStops)
        if let message = message {
            aCoder.encode(message, forKey: PropertyKey.message)
        }
        aCoder.encode(path.flatMap({[$0.lat, $0.lon]}), forKey: PropertyKey.path)
        if let journeyContext = journeyContext {
            aCoder.encode(journeyContext, forKey: PropertyKey.journeyContext)
        }
        if let wagonSequenceContext = wagonSequenceContext {
            aCoder.encode(wagonSequenceContext, forKey: PropertyKey.wagonSequenceContext)
        }
        if let loadFactor = loadFactor {
            aCoder.encode(loadFactor.rawValue, forKey: PropertyKey.loadFactor)
        }
    }
    
    public override var description: String {
        return "Public departure=\(departure), arrival=\(arrival))"
    }
    
    public override func isEqual(_ other: Any?) -> Bool {
        guard let other = other as? PublicLeg else { return false }
        if other === self { return true }
        
        return self.departure == other.departure && self.arrival == other.arrival && self.line == other.line && self.destination == other.destination && self.departureStop == other.departureStop && self.arrivalStop == other.arrivalStop && self.intermediateStops == other.intermediateStops
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
        static let wagonSequenceContext = "wagonSequenceContext"
        static let loadFactor = "loadFactor"
        
    }
    
}

/// A leg using an individual means of transport, like walking, driving a bike or renting a taxi.
public class IndividualLeg: NSObject, Leg, NSSecureCoding {
    
    public static var supportsSecureCoding: Bool = true
    
    public var departure: Location
    public var arrival: Location
    public let path: [LocationPoint]
    public let departureTime: Date
    public let departureTimeZone: TimeZone?
    public let arrivalTime: Date
    public let arrivalTimeZone: TimeZone?
    public var plannedDepartureTime: Date { departureTime }
    public var plannedArrivalTime: Date { arrivalTime }
    public var minTime: Date { departureTime }
    public var maxTime: Date { arrivalTime }
    
    /// Type of this individual leg.
    public let type: `Type`
    /// Number of minutes between departure and arrival.
    public let min: Int
    /// Diestance in meters between departure and arrival.
    public let distance: Int
    
    public init(type: `Type`, departure: Location, arrival: Location, departureTime: Date, arrivalTime: Date, departureTimeZone: TimeZone?, arrivalTimeZone: TimeZone?, distance: Int, path: [LocationPoint]) {
        self.type = type
        self.departure = departure
        self.arrival = arrival
        self.departureTime = departureTime
        self.arrivalTime = arrivalTime
        self.departureTimeZone = departureTimeZone
        self.arrivalTimeZone = arrivalTimeZone
        self.min = Int(arrivalTime.timeIntervalSince(departureTime) / 60.0)
        self.distance = distance
        self.path = path
    }
    
    required convenience public init?(coder aDecoder: NSCoder) {
        guard
            let type = Type(rawValue: aDecoder.decodeInteger(forKey: PropertyKey.type)),
            let departure = aDecoder.decodeObject(of: Location.self, forKey: PropertyKey.departure),
            let arrival = aDecoder.decodeObject(of: Location.self, forKey: PropertyKey.arrival),
            let departureTime = aDecoder.decodeObject(of: NSDate.self, forKey: PropertyKey.departureTime) as Date?,
            let arrivalTime = aDecoder.decodeObject(of: NSDate.self, forKey: PropertyKey.arrivalTime) as Date?
        else {
            os_log("failed to decode individual leg", log: .default, type: .error)
            return nil
        }
        
        let departureTimeZone: TimeZone?
        if let secondsFromGMT = aDecoder.decodeObject(of: NSNumber.self, forKey: PropertyKey.departureTimeZone) as? Int {
            departureTimeZone = TimeZone(secondsFromGMT: secondsFromGMT)
        } else {
            departureTimeZone = nil
        }
        let arrivalTimeZone: TimeZone?
        if let secondsFromGMT = aDecoder.decodeObject(of: NSNumber.self, forKey: PropertyKey.arrivalTimeZone) as? Int {
            arrivalTimeZone = TimeZone(secondsFromGMT: secondsFromGMT)
        } else {
            arrivalTimeZone = nil
        }
        let encodedPath = aDecoder.decodeObject(of: [NSArray.self, NSNumber.self], forKey: PropertyKey.path) as? [Int] ?? []
        let path = stride(from: 0, to: encodedPath.count % 2 == 0 ? encodedPath.count : 0, by: 2).map {
            LocationPoint(lat: encodedPath[$0], lon: encodedPath[$0 + 1])
        }
        let distance = aDecoder.decodeInteger(forKey: PropertyKey.distance)
        self.init(type: type, departure: departure, arrival: arrival, departureTime: departureTime, arrivalTime: arrivalTime, departureTimeZone: departureTimeZone, arrivalTimeZone: arrivalTimeZone, distance: distance, path: path)
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(type.rawValue, forKey: PropertyKey.type)
        aCoder.encode(departure, forKey: PropertyKey.departure)
        aCoder.encode(arrival, forKey: PropertyKey.arrival)
        aCoder.encode(departureTime, forKey: PropertyKey.departureTime)
        aCoder.encode(departureTimeZone?.secondsFromGMT(), forKey: PropertyKey.departureTimeZone)
        aCoder.encode(arrivalTime, forKey: PropertyKey.arrivalTime)
        aCoder.encode(arrivalTimeZone?.secondsFromGMT(), forKey: PropertyKey.arrivalTimeZone)
        aCoder.encode(distance, forKey: PropertyKey.distance)
        aCoder.encode(path.flatMap({[$0.lat, $0.lon]}), forKey: PropertyKey.path)
    }
    
    public enum `Type`: Int {
        case walk, bike, car, transfer
    }
    
    struct PropertyKey {
        
        static let type = "type"
        static let departure = "departure"
        static let arrival = "arrival"
        static let departureTime = "departureTime"
        static let departureTimeZone = "departureTimeZone"
        static let arrivalTime = "arrivalTime"
        static let arrivalTimeZone = "arrivalTimeZone"
        static let distance = "distance"
        static let path = "path"
        
    }
    
}
