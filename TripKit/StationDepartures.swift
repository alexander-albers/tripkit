import Foundation

public class StationDepartures: CustomStringConvertible {
    
    public let stopLocation: Location
    public var departures: [Departure]
    public var lines: [ServingLine]
    
    init(stopLocation: Location, departures: [Departure], lines: [ServingLine]) {
        self.stopLocation = stopLocation
        self.departures = departures
        self.lines = lines
    }
    
    public var description: String {
        return "StationDepartures location=\(stopLocation), departures=\(departures), lines=\(lines)"
    }
    
}
