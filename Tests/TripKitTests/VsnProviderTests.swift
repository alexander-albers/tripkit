import Foundation
@testable import TripKit

class VsnProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .VSN }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return VsnProvider(apiAuthorization: authorizationData.hciAuthorization, requestVerification: authorizationData.hciRequestVerification)
    }
    
    var coordinatesFrom: LocationPoint { return LocationPoint(lat: 51535086, lon: 9927102) } // Göttingen Bahnhof/ZOB
    
    var coordinatesTo: LocationPoint { return LocationPoint(lat: 51533117, lon: 9934006) } // Göttingen Markt
    
    var stationIdFrom: String { return "1101000" } // Göttingen Bahnhof/ZOB
    
    var stationIdTo: String { return "9034001" } // Göttingen Markt
    
    var invalidStationId: String { return "999999" }
    
    var suggestLocations: String { return "Dahlmannstraße" }
    
    var suggestLocationsIncomplete: String { return "Siekw" } // Siegweg
    
    var suggestLocationsUmlaut: String { return "Lönsweg" }
    
    var suggestLocationsAddress: String { return "Göttingen(Niedersachs) Humboldtallee 14" }
    
}
