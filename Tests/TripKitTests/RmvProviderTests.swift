import Foundation
@testable import TripKit

class RmvProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .RMV }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return RmvProvider(apiAuthorization: authorizationData.hciAuthorization)
    }
    
    var coordinatesFrom: LocationPoint { return LocationPoint(lat: 50069485, lon: 8244636) } // Wiesbaden Hauptbahnhof
    
    var coordinatesTo: LocationPoint { return LocationPoint(lat: 50107167, lon: 8662509) } // Frankfurt (Main) Hauptbahnhof tief
    
    var stationIdFrom: String { return "3006907" } // Wiesbaden Hauptbahnhof
    
    var stationIdTo: String { return "3007010" } // Frankfurt (Main) Hauptbahnhof tief
    
    var invalidStationId: String { return "999999" }
    
    var suggestLocations: String { return "Willy-Brandt-Platz" }
    
    var suggestLocationsIncomplete: String { return "willy" } // Willy-Brandt-Platz
    
    var suggestLocationsUmlaut: String { return "Grüneburgweg" }
    
    var suggestLocationsAddress: String { return "Kaiserstraße 30, Frankfurt am Main - Innenstadt" }
    
}
