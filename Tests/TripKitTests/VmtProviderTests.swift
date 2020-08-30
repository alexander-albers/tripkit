import Foundation
@testable import TripKit

class VmtProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .VMT }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return VmtProvider(apiAuthorization: authorizationData.hciAuthorization)
    }
    
    var coordinatesFrom: LocationPoint { return LocationPoint(lat: 50926947, lon: 11586987) } //
    
    var coordinatesTo: LocationPoint { return LocationPoint(lat: 50933887, lon: 11590592) } //
    
    var stationIdFrom: String { return "153166" } // Jena, Stadtzentrum
    
    var stationIdTo: String { return "153014" } // Jena, Spittelpl.
    
    var invalidStationId: String { return "999999" }
    
    var suggestLocations: String { return "Ernst-Abbe-Platz" }
    
    var suggestLocationsIncomplete: String { return "spittel" } // Spittelplatz
    
    var suggestLocationsUmlaut: String { return "Höhle" }
    
    var suggestLocationsAddress: String { return "Holzmarkt 1, Jena" }
    
}
