import Foundation
@testable import TripKit

class NvbwProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .NVBW }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return NvbwProvider()
    }
    
    var coordinatesFrom: LocationPoint { return LocationPoint(lat: 48492484, lon: 9207456) } // Reutlingen ZOB
    
    var coordinatesTo: LocationPoint { return LocationPoint(lat: 48496968, lon: 9213320) } // Reutlingen Bismarckstr.
    
    var stationIdFrom: String { return "8029333" } // Reutlingen ZOB
    
    var stationIdTo: String { return "8029109" } // Reutlingen Bismarckstr.
    
    var invalidStationId: String { return "999999" }
    
    var suggestLocations: String { return "Hauptbahnhof, Freiburg im Breisgau" }
    
    var suggestLocationsIncomplete: String { return "bismarck" } // Bismarckstr
    
    var suggestLocationsUmlaut: String { return "Grünwinkel" }
    
    var suggestLocationsAddress: String { return "Stuttgart, Kronenstraße 3" }
    
}
