import Foundation
@testable import TripKit

class LinzProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .LINZ }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return LinzProvider()
    }
    
    var coordinatesFrom: LocationPoint { return LocationPoint(lat: 48290966, lon: 14291716) } // Linz Hauptbahnhof
    
    var coordinatesTo: LocationPoint { return LocationPoint(lat: 48248826, lon: 14308240) } // Linz Auwiesen
    
    var stationIdFrom: String { return "60501720" } // Linz Hauptbahnhof
    
    var stationIdTo: String { return "60501810" } // Linz Auwiesen
    
    var invalidStationId: String { return "999999" }
    
    var suggestLocations: String { return "Auwiesen" }
    
    var suggestLocationsIncomplete: String { return "auwie" } // Auwiesen
    
    var suggestLocationsUmlaut: String { return "Dürerstraße" }
    
    var suggestLocationsAddress: String { return "Linz/Donau, Figulystraße 12" }
    
}
