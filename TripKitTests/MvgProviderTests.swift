import Foundation
@testable import TripKit

class MvgProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .MVG }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return MvgProvider()
    }
    
    var coordinatesFrom: LocationPoint { return LocationPoint(lat: 51219781, lon: 7628682) } // Lüd. Bahnhof
    
    var coordinatesTo: LocationPoint { return LocationPoint(lat: 51220889, lon: 7625699) } // Lüd., Friedrichstr.
    
    var stationIdFrom: String { return "24200006" } // Lüd. Bahnhof
    
    var stationIdTo: String { return "24200032" } // Lüd., Friedrichstr.
    
    var invalidStationId: String { return "999999" }
    
    var suggestLocations: String { return "Rathaus, Iserlohn" }
    
    var suggestLocationsIncomplete: String { return "kur" } // Kurbezirk
    
    var suggestLocationsUmlaut: String { return "Schützenhalle" }
    
    var suggestLocationsAddress: String { return "Lüdenscheid, Bahnhofstraße 64" }
    
    var supportsQueryMoreTrips: Bool { return false }
    
    var supportsRefreshTrip: Bool { return false }
    
}
