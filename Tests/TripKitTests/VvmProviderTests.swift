import Foundation
@testable import TripKit

class VvmProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .VVM }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return VvmProvider()
    }
    
    var coordinatesFrom: LocationPoint { return LocationPoint(lat: 49801518, lon: 9933517) } // Würzburg Hauptbahnhof
    
    var coordinatesTo: LocationPoint { return LocationPoint(lat: 49797772, lon: 9934986) } // Stift Haug
    
    var stationIdFrom: String { return "80001152" } // Würzburg Hauptbahnhof
    
    var stationIdTo: String { return "80029085" } // Würzburg Paradiesstraße
    
    var invalidStationId: String { return "999999" }
    
    var suggestLocations: String { return "Paradiesstraße" }
    
    var suggestLocationsIncomplete: String { return "paradie" } // Paradiesstraße
    
    var suggestLocationsUmlaut: String { return "Klosterlechfeld, Südstraße" }
    
    var suggestLocationsAddress: String { return "Heidenheim, Bahnhofplatz 5" }
    
}
