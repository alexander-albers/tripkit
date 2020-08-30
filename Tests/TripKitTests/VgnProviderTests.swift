import Foundation
@testable import TripKit

class VgnProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .VGN }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return VgnProvider(apiBase: authorizationData.apiBase)
    }
    
    var coordinatesFrom: LocationPoint { return LocationPoint(lat: 49527298, lon: 10836204) } // Veilchenweg Puschendorf
    
    var coordinatesTo: LocationPoint { return LocationPoint(lat: 49468692, lon: 11125334) } // Nürnberg Grundschule Grimmstr.
    
    var stationIdFrom: String { return "451" } // Nürnberg Ostring
    
    var stationIdTo: String { return "510" } // Nürnberg Hauptbahnhof
    
    var invalidStationId: String { return "999999" }
    
    var suggestLocations: String { return "Ostring" }
    
    var suggestLocationsIncomplete: String { return "Kur" } //
    
    var suggestLocationsUmlaut: String { return "Röthenbach" }
    
    var suggestLocationsAddress: String { return "Nürnberg, Wodanstraße 25" }
    
}
