import Foundation
@testable import TripKit

class HvvProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .HVV }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return HvvProvider(apiAuthorization: authorizationData.hciAuthorization, requestVerification: authorizationData.hciRequestVerification)
    }
    
    var coordinatesFrom: LocationPoint { return LocationPoint(lat: 53552924, lon: 10004416) } // Hamburg Hauptbahnhof
    
    var coordinatesTo: LocationPoint { return LocationPoint(lat: 53567591, lon: 9967937) } // Hamburg Schlump
    
    var stationIdFrom: String { return "84" } // Hamburg Hauptbahnhof
    
    var stationIdTo: String { return "6618" } // Hamburg Schlump
    
    var invalidStationId: String { return "999999" }
    
    var suggestLocations: String { return "Hauptbahnhof" }
    
    var suggestLocationsIncomplete: String { return "hbf" } //
    
    var suggestLocationsUmlaut: String { return "Gänsemarkt (Oper)" }
    
    var suggestLocationsAddress: String { return "Bogenstraße 29, Hamburg" }
    
}
