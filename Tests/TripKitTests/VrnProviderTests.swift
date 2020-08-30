import Foundation
@testable import TripKit

class VrnProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .VRN }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return VrnProvider()
    }
    
    var coordinatesFrom: LocationPoint { return LocationPoint(lat: 49479748, lon: 8469938) } // Mannheim Hauptbahnhof
    
    var coordinatesTo: LocationPoint { return LocationPoint(lat: 49482892, lon: 8473050) } // Mannheim Kunsthalle
    
    var stationIdFrom: String { return "6002417" } // Mannheim Hauptbahnhof
    
    var stationIdTo: String { return "6005542" } // Mannheim Kunsthalle
    
    var invalidStationId: String { return "999999" }
    
    var suggestLocations: String { return "Hauptbahnhof, Mannheim" }
    
    var suggestLocationsIncomplete: String { return "kur" } //
    
    var suggestLocationsUmlaut: String { return "Käfertaler Wald" }
    
    var suggestLocationsAddress: String { return "Mannheim, Kolpingstraße 1" }
    
}
