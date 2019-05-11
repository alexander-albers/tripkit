import Foundation
@testable import TripKit

class SbbProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .SBB }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return SbbProvider()
    }
    
    var coordinatesFrom: LocationPoint { return LocationPoint(lat: 46689354, lon: 7683444) } // Spiez, Seestraße 62
    
    var coordinatesTo: LocationPoint { return LocationPoint(lat: 47133169, lon: 8767425) } // Einsiedeln, Erlenmoosweg 24
    
    var stationIdFrom: String { return "8500010" } // Basel SBB
    
    var stationIdTo: String { return "8507785" } // Bern, Hauptbahnhof
    
    var invalidStationId: String { return "999999" }
    
    var suggestLocations: String { return "Bern, Hauptbahnhof" }
    
    var suggestLocationsIncomplete: String { return "haupt" } // Hauptbahnhof
    
    var suggestLocationsUmlaut: String { return "Neumühle" }
    
    var suggestLocationsAddress: String { return "Erlenmoosweg 24, 8840 Einsiedeln" }
    
}
