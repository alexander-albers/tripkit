import Foundation

public class StationDepartures: NSObject, NSSecureCoding {
    
    public static var supportsSecureCoding: Bool = true
    
    /// Location of the station.
    public let stopLocation: Location
    /// Departures from the station.
    public var departures: [Departure]
    /// All possible lines that may be departing from the specified location.
    public var lines: [ServingLine]
    
    init(stopLocation: Location, departures: [Departure], lines: [ServingLine]) {
        self.stopLocation = stopLocation
        self.departures = departures
        self.lines = lines
    }
    
    public required convenience init?(coder: NSCoder) {
        guard
            let stopLocation = coder.decodeObject(of: Location.self, forKey: PropertyKey.stopLocationKey),
            let departures = coder.decodeObject(of: [Departure.self, NSArray.self], forKey: PropertyKey.departuresKey) as? [Departure],
            let lines = coder.decodeObject(of: [ServingLine.self, NSArray.self], forKey: PropertyKey.linesKey) as? [ServingLine]
        else {
            return nil
        }
        self.init(stopLocation: stopLocation, departures: departures, lines: lines)
    }
    
    public func encode(with coder: NSCoder) {
        coder.encode(stopLocation, forKey: PropertyKey.stopLocationKey)
        coder.encode(departures, forKey: PropertyKey.departuresKey)
        coder.encode(lines, forKey: PropertyKey.linesKey)
    }
    
    public override var description: String {
        return "StationDepartures location=\(stopLocation), departures=\(departures), lines=\(lines)"
    }
    
    public override func isEqual(_ other: Any?) -> Bool {
        guard let other = other as? StationDepartures else { return false }
        if self === other { return true }
        return self.stopLocation == other.stopLocation && self.departures == other.departures && self.lines == other.lines
    }
    
    struct PropertyKey {
        
        static let stopLocationKey = "stopLocation"
        static let departuresKey = "departures"
        static let linesKey = "lines"
        
    }
    
}
