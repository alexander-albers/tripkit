import Foundation
@testable import TripKit

class VmvProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .VMV }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return VmvProvider()
    }
    
    var coordinatesFrom: LocationPoint { return LocationPoint(lat: 53634388, lon: 11405774) } // Schwerin Hauptbahnhof
    
    var coordinatesTo: LocationPoint { return LocationPoint(lat: 53656658, lon: 11367353) } // Schwerin-Lankow
    
    var stationIdFrom: String { return "44409005" } // Schwerin Hauptbahnhof
    
    var stationIdTo: String { return "44402013" } // Schwerin Kieler Str.
    
    var invalidStationId: String { return "999999" }
    
    var suggestLocations: String { return "Kieler Str." }
    
    var suggestLocationsIncomplete: String { return "marien" } // Marienplatz
    
    var suggestLocationsUmlaut: String { return "Büdnerstraße" }
    
    var suggestLocationsAddress: String { return "Schwerin, Lübecker Straße 142" }
    
}
