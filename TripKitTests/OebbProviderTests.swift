import Foundation
@testable import TripKit

class OebbProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .OEBB }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return OebbProvider(apiAuthorization: authorizationData.hciAuthorization)
    }
    
    var coordinatesFrom: LocationPoint { return LocationPoint(lat: 48185010, lon: 16377855) } // Wien Hauptbahnhof
    
    var coordinatesTo: LocationPoint { return LocationPoint(lat: 48217428, lon: 16372377) } // Wien Schottenring
    
    var stationIdFrom: String { return "1390163" } // Wien Schottenring
    
    var stationIdTo: String { return "1140101" } // Linz
    
    var invalidStationId: String { return "999999" }
    
    var suggestLocations: String { return "Schottenring" }
    
    var suggestLocationsIncomplete: String { return "Roß" } // Roßauer Lände
    
    var suggestLocationsUmlaut: String { return "Börse" }
    
    var suggestLocationsAddress: String { return "Grünangergasse 1, Wiener Neustadt" }
    
}
