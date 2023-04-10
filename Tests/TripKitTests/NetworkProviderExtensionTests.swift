//

import Foundation
import os.log
@testable import TripKit
import XCTest

class NetworkProviderExtensionTests: XCTestCase {
    func testMinQueryTrips() {
        let expectation = self.expectation(description: "Network Task")
        
        let provider = KvvProvider()
        let minNumTrips = 12
        provider.queryTrips(from: Location(id: "7001011"), via: nil, to: Location(id: "7001002"), date: Date(), departure: true, minNumTrips: minNumTrips, tripOptions: TripOptions()) { result in
            switch result {
            case .success(_, _, _, _, let trips, _):
                os_log("%@", trips)
                XCTAssert(trips.count >= minNumTrips)
            default:
                XCTFail()
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 30, handler: nil)
    }
    
    func testMinQueryDepartures() {
        let expectation = self.expectation(description: "Network Task")
        
        let provider = KvvProvider()
        let minNumDepartures = 12
        provider.queryDepartures(stationId: "7001002", departures: true, time: nil, minDepartures: minNumDepartures, maxDepartures: 6, equivs: false) { result in
            switch result {
            case .success(let departures):
                os_log("%@", departures)
                XCTAssert(departures.flatMap({$0.departures}).count >= minNumDepartures)
            default:
                XCTFail()
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 30, handler: nil)
    }
}
