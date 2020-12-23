import XCTest
@testable import TripKit
import os.log

class RmvProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .RMV }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return RmvProvider(apiAuthorization: authorizationData.hciAuthorization)
    }
    
    var coordinatesFrom: LocationPoint { return LocationPoint(lat: 50069485, lon: 8244636) } // Wiesbaden Hauptbahnhof
    
    var coordinatesTo: LocationPoint { return LocationPoint(lat: 50107167, lon: 8662509) } // Frankfurt (Main) Hauptbahnhof tief
    
    var stationIdFrom: String { return "3006907" } // Wiesbaden Hauptbahnhof
    
    var stationIdTo: String { return "3007010" } // Frankfurt (Main) Hauptbahnhof tief
    
    var invalidStationId: String { return "999999" }
    
    var suggestLocations: String { return "Willy-Brandt-Platz" }
    
    var suggestLocationsIncomplete: String { return "willy" } // Willy-Brandt-Platz
    
    var suggestLocationsUmlaut: String { return "Grüneburgweg" }
    
    var suggestLocationsAddress: String { return "Kaiserstraße 30, Frankfurt am Main - Innenstadt" }
    
    func testQueryTripsChineeseCharacters() {
        let from = Location(type: .coord, id: nil, coord: LocationPoint(lat: 49867186, lon: 8640047), place: "达姆施塔特", name: "Schöfferstraße 2")!
        let to = Location(type: .coord, id: nil, coord: LocationPoint(lat: 49856719, lon: 8637645), place: "64295 达姆施塔特, 德国", name: "Wormser Straße 32")!
        let result = syncQueryTrips(from: from, via: nil, to: to, date: Date(), departure: true, products: nil, optimize: nil, walkSpeed: nil, accessibility: nil, options: nil)
        switch result {
        case .success(let context, _, _, _, let trips, let messages):
            os_log("success: %@, context=%@, messages=%@", log: .testsLogger, type: .default, trips, String(describing: context), messages)
            XCTAssert(!trips.isEmpty, "received empty result")
            if delegate.supportsQueryMoreTrips {
                XCTAssert(context != nil, "context == nil")
            }
            
        case .failure(let error):
            XCTFail("received an error: \(error)")
        default:
            XCTFail("illegal result type \(result)")
        }
    }
    
}
