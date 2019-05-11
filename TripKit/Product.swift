import Foundation

public enum Product: String, CaseIterable {
    
    case highSpeedTrain = "I"
    case regionalTrain = "R"
    case suburbanTrain = "S"
    case subway = "U"
    case tram = "T"
    case bus = "B"
    case onDemand = "P"
    case ferry = "F"
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
