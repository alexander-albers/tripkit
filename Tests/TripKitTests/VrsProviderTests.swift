import Foundation
@testable import TripKit

class VrsProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .VRS }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return VrsProvider()
    }
    
    var coordinatesFrom: LocationPoint { return LocationPoint(lat: 50740530, lon: 7129200) } //
    
    var coordinatesTo: LocationPoint { return LocationPoint(lat: 50933930, lon: 6932440) } //
    
    var stationIdFrom: String { return "8" } // Köln Hbf
    
    var stationIdTo: String { return "9" } // Köln Breslauer Platz
    
    var invalidStationId: String { return "999999" }
    
    var suggestLocations: String { return "Breslauer Platz" }
    
    var suggestLocationsIncomplete: String { return "bresl" } // Bresslauer Platz
    
    var suggestLocationsUmlaut: String { return "Dom / Hbf, Köln-Innenstadt" }
    
    var suggestLocationsAddress: String { return "Erftstraße 43, Kerpen-Sindorf" }
    
}
