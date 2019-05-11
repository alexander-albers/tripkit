import Foundation
@testable import TripKit

class WienProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .WIEN }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return WienProvider()
    }
    
    var coordinatesFrom: LocationPoint { return LocationPoint(lat: 48180281, lon: 16333551) } //
    
    var coordinatesTo: LocationPoint { return LocationPoint(lat: 48240452, lon: 16444788) } //
    
    var stationIdFrom: String { return "60200657" } // Wien Karlsplatz
    
    var stationIdTo: String { return "60201094" } // Wien Resselgasse
    
    var invalidStationId: String { return "999999" }
    
    var suggestLocations: String { return "Karlsplatz" }
    
    var suggestLocationsIncomplete: String { return "Resse" } // Resselgasse
    
    var suggestLocationsUmlaut: String { return "Längenfeldgasse U" }
    
    var suggestLocationsAddress: String { return "Wien, Grünangergasse 1" }
    
    var supportsRefreshTrip: Bool { return false }
    
    var supportsJourneyDetails: Bool { return false }
    
}
