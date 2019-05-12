import Foundation
@testable import TripKit

class VvoProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .VVO }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return VvoProvider()
    }
    
    var coordinatesFrom: LocationPoint { return LocationPoint(lat: 51052260, lon: 13740998) } // Dresden, Töpferstraße 10
    
    var coordinatesTo: LocationPoint { return LocationPoint(lat: 51029752, lon: 13700666) } // Dresden, Tharandter Straße 88
    
    var stationIdFrom: String { return "33000013" } // Dresden Albertplatz
    
    var stationIdTo: String { return "33000262" } // Dresden Bischofsweg
    
    var invalidStationId: String { return "999999" }
    
    var suggestLocations: String { return "Postplatz" }
    
    var suggestLocationsIncomplete: String { return "Kur" } //
    
    var suggestLocationsUmlaut: String { return "Hülßestraße" }
    
    var suggestLocationsAddress: String { return "Dresden, Töpferstraße 10" }
    
}
