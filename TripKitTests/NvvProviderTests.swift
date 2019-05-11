import Foundation
@testable import TripKit

class NvvProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .NVV }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return NvvProvider(apiAuthorization: authorizationData.hciAuthorization, requestVerification: authorizationData.hciRequestVerification)
    }
    
    var coordinatesFrom: LocationPoint { return LocationPoint(lat: 50017679, lon: 8229480) } // Mainz An den Dünen
    
    var coordinatesTo: LocationPoint { return LocationPoint(lat: 50142890, lon: 8895203) } // Hanau Beethovenplatz
    
    var stationIdFrom: String { return "3000001" } // Hauptwache
    
    var stationIdTo: String { return "3000912" } // Südbahnhof
    
    var invalidStationId: String { return "999999" }
    
    var suggestLocations: String { return "Hauptbahnhof, Frankfurt (Main)" }
    
    var suggestLocationsIncomplete: String { return "könig" } // Königsborn
    
    var suggestLocationsUmlaut: String { return "Wilhelmshöhe Bahnhof" }
    
    var suggestLocationsAddress: String { return "Kaiserstraße 30, Frankfurt am Main - Innenstadt" }
    
}
