import Foundation
@testable import TripKit

class AvvAachenProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .AVV2 }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        print("HCIKEYS: \(authorizationData.hciAuthorization.keys)")
        return AvvAachenProvider(apiAuthorization: authorizationData.hciAuthorization)
    }
    
    var coordinatesFrom: LocationPoint { return LocationPoint(lat: 50767803, lon: 6091504) } // Aachen Hbf
    
    var coordinatesTo: LocationPoint { return LocationPoint(lat: 50769870, lon: 6073840) } // Aachen Schanz
    
    var stationIdFrom: String { return "1008" } // Aachen Hbf
    
    var stationIdTo: String { return "1016" } // Aachen Schanz
    
    var invalidStationId: String { return "999999" }
    
    var suggestLocations: String { return "Hbf, Aachen" }
    
    var suggestLocationsIncomplete: String { return "scha" } // Schanz
    
    var suggestLocationsUmlaut: String { return "Gaßmühle" }
    
    var suggestLocationsAddress: String { return "Theaterstraße 49, Aachen" }
    
}
