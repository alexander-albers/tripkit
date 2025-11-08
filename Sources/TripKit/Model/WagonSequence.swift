import Foundation

public class WagonSequence {
    /// Direction of the train, relative to station track (sectors are left-to-right).
    public let travelDirection: TravelDirection?
    /// This array contains usually only a single element, except when the train is driving as double-traction.
    public let wagonGroups: [WagonGroup]
    /// Contains information about the track and its sectors.
    public let track: StationTrack
    
    init(travelDirection: TravelDirection?, wagonGroups: [WagonGroup], track: StationTrack) {
        self.travelDirection = travelDirection
        self.wagonGroups = wagonGroups
        self.track = track
    }
    
    public enum TravelDirection {
        case left, right
    }
    
}

/// A wagon group is a (usually fixed) set of wagons that can drive either as a single unit or connected to another wagon group as double traction.
public class WagonGroup {
    /// Identifies the model series of the wagon group. See `DbProvider.TrainType` for examples.
    public let designation: String
    /// List of wagons of which this wagon group consists of.
    public let wagons: [Wagon]
    /// Two wagon groups of the same train can have a different destination if they split midway.
    public let destination: String?
    /// Two wagon groups of the same train can have a different line label if they split midway.
    public let lineLabel: String?
    
    init(designation: String, wagons: [Wagon], destination: String?, lineLabel: String?) {
        self.designation = designation
        self.wagons = wagons
        self.destination = destination
        self.lineLabel = lineLabel
    }
}

public class Wagon {
    /// The public-facing number of the wagon, which is used for example for identification of seat reservations.
    public let number: Int?
    /// Orientation of wagon, relative to wagon group orientation.
    public let orientation: WagonOrientation?
    /// Contains position information of the wagon relative to the track.
    public let trackPosition: StationTrackSector
    /// Amenities such as bistro, or accessibility related information.
    public let attributes: [WagonAttributes]
    /// This wagon contains an area for first class seating. A wagon can contain both first and second class areas.
    public let firstClass: Bool
    /// This wagon contains an area for second class seating. A wagon can contain both first and second class areas.
    public let secondClass: Bool
    /// Degree of occupancy of this wagon.
    public let loadFactor: LoadFactor?
    /// False if the wagon is closed.
    public let isOpen: Bool
    
    init(number: Int?, orientation: WagonOrientation?, trackPosition: StationTrackSector, attributes: [WagonAttributes], firstClass: Bool, secondClass: Bool, loadFactor: LoadFactor?, isOpen: Bool) {
        self.number = number
        self.orientation = orientation
        self.trackPosition = trackPosition
        self.attributes = attributes
        self.firstClass = firstClass
        self.secondClass = secondClass
        self.loadFactor = loadFactor
        self.isOpen = isOpen
    }
}

public enum WagonOrientation {
    case forward, backward
}

public class StationTrackSector {
    /// Designation of the track sector, usually as letters from A to G.
    public let sectorName: String
    /// Start position of wagon, in meters from start of track.
    public let start: Double
    /// End position of wagon, in meters from start of track.
    public let end: Double
    
    init(sectorName: String, start: Double, end: Double) {
        self.sectorName = sectorName
        self.start = start
        self.end = end
    }
}

public class WagonAttributes {
    public let attribute: WagonAttributes.`Type`
    public let state: WagonAttributes.State
    
    init(attribute: WagonAttributes.`Type`, state: WagonAttributes.State) {
        self.attribute = attribute
        self.state = state
    }
    
    public enum `Type` {
        case bistro, airCondition, bikeSpace, wheelchairSpace, toiletWheelchair, boardingAid, cabinInfant, zoneQuiet, zoneFamily, seatsSeverelyDisabled, seatsBahnComfort
    }
    
    public enum State {
        case available, notAvailable, reserved, undefined
    }

}

public class StationTrack {
    /// Designation of the track, usually as number.
    public let trackNumber: String?
    /// Start position of track, in meters.
    public let start: Double
    /// End position of track, in meters.
    public let end: Double
    /// List of sectors at this track
    public let sectors: [StationTrackSector]
    
    init(trackNumber: String?, start: Double, end: Double, sectors: [StationTrackSector]) {
        self.trackNumber = trackNumber
        self.start = start
        self.end = end
        self.sectors = sectors
    }
}
