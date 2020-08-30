import Foundation
@testable import TripKit

class KvvProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .KVV }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return KvvProvider()
    }
    
    var coordinatesFrom: LocationPoint { return LocationPoint(lat: 49009526, lon: 8404914) } // Karlsruhe Marktplatz
    
    var coordinatesTo: LocationPoint { return LocationPoint(lat: 49009393, lon: 8408866) } // Karlsruhe Kronenplatz (Kaiserstr.)
    
    var stationIdFrom: String { return "7000001" } // Karlsruhe Marktplatz
    
    var stationIdTo: String { return "7000002" } // Karlsruhe Kronenplatz (Kaiserstr.)
    
    var invalidStationId: String { return "999999" }
    
    var suggestLocations: String { return "Marktplatz" }
    
    var suggestLocationsIncomplete: String { return "marktpl" } // Marktplatz
    
    var suggestLocationsUmlaut: String { return "Händelstraße" }
    
    var suggestLocationsAddress: String { return "Karlsruhe, Bahnhofplatz 2" }
    
}
