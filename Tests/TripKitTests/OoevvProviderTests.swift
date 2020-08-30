import Foundation
@testable import TripKit

class OoevvProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .OOEVV }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return OoevvProvider(apiAuthorization: authorizationData.hciAuthorization, requestVerification: authorizationData.hciRequestVerification)
    }
    
    var coordinatesFrom: LocationPoint { return LocationPoint(lat: 48207998, lon: 16371496) } // Wien Stephansplatz
    
    var coordinatesTo: LocationPoint { return LocationPoint(lat: 48206875, lon: 16379254) } // Wien Stubentor
    
    var stationIdFrom: String { return "490132000" } // Wien Stephansplatz
    
    var stationIdTo: String { return "490024500" } // Wien Stubentor
    
    var invalidStationId: String { return "999999" }
    
    var suggestLocations: String { return "Salzburg Merianstraße" }
    
    var suggestLocationsIncomplete: String { return "Merian" } // Merianstraße
    
    var suggestLocationsUmlaut: String { return "Wien Schönbrunn" }
    
    var suggestLocationsAddress: String { return "6800 Feldkirch, Mutterstraße 4" }
    
}
