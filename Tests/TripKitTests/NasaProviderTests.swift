import Foundation
@testable import TripKit

class NasaProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .NASA }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return NasaProvider(apiAuthorization: authorizationData.hciAuthorization)
    }
    
    var coordinatesFrom: LocationPoint { return LocationPoint(lat: 51346546, lon: 12383333) } // Leipzig Hbf
    
    var coordinatesTo: LocationPoint { return LocationPoint(lat: 51423340, lon: 12223423) } // Leipzig/Halle Flughafen
    
    var stationIdFrom: String { return "11063" } // Leipzig Johannisplatz
    
    var stationIdTo: String { return "8010205" } // Leipzig Hbf
    
    var invalidStationId: String { return "999999" }
    
    var suggestLocations: String { return "Johannisplatz" }
    
    var suggestLocationsIncomplete: String { return "johannis" } // Johannisplatz
    
    var suggestLocationsUmlaut: String { return "S-Bahnhof Möckern" }
    
    var suggestLocationsAddress: String { return "Georg-Schumann-Straße 1, Leipzig - Zentrum" }
    
}
