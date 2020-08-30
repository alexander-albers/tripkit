import Foundation
@testable import TripKit

class DingProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .DING }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return DingProvider()
    }
    
    var coordinatesFrom: LocationPoint { return LocationPoint(lat: 48402033, lon: 9992871) } // Ulm Justizgebäude
    
    var coordinatesTo: LocationPoint { return LocationPoint(lat: 48401035, lon: 9987638) } // Ulm Theater
    
    var stationIdFrom: String { return "9001011" } // Ulm Justizgebäude
    
    var stationIdTo: String { return "9001010" } // Ulm Theater
    
    var invalidStationId: String { return "999999" }
    
    var suggestLocations: String { return "Theater" }
    
    var suggestLocationsIncomplete: String { return "justizgeb" } // Justizgebäude
    
    var suggestLocationsUmlaut: String { return "Justizgebäude" }
    
    var suggestLocationsAddress: String { return "Ulm, Sedelhofgasse" }
    
}
