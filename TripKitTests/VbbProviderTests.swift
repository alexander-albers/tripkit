import Foundation
@testable import TripKit

class VbbProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .VBB }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return VbbProvider(apiAuthorization: authorizationData.hciAuthorization, requestVerification: authorizationData.hciRequestVerification)
    }
    
    var coordinatesFrom: LocationPoint { return LocationPoint(lat: 52479663, lon: 13324278) } // U Kurfürsterstr.
    
    var coordinatesTo: LocationPoint { return LocationPoint(lat: 52541536, lon: 13421290) } // S+U Wuhletal
    
    var stationIdFrom: String { return "900056102" } // Nollendorfplatz
    
    var stationIdTo: String { return "900013103" } // Prinzenstraße
    
    var invalidStationId: String { return "999999" }
    
    var suggestLocations: String { return "S+U Berlin Hauptbahnhof" }
    
    var suggestLocationsIncomplete: String { return "nol" } // Nollendorfplatz
    
    var suggestLocationsUmlaut: String { return "U Güntzelstr." }
    
    var suggestLocationsAddress: String { return "Sophienstr. 24, 10178 Berlin-Mitte" }
    
}
