import Foundation
@testable import TripKit

class VagfrProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .VAGFR }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return VagfrProvider()
    }
    
    var coordinatesFrom: LocationPoint { return LocationPoint(lat: 47994831, lon: 7849802) } // Freiburg Bertoldsbrunnen
    
    var coordinatesTo: LocationPoint { return LocationPoint(lat: 47997939, lon: 7852398) } // Freiburg Europaplatz
    
    var stationIdFrom: String { return "6930100" } // Freiburg Bertoldsbrunnen
    
    var stationIdTo: String { return "6930101" } // Freiburg Europaplatz
    
    var invalidStationId: String { return "999999" }
    
    var suggestLocations: String { return "Bertoldsbrunnen" }
    
    var suggestLocationsIncomplete: String { return "bertholds" } // Bertoldsbrunnen
    
    var suggestLocationsUmlaut: String { return "Elsässer Straße" }
    
    var suggestLocationsAddress: String { return "Freiburg im Breisgau, Eisenbahnstraße 68" }
    
}
