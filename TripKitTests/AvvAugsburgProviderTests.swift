import Foundation
@testable import TripKit

class AvvAugsburgProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .AVV }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return AvvAugsburgProvider()
    }
    
    var coordinatesFrom: LocationPoint { return LocationPoint(lat: 48366450, lon: 10892661) } // Augsburg Königsplatz
    
    var coordinatesTo: LocationPoint { return LocationPoint(lat: 48365854, lon: 10884123) } // Augsburg Hauptbahnhof
    
    var stationIdFrom: String { return "101" } // Augsburg Königsplatz
    
    var stationIdTo: String { return "100" } // Augsburg Hauptbahnhof
    
    var invalidStationId: String { return "999999" }
    
    var suggestLocations: String { return "Augsburg, Hbf" }
    
    var suggestLocationsIncomplete: String { return "Königspl" }
    
    var suggestLocationsUmlaut: String { return "Gärtnerstraße" }
    
    var suggestLocationsAddress: String { return "Augsburg, Bahnhofstraße 11" }
    
}
