import Foundation

public class StopEvent: NSObject {
    /// Information about the station of the stop.
    public let location: Location
    /// Scheduled time of arrival or departure.
    ///
    /// See ``NetworkProvider/timeZone`` for a discussion about how to correctly handle time zones.
    public let plannedTime: Date
    /// Actual, prognosed time of arrival or departure.
    ///
    /// See ``NetworkProvider/timeZone`` for a discussion about how to correctly handle time zones.
    public let predictedTime: Date?
    /// Scheduled arrival/departure platform of a station.
    public let plannedPlatform: String?
    /// Actual arrival/departure platform of a station.
    public let predictedPlatform: String?
    /// True if the stop has been planned originally, but is now skipped.
    public var cancelled: Bool
    /// True if the actual delay is unknown.
    public var undefinedDelay: Bool
    
    /// Predicted time if available, otherwise the planned time.
    public var time: Date { predictedTime ?? plannedTime }
    /// Predicted platform if available, otherwise the planned platform if available.
    public var platform: String? { predictedPlatform ?? plannedPlatform }
    
    /// Message specific to this stop.
    public var message: String?
    
    /// Planned or predicted time of the stop, depending on which value is smaller.
    public var minTime: Date {
        guard let predictedTime = predictedTime else {
            return plannedTime
        }
        return min(plannedTime, predictedTime)
    }
    
    /// Planned or predicted time of the stop, depending on which value is larger.
    public var maxTime: Date {
        guard let predictedTime = predictedTime else {
            return plannedTime
        }
        return max(plannedTime, predictedTime)
    }
    
    public init(location: Location, plannedTime: Date, predictedTime: Date?, plannedPlatform: String?, predictedPlatform: String?, cancelled: Bool, undefinedDelay: Bool = false) {
        self.location = location
        self.plannedTime = plannedTime
        self.predictedTime = predictedTime
        self.plannedPlatform = plannedPlatform
        self.predictedPlatform = predictedPlatform
        self.cancelled = cancelled
        self.undefinedDelay = undefinedDelay
    }
    
    public override func isEqual(_ other: Any?) -> Bool {
        guard let other = other as? StopEvent else { return false }
        if self === other { return true }
        if self.location != other.location {
            return false
        }
        return self.plannedTime == other.plannedTime && self.predictedTime == other.predictedTime && self.plannedPlatform == other.plannedPlatform && self.predictedPlatform == other.predictedPlatform && self.cancelled == other.cancelled
    }
}

// MARK: deprecated properties and methods
extension StopEvent {
    @available(*, deprecated, renamed: "plannedTime")
    public var plannedArrivalTime: Date? { plannedTime }
    @available(*, deprecated, renamed: "predictedTime")
    public var predictedArrivalTime: Date? { predictedTime }
    @available(*, deprecated, renamed: "plannedPlatform")
    public var plannedArrivalPlatform: String? { plannedPlatform }
    @available(*, deprecated, renamed: "predictedPlatform")
    public var predictedArrivalPlatform: String? { predictedPlatform }
    @available(*, deprecated, renamed: "cancelled")
    public var arrivalCancelled: Bool {
        get { return cancelled }
        set { cancelled = newValue }
    }
    @available(*, deprecated, renamed: "plannedTime")
    public var plannedDepartureTime: Date? { plannedTime }
    @available(*, deprecated, renamed: "predictedTime")
    public var predictedDepartureTime: Date? { predictedTime }
    @available(*, deprecated, renamed: "plannedPlatform")
    public var plannedDeparturePlatform: String? { plannedPlatform}
    @available(*, deprecated, renamed: "predictedPlatform")
    public var predictedDeparturePlatform: String? { predictedPlatform }
    @available(*, deprecated, renamed: "cancelled")
    public var departureCancelled: Bool {
        get { return cancelled }
        set { cancelled = newValue }
    }
}
