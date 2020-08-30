import Foundation
@testable import TripKit

class InvgProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .INVG }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return InvgProvider(apiAuthorization: authorizationData.hciAuthorization, requestVerification: authorizationData.hciRequestVerification)
    }
    
    var coordinatesFrom: LocationPoint { return LocationPoint(lat: 48744414, lon: 11434603) } // Ingolstadt Hbf
    
    var coordinatesTo: LocationPoint { return LocationPoint(lat: 48751558, lon: 11426546) } // Ingolstadt Nordbahnhof
    
    var stationIdFrom: String { return "61202" } // Rechbergstraße
    
    var stationIdTo: String { return "978801" } // ZOB
    
    var invalidStationId: String { return "999999" }
    
    var suggestLocations: String { return "Rathausplatz" }
    
    var suggestLocationsIncomplete: String { return "rathau" } // Rathausplatz
    
    var suggestLocationsUmlaut: String { return "Am Kreuzäcker" }
    
    var suggestLocationsAddress: String { return "Kellerstraße 1, Ingolstadt" }
    
}
