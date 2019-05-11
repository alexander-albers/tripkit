import Foundation
@testable import TripKit

class MvvProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .MVV }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return MvvProvider()
    }
    
    var coordinatesFrom: LocationPoint { return LocationPoint(lat: 48165238, lon: 11577473) } //
    
    var coordinatesTo: LocationPoint { return LocationPoint(lat: 47987199, lon: 11326532) } //
    
    var stationIdFrom: String { return "2" } // Marienplatz
    
    var stationIdTo: String { return "10" } // Pasing
    
    var invalidStationId: String { return "999999" }
    
    var suggestLocations: String { return "Hirschgarten" }
    
    var suggestLocationsIncomplete: String { return "Marien" } // Marienplatz
    
    var suggestLocationsUmlaut: String { return "Grüntal" }
    
    var suggestLocationsAddress: String { return "München, Maximilianstraße 1" }
    
    // TODO: support both
    var supportsRefreshTrip: Bool { return false }
    var supportsQueryMoreTrips: Bool { return false }
    
}
