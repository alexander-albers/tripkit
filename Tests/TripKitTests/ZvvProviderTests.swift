import Foundation
@testable import TripKit

class ZvvProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .ZVV }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return ZvvProvider(apiAuthorization: authorizationData.hciAuthorization, requestVerification: authorizationData.hciRequestVerification)
    }
    
    var coordinatesFrom: LocationPoint { return LocationPoint(lat: 47378491, lon: 8537945) } // Zürich Hauptbahnhof
    
    var coordinatesTo: LocationPoint { return LocationPoint(lat: 47361762, lon: 8560715) } // Zürich Hegibachplatz
    
    var stationIdFrom: String { return "8503000" } // Zürich Hauptbahnhof
    
    var stationIdTo: String { return "8530812" } // Zürich Hegibachplatz
    
    var invalidStationId: String { return "999999" }
    
    var suggestLocations: String { return "Hegibachplatz" }
    
    var suggestLocationsIncomplete: String { return "hard" } // Hardbrücke
    
    var suggestLocationsUmlaut: String { return "Hardbrücke (SBB)" }
    
    var suggestLocationsAddress: String { return "Ausstellungsstrasse 88, Zürich" }
    
}
