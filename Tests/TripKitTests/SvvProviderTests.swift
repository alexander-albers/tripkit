import Foundation
@testable import TripKit

class SvvProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .SVV }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return SvvProvider(apiAuthorization: authorizationData.hciAuthorization, requestVerification: authorizationData.hciRequestVerification)
    }
    
    var coordinatesFrom: LocationPoint { return LocationPoint(lat: 47797110, lon: 13053632) } // Salzburg Justizgebäude
    
    var coordinatesTo: LocationPoint { return LocationPoint(lat: 47794000, lon: 13059223) } // Salzburg Akademiestraße
    
    var stationIdFrom: String { return "455002100" } // Salzburg Justizgebäude
    
    var stationIdTo: String { return "455002200" } // Salzburg Akademiestraße
    
    var invalidStationId: String { return "999999" }
    
    var suggestLocations: String { return "Akademiestraße" }
    
    var suggestLocationsIncomplete: String { return "akademie" } // Akademiestraße
    
    var suggestLocationsUmlaut: String { return "Justizgebäude" }
    
    var suggestLocationsAddress: String { return "5020 Salzburg, Weitmoserstraße 9" }
    
}
