import Foundation

/// Type of a means of transport
public enum Product: String, CaseIterable {
    
    /// ICE, IC
    case highSpeedTrain = "I"
    /// RE, RB
    case regionalTrain = "R"
    /// "S-Bahn"
    case suburbanTrain = "S"
    /// "U-Bahn", Metro
    case subway = "U"
    /// Streetcar
    case tram = "T"
    /// Bus or "Schnellbus" (fast bus)
    case bus = "B"
    /// Bus that has to be called first for a reservation
    case onDemand = "P"
    /// Ship
    case ferry = "F"
    /// Train to mountain
    case cablecar = "C"

    public var id: String {
        switch self {
        case .highSpeedTrain:
            return "high_speed_train"
        case .regionalTrain:
            return "regional_train"
        case .suburbanTrain:
            return "suburban_train"
        case .subway:
            return "subway"
        case .tram:
            return "tram"
        case .bus:
            return "bus"
        case .ferry:
            return "ferry"
        case .cablecar:
            return "cablecar"
        case .onDemand:
            return "on_demand"
        }
    }
    
}
