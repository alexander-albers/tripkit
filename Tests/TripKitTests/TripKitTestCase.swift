import XCTest
import TestsCommon
@testable import TripKit
import os.log
import SwiftyJSON

class TripKitProviderTestCase: XCTestCase {
    
    private var provider: AbstractNetworkProvider!
    private var secrets: [NetworkId: AuthorizationData] = [:]
    private var settings: JSON!
    
    var delegate: TripKitProviderTestsDelegate! { return nil }
    
    override func setUpWithError() throws {
        super.setUp()
        continueAfterFailure = true
        
        secrets = SecretsLoader.loadSecrets()
        try XCTSkipIf(delegate == nil)
        provider = delegate.initProvider(from: secrets[delegate.networkId] ?? AuthorizationData()) as? AbstractNetworkProvider
        guard let settingsUrl = TestUtils.bundle.url(forResource: provider.id.rawValue.lowercased(), withExtension: "json", subdirectory: "Test Cases") else {
            fatalError("could not find settings file for provider \(provider.id.rawValue.lowercased())")
        }
        settings = try JSON(data: Data(contentsOf: settingsUrl))
    }

    // MARK: tests
    
    func testSuggestLocations() {
        for (index, testCase):(String, JSON) in settings["suggestLocations"] {
            let (request, result) = syncSuggestLocations(constraint: testCase["constraint"].stringValue)
            switch result {
            case .success(let locations):
                os_log("success: %@", log: .testsLogger, type: .default, locations.map({($0.location.id ?? "") + " " + $0.location.getUniqueLongName()}))
                XCTAssert(!locations.isEmpty, "received empty result")
                XCTAssert(locations.contains(where: {compareLocationIds($0.location.id, testCase["result"]["id"].string) || $0.location.getUniqueLongName() == testCase["result"]["name"].string}), "result does not contain the searched location")
                
                saveFixture(name: "suggestLocations-\(index)", input: request.responseData, output: locations)
            case .failure(let error):
                XCTFail("received an error: \(error)")
            }
        }
    }
    
    func testNearbyLocationsByCoordinate() {
        for (index, testCase):(String, JSON) in settings["queryNearbyLocationsByCoordinate"] {
            let (request, result) = syncNearbyStations(location: Location(lat: testCase["lat"].intValue, lon: testCase["lon"].intValue), types: [.station], maxDistance: 1000, maxLocations: 5)
            switch result {
            case .success(let locations):
                os_log("success: %@", log: .testsLogger, type: .default, locations.map({($0.id ?? "") + " " + $0.getUniqueLongName()}))
                XCTAssert(!locations.isEmpty, "received empty result")
                XCTAssert(locations.contains(where: {compareLocationIds($0.id, testCase["result"]["id"].string) || $0.getUniqueLongName() == testCase["result"]["name"].string}), "result does not contain the searched location")
                
                saveFixture(name: "queryNearbyLocationsByCoordinate-\(index)", input: request.responseData, output: locations)
            case .invalidId:
                XCTFail("received invalid id")
            case .failure(let error):
                XCTFail("received an error: \(error)")
            }
        }
    }
    
    func testQueryDepartures() {
        for (index, testCase):(String, JSON) in settings["queryDepartures"] {
            let (request, result) = syncQueryDepartures(stationId: testCase["id"].stringValue, departures: true, time: Date(), maxDepartures: 5, equivs: false)
            switch result {
            case .success(let departures):
                os_log("success: %@", log: .testsLogger, type: .default, departures)
                XCTAssert(!departures.flatMap({$0.departures}).isEmpty, "received empty result")
                
                saveFixture(name: "queryDepartures-\(index)", input: request.responseData, output: departures)
                
                if let first = departures.first?.departures.first, delegate.supportsJourneyDetails {
                    XCTAssert(first.journeyContext != nil, "journeyContext == nil")
                    
                    if let context = first.journeyContext {
                        let (request, result) = syncJourneyDetail(context: context)
                        switch result {
                        case .success(_, let leg):
                            os_log("success: %@", log: .testsLogger, type: .default, leg)
                            
                            saveFixture(name: "queryJourneyDetail-\(index)", input: request.responseData, output: leg)
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
    }
    
    func testQueryArrivals() {
        for (index, testCase):(String, JSON) in settings["queryDepartures"] {
            let (request, result) = syncQueryDepartures(stationId: testCase["id"].stringValue, departures: false, time: Date(), maxDepartures: 5, equivs: false)
            switch result {
            case .success(let departures):
                os_log("success: %@", log: .testsLogger, type: .default, departures)
                XCTAssert(!departures.flatMap({$0.departures}).isEmpty, "received empty result")
                
                saveFixture(name: "queryArrivals-\(index)", input: request.responseData, output: departures)
            case .invalidStation:
                XCTFail("received invalid id")
            case .failure(let error):
                XCTFail("received an error: \(error)")
            }
        }
    }
    
    func testQueryDeparturesEquivs() {
        for (index, testCase):(String, JSON) in settings["queryDepartures"] {
            let (request, result) = syncQueryDepartures(stationId: testCase["id"].stringValue, departures: true, time: Date(), maxDepartures: 5, equivs: true)
            switch result {
            case .success(let departures):
                os_log("success: %@", log: .testsLogger, type: .default, departures)
                XCTAssert(!departures.flatMap({$0.departures}).isEmpty, "received empty result")
                
                saveFixture(name: "queryDeparturesEquivs-\(index)", input: request.responseData, output: departures)
            case .invalidStation:
                XCTFail("received invalid id")
            case .failure(let error):
                XCTFail("received an error: \(error)")
            }
        }
    }
    
    func testQueryDeparturesInvalid() {
        let (request, result) = syncQueryDepartures(stationId: settings["queryDeparturesInvalidId"].stringValue, departures: true, time: Date(), maxDepartures: 1, equivs: false)
        switch result {
        case .success(_):
            XCTFail("illegal result type success")
        case .invalidStation:
            saveFixture(name: "queryDeparturesInvalid", input: request.responseData, output: nil)
        case .failure(let error):
            XCTFail("received an error: \(error)")
        }
    }
    
    func testQueryTrips() {
        for (index, testCase):(String, JSON) in settings["queryTrips"] {
            let (request, result) = syncQueryTrips(
                from: parseTestCaseLocation(testCase["from"]),
                via: testCase["via"].exists() ? parseTestCaseLocation(testCase["via"]) : nil,
                to: parseTestCaseLocation(testCase["to"]),
                date: Date(), departure: true, products: nil, optimize: nil, walkSpeed: nil, accessibility: nil, options: nil
            )
            var queryMoreContext: QueryTripsContext?
            switch result {
            case .success(let context, _, _, _, let trips, let messages):
                os_log("success: %@, context=%@, messages=%@", log: .testsLogger, type: .default, trips, String(describing: context), messages)
                XCTAssert(!trips.isEmpty, "received empty result")
                if delegate.supportsQueryMoreTrips {
                    XCTAssertNotNil(context, "context == nil")
                }
                queryMoreContext = context
                
                saveFixture(name: "queryTrips-\(index)", input: request.responseData, output: trips)
                
                if let first = trips.first, delegate.supportsRefreshTrip {
                    let context = first.refreshContext
                    XCTAssertNotNil(context, "refresh context == nil")
                    let (request, result) = syncRefreshTrip(context: context!)
                    switch result {
                    case .success(let context, _, _, _, let trips, let messages):
                        os_log("success: %@, context=%@, messages=%@", log: .testsLogger, type: .default, trips, String(describing: context), messages)
                        XCTAssert(!trips.isEmpty, "received empty result")
                        
                        saveFixture(name: "refreshTrip-\(index)", input: request.responseData, output: trips)
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
                XCTAssertNotNil(context, "context == nil")
                queryMoreContext = context
            case .failure(let error):
                XCTFail("received an error: \(error)")
            default:
                XCTFail("illegal result type \(resultLater)")
            }
            
            guard let queryMoreContext2 = queryMoreContext else { return }
            queryMoreContext = nil
            let resultEarlier = syncQueryMoreTrips(context: queryMoreContext2, later: false)
            switch resultEarlier {
            case .success(let context, _, _, _, let trips, let messages):
                os_log("success: %@, context=%@, messages=%@", log: .testsLogger, type: .default, trips, String(describing: context), messages)
                XCTAssert(!trips.isEmpty, "received empty result")
                XCTAssertNotNil(context, "context == nil")
            case .failure(let error):
                XCTFail("received an error: \(error)")
            default:
                XCTFail("illegal result type \(resultEarlier)")
            }
        }
    }
    
    func testTooClose() {
        for (index, testCase):(String, JSON) in settings["queryTripsTooClose"] {
            let (request, result) = syncQueryTrips(
                from: parseTestCaseLocation(testCase["from"]),
                via: testCase["via"].exists() ? parseTestCaseLocation(testCase["via"]) : nil,
                to: parseTestCaseLocation(testCase["to"]),
                date: Date(), departure: true, products: nil, optimize: nil, walkSpeed: nil, accessibility: nil, options: nil
            )
            switch result {
            case .tooClose, .noTrips, .failure(_):
                saveFixture(name: "queryTripsTooClose-\(index)", input: request.responseData, output: nil)
            default:
                XCTFail("illegal result type \(result)")
            }
        }
    }
    
    // MARK: utility methods
    
    func syncQueryTrips(from: Location, via: Location?, to: Location, date: Date, departure: Bool, products: [Product]?, optimize: Optimize?, walkSpeed: WalkSpeed?, accessibility: Accessibility?, options: [Option]?) -> (HttpRequest, QueryTripsResult) {
        let expectation = self.expectation(description: "Network Task")
        var request: HttpRequest?
        var result: QueryTripsResult?
        
        _ = provider.queryTrips(from: from, via: via, to: to, date: date, departure: departure, tripOptions: TripOptions(products: products, optimize: optimize, walkSpeed: walkSpeed, accessibility: accessibility, options: options, maxChanges: nil, minChangeTime: nil), completion: { (httpRequest, completion) in
            request = httpRequest
            result = completion
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: 30, handler: nil)
        XCTAssert(request != nil, "No result fetched!")
        XCTAssert(result != nil, "No result fetched!")
        guard let request_ = request, let result_ = result else {
            return (HttpRequest(urlBuilder: UrlBuilder()), .failure(TimeoutError()))
        }
        return (request_, result_)
    }
    
    func syncQueryMoreTrips(context: QueryTripsContext, later: Bool) -> QueryTripsResult {
        let expectation = self.expectation(description: "Network Task")
        var result: QueryTripsResult?
        
        _ = provider.queryMoreTrips(context: context, later: later) { (request, completion: QueryTripsResult) in
            result = completion
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 30, handler: nil)
        XCTAssert(result != nil, "No result fetched!")
        return result ?? .failure(TimeoutError())
    }
    
    func syncRefreshTrip(context: RefreshTripContext) -> (HttpRequest, QueryTripsResult) {
        let expectation = self.expectation(description: "Network Task")
        var request: HttpRequest?
        var result: QueryTripsResult?
        
        _ = provider.refreshTrip(context: context) { (httpRequest, completion: QueryTripsResult) in
            request = httpRequest
            result = completion
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 30, handler: nil)
        XCTAssert(result != nil, "No result fetched!")
        XCTAssert(request != nil, "No result fetched!")
        XCTAssert(result != nil, "No result fetched!")
        guard let request_ = request, let result_ = result else {
            return (HttpRequest(urlBuilder: UrlBuilder()), .failure(TimeoutError()))
        }
        return (request_, result_)
    }
    
    func syncNearbyStations(location: Location, types: [LocationType], maxDistance: Int, maxLocations: Int) -> (HttpRequest, NearbyLocationsResult) {
        let expectation = self.expectation(description: "Network Task")
        var request: HttpRequest?
        var result: NearbyLocationsResult?
        
        _ = provider.queryNearbyLocations(location: location, types: types, maxDistance: maxDistance, maxLocations: maxLocations) { (httpRequest, completion: NearbyLocationsResult) in
            request = httpRequest
            result = completion
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 30, handler: nil)
        XCTAssert(request != nil, "No result fetched!")
        XCTAssert(result != nil, "No result fetched!")
        guard let request_ = request, let result_ = result else {
            return (HttpRequest(urlBuilder: UrlBuilder()), .failure(TimeoutError()))
        }
        return (request_, result_)
    }
    
    func syncQueryDepartures(stationId: String, departures: Bool, time: Date?, maxDepartures: Int, equivs: Bool) -> (HttpRequest, QueryDeparturesResult) {
        let expectation = self.expectation(description: "Network Task")
        var request: HttpRequest?
        var result: QueryDeparturesResult?
        
        _ = provider.queryDepartures(stationId: stationId, departures: departures, time: time, maxDepartures: maxDepartures, equivs: equivs) { (httpRequest, completion: QueryDeparturesResult) in
            request = httpRequest
            result = completion
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 30, handler: nil)
        XCTAssert(request != nil, "No result fetched!")
        XCTAssert(result != nil, "No result fetched!")
        guard let request_ = request, let result_ = result else {
            return (HttpRequest(urlBuilder: UrlBuilder()), .failure(TimeoutError()))
        }
        return (request_, result_)
    }
    
    func syncJourneyDetail(context: QueryJourneyDetailContext) -> (HttpRequest, QueryJourneyDetailResult) {
        let expectation = self.expectation(description: "Network Task")
        var request: HttpRequest?
        var result: QueryJourneyDetailResult?
        
        _ = provider.queryJourneyDetail(context: context) { (httpRequest, completion: QueryJourneyDetailResult) in
            request = httpRequest
            result = completion
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 30, handler: nil)
        XCTAssert(request != nil, "No result fetched!")
        XCTAssert(result != nil, "No result fetched!")
        guard let request_ = request, let result_ = result else {
            return (HttpRequest(urlBuilder: UrlBuilder()), .failure(TimeoutError()))
        }
        return (request_, result_)
    }
    
    func syncSuggestLocations(constraint: String) -> (HttpRequest, SuggestLocationsResult) {
        let expectation = self.expectation(description: "Network Task")
        var request: HttpRequest?
        var result: SuggestLocationsResult?
        
        _ = provider.suggestLocations(constraint: constraint, types: nil, maxLocations: 5) { (httpRequest, completion: SuggestLocationsResult) in
            request = httpRequest
            result = completion
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 30, handler: nil)
        XCTAssert(request != nil, "No result fetched!")
        XCTAssert(result != nil, "No result fetched!")
        guard let request_ = request, let result_ = result else {
            return (HttpRequest(urlBuilder: UrlBuilder()), .failure(TimeoutError()))
        }
        return (request_, result_)
    }
    
    func saveFixture(name: String, input: Data?, output: Any?) {
        guard let _ = ProcessInfo.processInfo.environment["SAVE_FIXTURES"] else {
            return
        }
        guard let input = input else {
            XCTAssert(false, "No result fetched!")
            return
        }
        let file = URL(fileURLWithPath: #file)
        let fixturesUrl = file.deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("TestsCommon/Resources/Fixtures/\(provider.id.rawValue.lowercased())")
        do {
            if !FileManager.default.fileExists(atPath: fixturesUrl.path) {
                try FileManager.default.createDirectory(atPath: fixturesUrl.path, withIntermediateDirectories: false, attributes: nil)
            }
            try input.write(to: fixturesUrl.appendingPathComponent(name).appendingPathExtension("input"))
            if let output = output {
                let outData = try NSKeyedArchiver.archivedData(withRootObject: output, requiringSecureCoding: true)
                try outData.write(to: fixturesUrl.appendingPathComponent(name).appendingPathExtension("output"))
            }
        } catch let error as NSError {
            os_log("Failed to save fixture %@: %@", log: .testsLogger, type: .error, name, error.description)
        }
    }
    
    func parseTestCaseLocation(_ json: JSON) -> Location {
        let coord: LocationPoint?
        if let lat = json["lat"].int, let lon = json["lon"].int {
            coord = LocationPoint(lat: lat, lon: lon)
        } else {
            coord = nil
        }
        guard let locationType = LocationType.from(string: json["type"].stringValue) else {
            fatalError("location type not specified or illegal")
        }
        guard let location = Location(type: locationType, id: json["id"].string, coord: coord, place: json["place"].string, name: json["name"].string) else {
            fatalError("could not initialize test case location")
        }
        return location
    }
}
