import Foundation
@testable import TripKit

class BsvagProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .BSVAG }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return BsvagProvider()
    }
    
    var coordinatesFrom: LocationPoint { return LocationPoint(lat: 52252642, lon: 10539546) } // Hauptbahnhof
    
    var coordinatesTo: LocationPoint { return LocationPoint(lat: 52265399, lon: 10521948) } // Packhof
    
    var stationIdFrom: String { return "26000178" } // Hauptbahnhof
    
    var stationIdTo: String { return "26000322" } // Packhof
    
    var invalidStationId: String { return "999999" }
    
    var suggestLocations: String { return "Packhof" }
    
    var suggestLocationsIncomplete: String { return "Kurf" } // Kurfürstenring
    
    var suggestLocationsUmlaut: String { return "Münzstraße" }
    
    var suggestLocationsAddress: String { return "Braunschweig, Willy-Brandt-Platz" }
    
}
