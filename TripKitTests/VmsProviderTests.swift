import Foundation
@testable import TripKit

class VmsProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .VMS }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return VmsProvider()
    }
    
    var coordinatesFrom: LocationPoint { return LocationPoint(lat: 50831380, lon: 12922278) } // Chemnitz Zentralhaltestelle
    
    var coordinatesTo: LocationPoint { return LocationPoint(lat: 50836056, lon: 12922042) } // Chemnitz Stadthalle
    
    var stationIdFrom: String { return "36030131" } // Chemnitz Zentralhaltestelle
    
    var stationIdTo: String { return "36030522" } // Chemnitz Stadthalle
    
    var invalidStationId: String { return "999999" }
    
    var suggestLocations: String { return "Zentralhaltestelle" }
    
    var suggestLocationsIncomplete: String { return "zentralhalt" } // Zentralhaltestelle
    
    var suggestLocationsUmlaut: String { return "Küchwald" }
    
    var suggestLocationsAddress: String { return "Chemnitz, Christian-Wehner-Straße" }
    
}
