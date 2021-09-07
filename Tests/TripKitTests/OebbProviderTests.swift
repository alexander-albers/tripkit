import Foundation
import TestsCommon
@testable import TripKit
import os.log
import XCTest

class OebbProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .OEBB }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return OebbProvider(apiAuthorization: authorizationData.hciAuthorization)
    }
    
    func testLineFullNumber() {
        let (_, result) = syncQueryTrips(from: Location(id: "5600582"),  // Bratislava-Petrzalka
                                    via: nil,
                                    to: Location(id: "8101051"),    // Hbf, Wien
                                    date: Date(),
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
                    XCTAssertNotNil(leg.line.vehicleNumber, "vehicleNumber must be not be nil")
                }
            }
        case .failure(let error):
            XCTFail("received an error: \(error)")
        default:
            XCTFail("illegal result type \(result)")
        }
    }
    
}
