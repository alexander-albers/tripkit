import Foundation
@testable import TripKit

class VgsProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .VGS }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return VgsProvider(apiAuthorization: authorizationData.hciAuthorization)
    }
    
    var coordinatesFrom: LocationPoint { return LocationPoint(lat: 49239313, lon: 6992942) } // Saarbrücken Hauptbahnhof
    
    var coordinatesTo: LocationPoint { return LocationPoint(lat: 49230593, lon: 7020485) } // Saarbrücken Ostbahnhof
    
    var stationIdFrom: String { return "10640" } // Saarbrücken Hauptbahnhof
    
    var stationIdTo: String { return "10700" } // Saarbrücken Ostbahnhof
    
    var invalidStationId: String { return "999999" }
    
    var suggestLocations: String { return "Johanneskirche" }
    
    var suggestLocationsIncomplete: String { return "johann" } // Johanneskirche
    
    var suggestLocationsUmlaut: String { return "Alte Brücke" }
    
    var suggestLocationsAddress: String { return "Reichsstraße 5, Saarbrücken - Sankt Johann" }
    
}
