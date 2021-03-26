import Foundation
@testable import TripKit

class StvProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .STV }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return StvProvider(apiAuthorization: authorizationData.hciAuthorization)
    }
    
    var coordinatesFrom: LocationPoint { return LocationPoint(lat: 47072481, lon: 15417506) } // Graz Hauptbahnhof
    
    var coordinatesTo: LocationPoint { return LocationPoint(lat: 47073564, lon: 15420498) } // Graz Babenbergerstraße
    
    var stationIdFrom: String { return "460304000" } // Graz Hauptbahnhof
    
    var stationIdTo: String { return "460314900" } // Graz Babenbergerstraße
    
    var invalidStationId: String { return "999999" }
    
    var suggestLocations: String { return "Babenbergerstraße" }
    
    var suggestLocationsIncomplete: String { return "babenber" } // Babenbergerstraße
    
    var suggestLocationsUmlaut: String { return "Keplerbrücke" }
    
    var suggestLocationsAddress: String { return "8010 Graz, Wartingergasse 36" }
    
}
