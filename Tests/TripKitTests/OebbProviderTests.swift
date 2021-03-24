import Foundation
@testable import TripKit
import os.log
import XCTest

class OebbProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .OEBB }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return OebbProvider(apiAuthorization: authorizationData.hciAuthorization)
    }
    
    var coordinatesFrom: LocationPoint { return LocationPoint(lat: 48185010, lon: 16377855) } // Wien Hauptbahnhof
    
    var coordinatesTo: LocationPoint { return LocationPoint(lat: 48217428, lon: 16372377) } // Wien Schottenring
    
    var stationIdFrom: String { return "1390163" } // Wien Schottenring
    
    var stationIdTo: String { return "1140101" } // Linz
    
    var invalidStationId: String { return "999999" }
    
    var suggestLocations: String { return "Schottenring" }
    
    var suggestLocationsIncomplete: String { return "Roß" } // Roßauer Lände
    
    var suggestLocationsUmlaut: String { return "Börse" }
    
    var suggestLocationsAddress: String { return "Grünangergasse 1, Wiener Neustadt" }

    func testLineFullNumber() {
        let result = syncQueryTrips(from: Location(id: "5600582"),  // Bratislava-Petrzalka
                                    via: nil,
                                    to: Location(id: "8101051"),    // Hbf, Wien
                                    date: Date(timeIntervalSince1970: 1609191510),
                                    departure: true,
                                    products: nil,
                                    optimize: nil,
                                    walkSpeed: nil,
                                    accessibility: nil,
                                    options: nil)

        switch result {
        case .success(_, _, _, _, let trips, let messages):
            os_log("success: %@, messages=%@", log: .testsLogger, type: .default, trips, messages)
            XCTAssert(!trips.isEmpty, "received empty result")

            if let trip = trips.first {
                if let leg = trip.legs.first as? PublicLeg {
                    XCTAssertNotNil(leg.line.trainNumber, "trainNumber must be not be nil")
                }
            }
        case .failure(let error):
            XCTFail("received an error: \(error)")
        default:
            XCTFail("illegal result type \(result)")
        }
    }
    
}
