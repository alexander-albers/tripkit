import XCTest
@testable import TripKit
import os.log

class TripKitProviderTestCase: XCTestCase {
    
    private var provider: NetworkProvider!
    private var secrets: [NetworkId: AuthorizationData] = [:]
    
    var delegate: TripKitProviderTestsDelegate! { return nil }
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = true
        
        secrets = SecretsLoader.loadSecrets()
        provider = delegate.initProvider(from: secrets[delegate.networkId] ?? AuthorizationData())
    }

    // MARK: tests
    
    func testSuggestLocations() {
        let result = syncSuggestLocations(constraint: delegate.suggestLocations)
        switch result {
        case .success(let locations):
            os_log("success: %@", log: .testsLogger, type: .default, locations)
            XCTAssert(!locations.isEmpty, "received empty result")
            XCTAssert(locations.contains(where: {$0.location.getUniqueShortName().lowercased() == delegate.suggestLocations.lowercased() || $0.location.getUniqueLongName().lowercased() == delegate.suggestLocations.lowercased()}), "result does not contain the searched location")
        case .failure(let error):
            XCTFail("received an error: \(error)")
        }
    }
    
    func testSuggestLocationsIncomplete() {
        let result = syncSuggestLocations(constraint: delegate.suggestLocationsIncomplete)
        switch result {
        case .success(let locations):
            os_log("success: %@", log: .testsLogger, type: .default, locations)
            XCTAssert(!locations.isEmpty, "received empty result")
            XCTAssert(locations.contains(where: {$0.location.getUniqueShortName().lowercased().contains(delegate.suggestLocationsIncomplete.lowercased())}), "result does not contain the searched location")
        case .failure(let error):
            XCTFail("received an error: \(error)")
        }
    }
    
    func testSuggestLocationsUmlaut() {
        let result = syncSuggestLocations(constraint: delegate.suggestLocationsUmlaut)
        switch result {
        case .success(let locations):
            os_log("success: %@", log: .testsLogger, type: .default, locations)
            XCTAssert(!locations.isEmpty, "received empty result")
            XCTAssert(locations.contains(where: {$0.location.getUniqueShortName().lowercased() == delegate.suggestLocationsUmlaut.lowercased() || $0.location.getUniqueLongName().lowercased() == delegate.suggestLocationsUmlaut.lowercased()}), "result does not contain the searched location")
        case .failure(let error):
            XCTFail("received an error: \(error)")
        }
    }
    
    func testSuggestLocationsAddress() {
        if delegate.suggestLocationsAddress.isEmpty { return }
        let result = syncSuggestLocations(constraint: delegate.suggestLocationsAddress)
        switch result {
        case .success(let locations):
            os_log("success: %@", log: .testsLogger, type: .default, locations.map({$0.location.getUniqueLongName()}))
            XCTAssert(!locations.isEmpty, "received empty result")
            XCTAssert(locations.contains(where: {$0.location.getUniqueLongName().lowercased() == delegate.suggestLocationsAddress.lowercased() && $0.location.type == .address}), "result does not contain the searched location")
        case .failure(let error):
            XCTFail("received an error: \(error)")
        }
    }
    
    func testNearbyStationByCoordinate() {
        let result = syncNearbyStations(location: Location(lat: delegate.coordinatesFrom.lat, lon: delegate.coordinatesFrom.lon), types: [.station], maxDistance: 0, maxLocations: 5)
        switch result {
        case .success(let locations):
            os_log("success: %@", log: .testsLogger, type: .default, locations)
            XCTAssert(!locations.isEmpty, "received empty result")
        case .invalidId:
            XCTFail("received invalid id")
        case .failure(let error):
            XCTFail("received an error: \(error)")
        }
    }
    
    func testQueryDepartures() {
        let result = syncQueryDepartures(stationId: delegate.stationIdFrom, time: Date(), maxDepartures: 5, equivs: false)
        switch result {
        case .success(let departures, let desktopUrl):
            os_log("success: %@, desktopUrl=%@", log: .testsLogger, type: .default, departures, desktopUrl?.absoluteString ?? "")
            XCTAssert(!departures.isEmpty, "received empty result")
            if let first = departures.first {
                XCTAssert(!first.departures.isEmpty, "received empty result")
            }
            
            if let first = departures.first?.departures.first, delegate.supportsJourneyDetails {
                XCTAssert(first.journeyContext != nil, "journeyContext == nil")
                
                if let context = first.journeyContext {
                    let result = syncJourneyDetail(context: context)
                    switch result {
                    case .success(_, let leg):
                        os_log("success: %@", log: .testsLogger, type: .default, leg)
                    case .invalidId:
                        XCTFail("received invalid journey id")
                    case .failure(let error):
                        XCTFail("received an error: \(error)")
                    }
                }
            }
        case .invalidStation:
            XCTFail("received invalid id")
        case .failure(let error):
            XCTFail("received an error: \(error)")
        }
    }
    
    func testQueryDeparturesEquivs() {
        let result = syncQueryDepartures(stationId: delegate.stationIdFrom, time: Date(), maxDepartures: 5, equivs: false)
        switch result {
        case .success(let departures, let desktopUrl):
            os_log("success: %@, desktopUrl=%@", log: .testsLogger, type: .default, departures, desktopUrl?.absoluteString ?? "")
            XCTAssert(!departures.isEmpty, "received empty result")
            if let first = departures.first {
                XCTAssert(!first.departures.isEmpty, "received empty result")
            }
        case .invalidStation:
            XCTFail("received invalid id")
        case .failure(let error):
            XCTFail("received an error: \(error)")
        }
    }
    
    func testQueryDeparturesInvalid() {
        let result = syncQueryDepartures(stationId: delegate.invalidStationId, time: Date(), maxDepartures: 1, equivs: false)
        switch result {
        case .success(_, _):
            XCTFail("illegal result type success")
        case .invalidStation:
            break
        case .failure(let error):
            XCTFail("received an error: \(error)")
        }
    }
    
    func testQueryTrips() {
        let result = syncQueryTrips(from: Location(id: delegate.stationIdFrom), via: nil, to: Location(id: delegate.stationIdTo), date: Date(), departure: true, products: nil, optimize: nil, walkSpeed: nil, accessibility: nil, options: nil)
        var queryMoreContext: QueryTripsContext?
        switch result {
        case .success(let context, _, _, _, let trips, let messages):
            os_log("success: %@, context=%@, messages=%@", log: .testsLogger, type: .default, trips, String(describing: context), messages)
            XCTAssert(!trips.isEmpty, "received empty result")
            if delegate.supportsQueryMoreTrips {
                XCTAssert(context != nil, "context == nil")
            }
            queryMoreContext = context
            
            if let first = trips.first, let context = first.refreshContext, delegate.supportsRefreshTrip {
                let result = syncRefreshTrip(context: context)
                switch result {
                case .success(let context, _, _, _, let trips, let messages):
                    os_log("success: %@, context=%@, messages=%@", log: .testsLogger, type: .default, trips, String(describing: context), messages)
                    XCTAssert(!trips.isEmpty, "received empty result")
                case .failure(let error):
                    XCTFail("received an error: \(error)")
                default:
                    XCTFail("illegal result type \(result)")
                }
            }
        case .failure(let error):
            XCTFail("received an error: \(error)")
        default:
            XCTFail("illegal result type \(result)")
        }
        guard let queryMoreContext1 = queryMoreContext, delegate.supportsQueryMoreTrips else { return }
        queryMoreContext = nil
        let resultLater = syncQueryMoreTrips(context: queryMoreContext1, later: true)
        switch resultLater {
        case .success(let context, _, _, _, let trips, let messages):
            os_log("success: %@, context=%@, messages=%@", log: .testsLogger, type: .default, trips, String(describing: context), messages)
            XCTAssert(!trips.isEmpty, "received empty result")
            XCTAssert(context != nil, "context == nil")
            queryMoreContext = context
        case .failure(let error):
            XCTFail("received an error: \(error)")
        default:
            XCTFail("illegal result type \(resultLater)")
        }
        
        guard let queryMoreContext2 = queryMoreContext else { return }
        queryMoreContext = nil
        let resultEarlier = syncQueryMoreTrips(context: queryMoreContext2, later: true)
        switch resultEarlier {
        case .success(let context, _, _, _, let trips, let messages):
            os_log("success: %@, context=%@, messages=%@", log: .testsLogger, type: .default, trips, String(describing: context), messages)
            XCTAssert(!trips.isEmpty, "received empty result")
            XCTAssert(context != nil, "context == nil")
        case .failure(let error):
            XCTFail("received an error: \(error)")
        default:
            XCTFail("illegal result type \(resultEarlier)")
        }
    }
    
    func testQueryTripsBetweenCoordinates() {
        let result = syncQueryTrips(from: Location(lat: delegate.coordinatesFrom.lat, lon: delegate.coordinatesFrom.lon), via: nil, to: Location(lat: delegate.coordinatesTo.lat, lon: delegate.coordinatesTo.lon), date: Date(), departure: true, products: nil, optimize: nil, walkSpeed: nil, accessibility: nil, options: nil)
        switch result {
        case .success(let context, _, _, _, let trips, let messages):
            os_log("success: %@, context=%@, messages=%@", log: .testsLogger, type: .default, trips, String(describing: context), messages)
            XCTAssert(!trips.isEmpty, "received empty result")
            XCTAssert(context != nil, "context == nil")
        case .failure(let error):
            XCTFail("received an error: \(error)")
        default:
            XCTFail("illegal result type \(result)")
        }
    }
    
    func testTooClose() {
        let result = syncQueryTrips(from: Location(id: delegate.stationIdFrom), via: nil, to: Location(id: delegate.stationIdFrom), date: Date(), departure: true, products: nil, optimize: nil, walkSpeed: nil, accessibility: nil, options: nil)
        switch result {
        case .tooClose, .noTrips:
            break
        case .failure(let error):
            XCTFail("received an error: \(error)")
        default:
            XCTFail("illegal result type \(result)")
        }
    }
    
    // MARK: utility methods
    
    private func syncQueryTrips(from: Location, via: Location?, to: Location, date: Date, departure: Bool, products: [Product]?, optimize: Optimize?, walkSpeed: WalkSpeed?, accessibility: Accessibility?, options: [Option]?) -> QueryTripsResult {
        let expectation = self.expectation(description: "Network Task")
        var result: QueryTripsResult?
        
        _ = provider.queryTrips(from: from, via: via, to: to, date: date, departure: departure, products: products, optimize: optimize, walkSpeed: walkSpeed, accessibility: accessibility, options: options) { (completion: QueryTripsResult) in
            result = completion
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 30, handler: nil)
        XCTAssert(result != nil, "No result fetched!")
        return result ?? .failure(TimeoutError())
    }
    
    private func syncQueryMoreTrips(context: QueryTripsContext, later: Bool) -> QueryTripsResult {
        let expectation = self.expectation(description: "Network Task")
        var result: QueryTripsResult?
        
        _ = provider.queryMoreTrips(context: context, later: later) { (completion: QueryTripsResult) in
            result = completion
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 30, handler: nil)
        XCTAssert(result != nil, "No result fetched!")
        return result ?? .failure(TimeoutError())
    }
    
    private func syncRefreshTrip(context: RefreshTripContext) -> QueryTripsResult {
        let expectation = self.expectation(description: "Network Task")
        var result: QueryTripsResult?
        
        _ = provider.refreshTrip(context: context) { (completion: QueryTripsResult) in
            result = completion
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 30, handler: nil)
        XCTAssert(result != nil, "No result fetched!")
        return result ?? .failure(TimeoutError())
    }
    
    private func syncNearbyStations(location: Location, types: [LocationType], maxDistance: Int, maxLocations: Int) -> NearbyLocationsResult {
        let expectation = self.expectation(description: "Network Task")
        var result: NearbyLocationsResult?
        
        _ = provider.queryNearbyLocations(location: location, types: types, maxDistance: maxDistance, maxLocations: maxLocations) { (completion: NearbyLocationsResult) in
            result = completion
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 30, handler: nil)
        XCTAssert(result != nil, "No result fetched!")
        return result ?? .failure(TimeoutError())
    }
    
    private func syncQueryDepartures(stationId: String, time: Date?, maxDepartures: Int, equivs: Bool) -> QueryDeparturesResult {
        let expectation = self.expectation(description: "Network Task")
        var result: QueryDeparturesResult?
        
        _ = provider.queryDepartures(stationId: stationId, time: time, maxDepartures: maxDepartures, equivs: equivs) { (completion: QueryDeparturesResult) in
            result = completion
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 30, handler: nil)
        XCTAssert(result != nil, "No result fetched!")
        return result ?? .failure(TimeoutError())
    }
    
    private func syncJourneyDetail(context: QueryJourneyDetailContext) -> QueryJourneyDetailResult {
        let expectation = self.expectation(description: "Network Task")
        var result: QueryJourneyDetailResult?
        
        _ = provider.queryJourneyDetail(context: context) { (completion: QueryJourneyDetailResult) in
            result = completion
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 30, handler: nil)
        XCTAssert(result != nil, "No result fetched!")
        return result ?? .failure(TimeoutError())
    }
    
    private func syncSuggestLocations(constraint: String) -> SuggestLocationsResult {
        let expectation = self.expectation(description: "Network Task")
        var result: SuggestLocationsResult?
        
        _ = provider.suggestLocations(constraint: constraint, types: nil, maxLocations: 5) { (completion: SuggestLocationsResult) in
            result = completion
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 30, handler: nil)
        XCTAssert(result != nil, "No result fetched!")
        return result ?? .failure(TimeoutError())
    }
    
}

protocol TripKitProviderTestsDelegate {
    
    var networkId: NetworkId { get }
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider
    
    var coordinatesFrom: LocationPoint { get }
    var coordinatesTo: LocationPoint { get }
    var stationIdFrom: String { get }
    var stationIdTo: String { get }
    var invalidStationId: String { get }
    var suggestLocations: String { get }
    var suggestLocationsIncomplete: String { get }
    var suggestLocationsUmlaut: String { get }
    var suggestLocationsAddress: String { get }
    
    var supportsQueryMoreTrips: Bool { get }
    var supportsRefreshTrip: Bool { get }
    var supportsJourneyDetails: Bool { get }
}

extension TripKitProviderTestsDelegate {
    // the goal should be that all providers support the following features
    var supportsQueryMoreTrips: Bool { return true }
    var supportsRefreshTrip: Bool { return true }
    var supportsJourneyDetails: Bool { return true }
}

extension OSLog {
    static let testsLogger = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "Tests")
}

struct TimeoutError: Error {}
