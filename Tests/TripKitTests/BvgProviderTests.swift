import Foundation
@testable import TripKit

class BvgProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .BVG }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return BvgProvider(apiAuthorization: authorizationData.hciAuthorization)
    }
    
    var coordinatesFrom: LocationPoint { return LocationPoint(lat: 52536099, lon: 13426309) } // Berlin, Christburger Straße 1
    
    var coordinatesTo: LocationPoint { return LocationPoint(lat: 52486400, lon: 13350744) } // Berlin, Eisenacher Straße 70
    
    var stationIdFrom: String { return "900013103" } // Prinzenstraße
    
    var stationIdTo: String { return "900056102" } // Nollendorfplatz
    
    var invalidStationId: String { return "999999" }
    
    var suggestLocations: String { return "S+U Berlin Hauptbahnhof" }
    
    var suggestLocationsIncomplete: String { return "nol" } // Nollendorfplatz
    
    var suggestLocationsUmlaut: String { return "U Güntzelstr." }
    
    var suggestLocationsAddress: String { return "Sophienstr. 24, 10178 Berlin-Mitte" }
    
}
