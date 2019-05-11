import Foundation
@testable import TripKit

class IvbProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .IVB }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return IvbProvider(apiAuthorization: authorizationData.hciAuthorization)
    }
    
    var coordinatesFrom: LocationPoint { return LocationPoint(lat: 47272347, lon: 11400363) } // Innsbruck Kochstraße
    
    var coordinatesTo: LocationPoint { return LocationPoint(lat: 47271233, lon: 11404534) } // Innsbruck Messe/Zeughaus
    
    var stationIdFrom: String { return "476640200" } // Innsbruck Kochstraße
    
    var stationIdTo: String { return "476167900" } // Innsbruck Messe/Zeughaus
    
    var invalidStationId: String { return "999999" }
    
    var suggestLocations: String { return "Kochstraße" }
    
    var suggestLocationsIncomplete: String { return "kochs" } // Kochstraße
    
    var suggestLocationsUmlaut: String { return "Mühlauer Brücke" }
    
    var suggestLocationsAddress: String { return "Falkstraße 26, 6020 Innsbruck" }
    
}
