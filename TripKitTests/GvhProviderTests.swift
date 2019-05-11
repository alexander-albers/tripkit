import Foundation
@testable import TripKit

class GvhProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .GVH }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return GvhProvider()
    }
    
    var coordinatesFrom: LocationPoint { return LocationPoint(lat: 53069619, lon: 8799202) } // Bremen, Neustadtswall 12
    
    var coordinatesTo: LocationPoint { return LocationPoint(lat: 53104124, lon: 8788575) } // Bremen Glücksburger Straße 37
    
    var stationIdFrom: String { return "25000031" } // Hannover Hauptbahnhof
    
    var stationIdTo: String { return "25001141" } // Hannover Bismarckstraße
    
    var invalidStationId: String { return "999999" }
    
    var suggestLocations: String { return "Sarstedt" }
    
    var suggestLocationsIncomplete: String { return "sarste" } // Sarstedt
    
    var suggestLocationsUmlaut: String { return "Büttnerstraße" }
    
    var suggestLocationsAddress: String { return "Bremen, Glücksburger Straße 37" }
    
}
