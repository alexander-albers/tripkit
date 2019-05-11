import Foundation
@testable import TripKit

class BayernProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .BAYERN }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return BayernProvider()
    }
    
    var coordinatesFrom: LocationPoint { return LocationPoint(lat: 48127882, lon: 11604273) } // München Ostbahnhof
    
    var coordinatesTo: LocationPoint { return LocationPoint(lat: 48140492, lon: 11452831) } // München Pasing
    
    var stationIdFrom: String { return "91000892" } // München Ostbahnhof
    
    var stationIdTo: String { return "91000010" } // München Pasing
    
    var invalidStationId: String { return "999999" }
    
    var suggestLocations: String { return "Regensburg Hbf" }
    
    var suggestLocationsIncomplete: String { return "Marien" } // Marienplatz
    
    var suggestLocationsUmlaut: String { return "Mühldorfstraße" }
    
    var suggestLocationsAddress: String { return "Friedenstraße 2, München" }
    
    var supportsQueryMoreTrips: Bool { return false }
    
    var supportsJourneyDetails: Bool { return false }
    
}
