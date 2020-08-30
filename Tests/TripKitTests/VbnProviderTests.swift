import Foundation
@testable import TripKit

class VbnProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .VBN }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return VbnProvider(apiAuthorization: authorizationData.hciAuthorization)
    }
    
    var coordinatesFrom: LocationPoint { return LocationPoint(lat: 53086421, lon: 8806388) } // Oldenburg
    
    var coordinatesTo: LocationPoint { return LocationPoint(lat: 51536614, lon: 9925673) } // Bremerhaven
    
    var stationIdFrom: String { return "708425" } // Rostock lange straße
    
    var stationIdTo: String { return "625398" } // Bremerhaven
    
    var invalidStationId: String { return "999999" }
    
    var suggestLocations: String { return "Bremerhaven Hbf" }
    
    var suggestLocationsIncomplete: String { return "bremer" } // Bremerhaven
    
    var suggestLocationsUmlaut: String { return "Göttingen Bahnhof/ZOB" }
    
    var suggestLocationsAddress: String { return "Lange Straße 1, Rostock - Stadtmitte" }
    
}
