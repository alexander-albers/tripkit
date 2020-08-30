import Foundation
@testable import TripKit

class VrrProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .VRR }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return VrrProvider()
    }
    
    var coordinatesFrom: LocationPoint { return LocationPoint(lat: 50884675, lon: 6994941) } // Köln Siegstraße 30
    
    var coordinatesTo: LocationPoint { return LocationPoint(lat: 50736200, lon: 7092096) } // Bonn Berliner Platz 1
    
    var stationIdFrom: String { return "20009289" } // Essen Hauptbahnhof
    
    var stationIdTo: String { return "20009161" } // Essen Bismarckplatz
    
    var invalidStationId: String { return "999999" }
    
    var suggestLocations: String { return "Bismarckplatz" }
    
    var suggestLocationsIncomplete: String { return "kur" } //
    
    var suggestLocationsUmlaut: String { return "Bf Mülheim, Köln" }
    
    var suggestLocationsAddress: String { return "Hagen, Siegstraße 30" }
    
}
