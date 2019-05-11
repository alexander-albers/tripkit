import Foundation
@testable import TripKit

class VvsProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .VVS }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return VvsProvider()
    }
    
    var coordinatesFrom: LocationPoint { return LocationPoint(lat: 48782984, lon: 9179846) } // Stuttgart Hauptbahnhof
    
    var coordinatesTo: LocationPoint { return LocationPoint(lat: 48782584, lon: 9187098) } // Stuttgart Staatsgalerie
    
    var stationIdFrom: String { return "5006118" } // Stuttgart Hauptbahnhof
    
    var stationIdTo: String { return "5006024" } // Stuttgart Staatsgalerie
    
    var invalidStationId: String { return "999999" }
    
    var suggestLocations: String { return "Staatsgalerie" }
    
    var suggestLocationsIncomplete: String { return "kur" } //
    
    var suggestLocationsUmlaut: String { return "Nürtingen" }
    
    var suggestLocationsAddress: String { return "Stuttgart, Urbanstraße 20" }
    
}
