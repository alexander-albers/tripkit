import Foundation
@testable import TripKit

class VvvProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .VVV }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return VvvProvider()
    }
    
    var coordinatesFrom: LocationPoint { return LocationPoint(lat: 50484564, lon: 12140028) } // Plauen (Vogtl) Bickelstraße
    
    var coordinatesTo: LocationPoint { return LocationPoint(lat: 50487332, lon: 12139050) } // Plauen (Vogtl) Hofer Straße
    
    var stationIdFrom: String { return "30202006" } // Plauen (Vogtl) Bickelstraße
    
    var stationIdTo: String { return "30202012" } // Plauen (Vogtl) Hofer Straße
    
    var invalidStationId: String { return "999999" }
    
    var suggestLocations: String { return "Bickelstraße" }
    
    var suggestLocationsIncomplete: String { return "grün" } //
    
    var suggestLocationsUmlaut: String { return "Südinsel" }
    
    var suggestLocationsAddress: String { return "Plauen (Vogtl), Haselbrunner Straße 64" }
    
}
