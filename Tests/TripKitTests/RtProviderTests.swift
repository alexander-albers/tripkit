import Foundation
@testable import TripKit

class RtProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .RT }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return RtProvider()
    }
    
    var coordinatesFrom: LocationPoint { return LocationPoint(lat: 51521886, lon: -51447) } // 26 Coopers Close, Poplar, Greater London E1 4, Vereinigtes Königreich
    
    var coordinatesTo: LocationPoint { return LocationPoint(lat: 50941312, lon: 6967206) } // Köln
    
    var stationIdFrom: String { return "8000207" } // Köln Hbf
    
    var stationIdTo: String { return "6096001" } // Dublin
    
    var invalidStationId: String { return "999999" }
    
    var suggestLocations: String { return "DUBLIN" }
    
    var suggestLocationsIncomplete: String { return "haupt" } //
    
    var suggestLocationsUmlaut: String { return "Köln Hbf" }
    
    var suggestLocationsAddress: String { return "" }
    
    var supportsJourneyDetails: Bool { return false }
    
}
