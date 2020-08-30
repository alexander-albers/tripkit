import Foundation
@testable import TripKit

class VosProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .VOS }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return VosProvider(apiAuthorization: authorizationData.hciAuthorization, requestVerification: authorizationData.hciRequestVerification)
    }
    
    var coordinatesFrom: LocationPoint { return LocationPoint(lat: 52272633, lon: 8059746) } // Osnabrück Hauptbahnhof/ZOB
    
    var coordinatesTo: LocationPoint { return LocationPoint(lat: 52272588, lon: 8047656) } // Osnabrück Neumarkt
    
    var stationIdFrom: String { return "A=1@O=Osnabrück Hauptbahnhof/ZOB@X=8059746@Y=52272633@U=80@L=100071@" } // Osnabrück Hauptbahnhof/ZOB
    
    var stationIdTo: String { return "A=1@O=Osnabrück Neumarkt@X=8047656@Y=52272588@U=80@L=100082@" } // Osnabrück Neumarkt
    
    var invalidStationId: String { return "999999" }
    
    var suggestLocations: String { return "Stresemannplatz" }
    
    var suggestLocationsIncomplete: String { return "Stresem" } //
    
    var suggestLocationsUmlaut: String { return "Stresemannplatz" }
    
    var suggestLocationsAddress: String { return "Osnabrück, Eisenbahnstraße 1" }
    
}
