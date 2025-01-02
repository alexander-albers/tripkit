import Foundation
import os.log

public class Trip: NSObject, NSSecureCoding {
    
    public static var supportsSecureCoding: Bool = true
    
    private var _id: String
    /// A unique id for this trip.
    ///
    /// This value is either returned by the transit provider or computed once automatically if not such id exists.
    public var id: String {
        if !_id.isEmpty {
            return _id
        } else {
            _id = buildSubstituteId()
            return _id
        }
    }
    /// The departure location.
    public let from: Location
    /// The arrival location.
    public let to: Location
    /// List of legs. Each leg represents a partial, direct trip between two locations.
    public let legs: [Leg]
    /// List of fares for this trip. Fares for a whole day or month are excluded here.
    public let fares: [Fare]
    /// Context for refreshing the trip. See `NetworkProvider.refreshTrip`
    public var refreshContext: RefreshTripContext?
    
    /// Total duration of this trip (in seconds).
    public let duration: TimeInterval
    
    /// Predicted departure time of the first leg, if available, otherwise the planned time.
    ///
    /// See ``NetworkProvider/timeZone`` for a discussion about how to correctly handle time zones.
    public var departureTime: Date { legs[0].departureTime }
    public var departureTimeZone: TimeZone? { legs[0].departureTimeZone }
    /// Predicted arrival time of the last leg, if available, otherwise the planned time.
    ///
    /// See ``NetworkProvider/timeZone`` for a discussion about how to correctly handle time zones.
    public var arrivalTime: Date { legs[legs.count - 1].arrivalTime }
    public var arrivalTimeZone: TimeZone? { legs[legs.count - 1].arrivalTimeZone }
    
    /// Returns always the planned departure time of the first leg.
    ///
    /// See ``NetworkProvider/timeZone`` for a discussion about how to correctly handle time zones.
    public var plannedDepartureTime: Date { legs[0].plannedDepartureTime }
    /// Returns always the planned arrival time of the first leg.
    ///
    /// See ``NetworkProvider/timeZone`` for a discussion about how to correctly handle time zones.
    public var plannedArrivalTime: Date { legs[legs.count - 1].plannedArrivalTime }
    
    /// Returns true if there is realtime departure information.
    public var hasPredictedDepartureTime: Bool {
        return (legs.first(where: {$0 is PublicLeg}) as? PublicLeg)?.departureStop.predictedTime != nil
    }
    /// Returns true if there is realtime arrival information.
    public var hasPredictedArrivalTime: Bool {
        return (legs.last(where: {$0 is PublicLeg}) as? PublicLeg)?.arrivalStop.predictedTime != nil
    }
    
    /// Returns true if the predicted departure time of this trip deviates from the predicted arrival time (rounded to the next minute).
    public var hasDeviantDeparture: Bool {
        guard let leg = legs.first(where: {$0 is PublicLeg}) as? PublicLeg else { return false }
        guard let predictedDeparture = leg.departureStop.predictedTime else { return false }
        return Int(predictedDeparture.timeIntervalSince(leg.departureStop.plannedTime) / 60) != 0
    }
    /// Returns true if the predicted arrival time of this trip deviates from the predicted arrival time (rounded to the next minute).
    public var hasDeviantArrival: Bool {
        guard let leg = legs.last(where: {$0 is PublicLeg}) as? PublicLeg else { return false }
        guard let predictedArrival = leg.arrivalStop.predictedTime else { return false }
        return Int(predictedArrival.timeIntervalSince(leg.arrivalStop.plannedTime) / 60) != 0
    }
    
    /// Returns the earliest departure time.
    ///
    /// This may be either the predicted or the planned time, depending on what is smaller.
    public var minTime: Date {
        return legs.map({ $0.minTime }).min()!
    }
    /// Returns the latest arrival time.
    ///
    /// This may be either the predicted or the planned time, depending on what is marger.
    public var maxTime: Date {
        return legs.map({ $0.maxTime }).max()!
    }
    
    /// Returns true if any public leg of this trip has been cancelled.
    public var isCancelled: Bool {
        legs.compactMap({ $0 as? PublicLeg }).contains(where: { $0.isCancelled })
    }
    
    public init(id: String, from: Location, to: Location, legs: [Leg], duration: TimeInterval, fares: [Fare], refreshContext: RefreshTripContext? = nil) {
        assert(!legs.isEmpty, "Legs cannot be empty")
        self._id = id
        self.from = from
        self.to = to
        self.legs = legs
        if duration == 0 {
            self.duration = legs[legs.count - 1].arrivalTime.timeIntervalSince(legs[0].departureTime)
        } else {
            self.duration = duration
        }
        self.fares = fares
        self.refreshContext = refreshContext
    }
    
    required convenience public init?(coder aDecoder: NSCoder) {
        guard
            let id = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.id) as String?,
            let from = aDecoder.decodeObject(of: Location.self, forKey: PropertyKey.from),
            let to = aDecoder.decodeObject(of: Location.self, forKey: PropertyKey.to),
            let legs = aDecoder.decodeObject(of: [NSArray.self, PublicLeg.self, IndividualLeg.self], forKey: PropertyKey.legs) as? [Leg],
            let fares = aDecoder.decodeObject(of: [NSArray.self, Fare.self], forKey: PropertyKey.fares) as? [Fare]
        else {
            os_log("failed to decode trip", log: .default, type: .error)
            return nil
        }
        let duration = aDecoder.decodeDouble(forKey: PropertyKey.duration)
        let refreshContext = aDecoder.decodeObject(of: RefreshTripContext.self, forKey: PropertyKey.refreshContext)
        self.init(id: id, from: from, to: to, legs: legs, duration: duration, fares: fares, refreshContext: refreshContext)
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(id, forKey: PropertyKey.id)
        aCoder.encode(from, forKey: PropertyKey.from)
        aCoder.encode(to, forKey: PropertyKey.to)
        aCoder.encode(legs, forKey: PropertyKey.legs)
        aCoder.encode(duration, forKey: PropertyKey.duration)
        aCoder.encode(fares, forKey: PropertyKey.fares)
        if let refreshContext = refreshContext {
            aCoder.encode(refreshContext, forKey: PropertyKey.refreshContext)
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
                result += "\(leg.departureStop.plannedTime.timeIntervalSince1970)-"
                result += "\(leg.arrivalStop.plannedTime.timeIntervalSince1970)-"
                result += "\(leg.line.product?.rawValue ?? "")-\(leg.line.label ?? "")"
            }
            result += "|"
        }
        return result
    }
    
    public override var description: String {
        return "Trip id=\(id) legs=\(legs)"
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? Trip else { return false }
        return other.id == id
    }
    
    public override var hash: Int {
        return id.hash
    }
    
    struct PropertyKey {
        
        static let id = "id"
        static let from = "from"
        static let to = "to"
        static let legs = "legs"
        static let duration = "duration"
        static let fares = "fares"
        static let refreshContext = "refreshContext"
        
    }
    
}

// MARK: deprecated properties and methods
extension Trip {
    @available(*, deprecated, renamed: "id")
    public func getId() -> String { id }
    @available(*, deprecated, renamed: "departureTime")
    public func getDepartureTime() -> Date { departureTime }
    @available(*, deprecated, renamed: "arrivalTime")
    public func getArrivalTime() -> Date { arrivalTime }
    @available(*, deprecated, renamed: "plannedDepartureTime")
    public func getPlannedDepartureTime() -> Date { plannedDepartureTime }
    @available(*, deprecated, renamed: "plannedArrivalTime")
    public func getPlannedArrivalTime() -> Date { plannedArrivalTime }
    @available(*, deprecated, renamed: "hasDeviantDeparture")
    public func isDeparturingLate() -> Bool { hasDeviantDeparture }
    @available(*, deprecated, renamed: "hasDeviantArrival")
    public func isArrivingLate() -> Bool { hasDeviantArrival }
    @available(*, deprecated, renamed: "hasPredictedDepartureTime")
    public func isPredictedDepartureTime() -> Bool { hasPredictedDepartureTime }
    @available(*, deprecated, renamed: "hasPredictedArrivalTime")
    public func isPredictedArrivalTime() -> Bool { hasPredictedArrivalTime }
    @available(*, deprecated, renamed: "minTime")
    public func getMinTime() -> Date { minTime }
    @available(*, deprecated, renamed: "maxTime")
    public func getMaxTime() -> Date { maxTime }
}
