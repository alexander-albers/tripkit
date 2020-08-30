import Foundation
@testable import TripKit

class ShProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .SH }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return ShProvider(apiAuthorization: authorizationData.hciAuthorization)
    }
    
    var coordinatesFrom: LocationPoint { return LocationPoint(lat: 53632350, lon: 10006648) } // Hamburg Flughafen
    
    var coordinatesTo: LocationPoint { return LocationPoint(lat: 53804125, lon: 10697487) } // Lübeck Flughafen
    
    var stationIdFrom: String { return "8002547" } // Hamburg Flughafen
    
    var stationIdTo: String { return "8003781" } // Lübeck Flughafen
    
    var invalidStationId: String { return "999999" }
    
    var suggestLocations: String { return "Bf. Dammtor, Hamburg" }
    
    var suggestLocationsIncomplete: String { return "uhland" } // Uhlandstraße
    
    var suggestLocationsUmlaut: String { return "Überseequartier" }
    
    var suggestLocationsAddress: String { return "Edmund-Siemers-Allee 1, 20146 Hansestadt Hamburg" }
    
}
