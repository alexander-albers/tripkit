import Foundation
@testable import TripKit

class VblProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .VBL }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return VblProvider()
    }
    
    var coordinatesFrom: LocationPoint { return LocationPoint(lat: 47050164, lon: 8310352) } // Luzern Bahnhof
    
    var coordinatesTo: LocationPoint { return LocationPoint(lat: 47048564, lon: 8306016) } // Luzern Kantonalbank
    
    var stationIdFrom: String { return "53020041" } // Luzern Bahnhof
    
    var stationIdTo: String { return "53028841" } // Luzern Kantonalbank
    
    var invalidStationId: String { return "999999" }
    
    var suggestLocations: String { return "Friedbergstrasse" }
    
    var suggestLocationsIncomplete: String { return "friedb" } // Friedbergstrasse
    
    var suggestLocationsUmlaut: String { return "Gütsch" }
    
    var suggestLocationsAddress: String { return "Luzern, Seidenhofstrasse 1" }
    
}
