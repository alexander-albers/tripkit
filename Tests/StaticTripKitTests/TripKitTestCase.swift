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
            guard let (request, expected):(HttpRequest, [SuggestedLocation]) = loadFixtureArray(name: "suggestLocations-\(index)") else { continue }
            do {
                try provider.suggestLocationsParsing(request: request, constraint: testCase["constraint"].stringValue, types: nil, maxLocations: 5) { _, result in
                    switch result {
                    case .success(let locations):
                        os_log("success: %@", log: .testsLogger, type: .default, locations.map({($0.location.id ?? "") + " " + $0.location.getUniqueLongName()}))
                        XCTAssert(!locations.isEmpty, "received empty result")
                        XCTAssert(locations.contains(where: {$0.location.id == testCase["result"]["id"].string || $0.location.getUniqueLongName() == testCase["result"]["name"].string}), "result does not contain the searched location")
                        
                        XCTAssert(expected == locations)
                    case .failure(let error):
                        XCTFail("received an error: \(error)")
                    }
                }
            } catch let error {
                XCTFail("received an error: \(error)")
            }
        }
    }
    
    func testNearbyLocationsByCoordinate() {
        for (index, testCase):(String, JSON) in settings["queryNearbyLocationsByCoordinate"] {
            guard let (request, expected):(HttpRequest, [Location]) = loadFixtureArray(name: "queryNearbyLocationsByCoordinate-\(index)") else { continue }
            do {
                try provider.queryNearbyLocationsByCoordinateParsing(request: request, location: Location(lat: testCase["lat"].intValue, lon: testCase["lon"].intValue), types: [.station], maxDistance: 1000, maxLocations: 5, completion: { _, result in
                    switch result {
                    case .success(let locations):
                        os_log("success: %@", log: .testsLogger, type: .default, locations.map({($0.id ?? "") + " " + $0.getUniqueLongName()}))
                        XCTAssert(!locations.isEmpty, "received empty result")
                        XCTAssert(locations.contains(where: {$0.id == testCase["result"]["id"].string || $0.getUniqueLongName() == testCase["result"]["name"].string}), "result does not contain the searched location")
                        
                        XCTAssert(expected == locations)
                    case .invalidId:
                        XCTFail("received invalid id")
                    case .failure(let error):
                        XCTFail("received an error: \(error)")
                    }
                })
            } catch let error {
                XCTFail("received an error: \(error)")
            }
        }
    }
    
    func testQueryDepartures() {
        for (index, testCase):(String, JSON) in settings["queryDepartures"] {
            guard let (request, expected):(HttpRequest, [StationDepartures]) = loadFixtureArray(name: "queryDepartures-\(index)") else { continue }
            do {
                try provider.queryDeparturesParsing(request: request, stationId: testCase["id"].stringValue, departures: true, time: Date(), maxDepartures: 5, equivs: false, completion: { _, result in
                    switch result {
                    case .success(let departures):
                        os_log("success: %@", log: .testsLogger, type: .default, departures)
                        XCTAssert(!departures.isEmpty, "received empty result")
                        if let first = departures.first {
                            XCTAssert(!first.departures.isEmpty, "received empty result")
                        }
                        
                        XCTAssert(expected == departures)
                    case .invalidStation:
                        XCTFail("received invalid id")
                    case .failure(let error):
                        XCTFail("received an error: \(error)")
                    }
                })
            } catch let error {
                XCTFail("received an error: \(error)")
            }
        }
    }
    
    /* TODO: skip for now, figure out how to use the context in the future
     func testQueryJourneyDetail() {
        for (index, _):(String, JSON) in settings["queryDepartures"] {
            guard let (request, expected):(HttpRequest, PublicLeg) = loadFixture(name: "queryJourneyDetail-\(index)") else { continue }
            do {
                try provider.queryJourneyDetailParsing(request: request, context: QueryJourneyDetailContext(), completion: { _, result in
                    switch result {
                    case .success(_, let leg):
                        os_log("success: %@", log: .testsLogger, type: .default, leg)
                        
                        XCTAssert(expected == leg)
                    case .invalidId:
                        XCTFail("received invalid journey id")
                    case .failure(let error):
                        XCTFail("received an error: \(error)")
                    }
                })
            } catch let error {
                XCTFail("received an error: \(error)")
            }
        }
    }*/
    
    func testQueryArrivals() {
        for (index, testCase):(String, JSON) in settings["queryDepartures"] {
            guard let (request, expected):(HttpRequest, [StationDepartures]) = loadFixtureArray(name: "queryArrivals-\(index)") else { continue }
            do {
                try provider.queryDeparturesParsing(request: request, stationId: testCase["id"].stringValue, departures: false, time: Date(), maxDepartures: 5, equivs: false, completion: { _, result in
                    switch result {
                    case .success(let departures):
                        os_log("success: %@", log: .testsLogger, type: .default, departures)
                        XCTAssert(!departures.isEmpty, "received empty result")
                        if let first = departures.first {
                            XCTAssert(!first.departures.isEmpty, "received empty result")
                        }
                        
                        XCTAssert(expected == departures)
                    case .invalidStation:
                        XCTFail("received invalid id")
                    case .failure(let error):
                        XCTFail("received an error: \(error)")
                    }
                })
            } catch let error {
                XCTFail("received an error: \(error)")
            }
        }
    }
    
    func testQueryDeparturesEquivs() {
        for (index, testCase):(String, JSON) in settings["queryDepartures"] {
            guard let (request, expected):(HttpRequest, [StationDepartures]) = loadFixtureArray(name: "queryDeparturesEquivs-\(index)") else { continue }
            do {
                try provider.queryDeparturesParsing(request: request, stationId: testCase["id"].stringValue, departures: true, time: Date(), maxDepartures: 5, equivs: true, completion: { _, result in
                    switch result {
                    case .success(let departures):
                        os_log("success: %@", log: .testsLogger, type: .default, departures)
                        XCTAssert(!departures.isEmpty, "received empty result")
                        if let first = departures.first {
                            XCTAssert(!first.departures.isEmpty, "received empty result")
                        }
                        
                        XCTAssert(expected == departures)
                    case .invalidStation:
                        XCTFail("received invalid id")
                    case .failure(let error):
                        XCTFail("received an error: \(error)")
                    }
                })
            } catch let error {
                XCTFail("received an error: \(error)")
            }
        }
    }
    
    func testQueryDeparturesInvalid() {
        guard let request = loadFixtureWithoutOutput(name: "queryDeparturesInvalid") else { return }
        do {
            try provider.queryDeparturesParsing(request: request, stationId: settings["queryDeparturesInvalidId"].stringValue, departures: true, time: Date(), maxDepartures: 1, equivs: false) { _, result in
                switch result {
                case .success(_):
                    XCTFail("illegal result type success")
                case .invalidStation:
                    break
                case .failure(let error):
                    XCTFail("received an error: \(error)")
                }
            }
        } catch let error {
            XCTFail("received an error: \(error)")
        }
    }
    
    func testQueryTrips() {
        for (index, testCase):(String, JSON) in settings["queryTrips"] {
            guard let (request, expected):(HttpRequest, [Trip]) = loadFixtureArray(name: "queryTrips-\(index)") else { continue }
            do {
                try provider.queryTripsParsing(
                    request: request,
                    from: parseTestCaseLocation(testCase["from"]),
                    via: testCase["via"].exists() ? parseTestCaseLocation(testCase["via"]) : nil,
                    to: parseTestCaseLocation(testCase["to"]),
                    date: Date(), departure: true, tripOptions: TripOptions(), previousContext: nil, later: false) { _, result in
                    switch result {
                        case .success(let context, _, _, _, let trips, let messages):
                        os_log("success: %@, context=%@, messages=%@", log: .testsLogger, type: .default, trips, String(describing: context), messages)
                        XCTAssert(!trips.isEmpty, "received empty result")
                        if self.delegate.supportsQueryMoreTrips {
                            XCTAssert(context != nil, "context == nil")
                        }
                        
                        XCTAssert(expected == trips)
                    case .failure(let error):
                        XCTFail("received an error: \(error)")
                    default:
                        XCTFail("illegal result type \(result)")
                    }
                }
            } catch let error {
                XCTFail("received an error: \(error)")
            }
        }
    }
    
    func testRefreshTrip() {
        for (index, testCase):(String, JSON) in settings["queryTrips"] {
            guard let (request, expected):(HttpRequest, [Trip]) = loadFixtureArray(name: "refreshTrip-\(index)") else { continue }
            do {
                try provider.refreshTripParsing(request: request, context: HafasClientInterfaceRefreshTripContext(contextRecon: "", from: parseTestCaseLocation(testCase["from"]), to: parseTestCaseLocation(testCase["to"])), completion: { _, result in
                    switch result {
                    case .success(let context, _, _, _, let trips, let messages):
                        os_log("success: %@, context=%@, messages=%@", log: .testsLogger, type: .default, trips, String(describing: context), messages)
                        XCTAssert(!trips.isEmpty, "received empty result")
                        
                        XCTAssert(expected == trips)
                    case .failure(let error):
                        XCTFail("received an error: \(error)")
                    default:
                        XCTFail("illegal result type \(result)")
                    }
                })
            } catch let error {
                XCTFail("received an error: \(error)")
            }
        }
    }
    
    func testTooClose() {
        for (index, testCase):(String, JSON) in settings["queryTripsTooClose"] {
            guard let request = loadFixtureWithoutOutput(name: "queryTripsTooClose-\(index)") else { continue }
            do {
                try provider.queryTripsParsing(
                    request: request,
                    from: parseTestCaseLocation(testCase["from"]),
                    via: testCase["via"].exists() ? parseTestCaseLocation(testCase["via"]) : nil,
                    to: parseTestCaseLocation(testCase["to"]),
                    date: Date(), departure: true, tripOptions: TripOptions(), previousContext: nil, later: false) { _, result in
                    switch result {
                    case .tooClose, .noTrips, .failure(_):
                        break
                    default:
                        XCTFail("illegal result type \(result)")
                    }
                }
            } catch {
            }
        }
    }
    
    // MARK: utility methods
    
    func loadFixtureArray<T: AnyObject>(name: String) -> (request: HttpRequest, expected: [T])? {
        do {
            guard let inputFile = TestUtils.bundle.url(forResource: name, withExtension: "input", subdirectory: "Fixtures/\(provider.id.rawValue.lowercased())") else {
                os_log("Failed to load fixture input %@", log: .testsLogger, type: .error, provider.id.rawValue.lowercased() + "/" + name)
                return nil
            }
            guard let outputFile = TestUtils.bundle.url(forResource: name, withExtension: "output", subdirectory: "Fixtures/\(provider.id.rawValue.lowercased())") else {
                os_log("Failed to load fixture output %@", log: .testsLogger, type: .error, provider.id.rawValue.lowercased() + "/" + name)
                return nil
            }
            let input = try Data(contentsOf: inputFile)
            let outputData = try Data(contentsOf: outputFile)
            guard let output = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSArray.self, T.self], from: outputData) as? [T] else {
                os_log("Failed to unarchive fixture output %@", log: .testsLogger, type: .error, provider.id.rawValue.lowercased() + "/" + name)
                return nil
            }
            
            let request = HttpRequest(urlBuilder: UrlBuilder())
            request.responseData = input
            return (request, output)
        } catch let error as NSError {
            os_log("Failed to load fixture %@: %@", log: .testsLogger, type: .error, provider.id.rawValue.lowercased() + "/" + name, error.description)
            return nil
        }
    }
    
    func loadFixture<T: AnyObject>(name: String) -> (request: HttpRequest, expected: T)? {
        do {
            guard let inputFile = TestUtils.bundle.url(forResource: name, withExtension: "input", subdirectory: "Fixtures/\(provider.id.rawValue.lowercased())") else {
                os_log("Failed to load fixture input %@", log: .testsLogger, type: .error, provider.id.rawValue.lowercased() + "/" + name)
                return nil
            }
            guard let outputFile = TestUtils.bundle.url(forResource: name, withExtension: "output", subdirectory: "Fixtures/\(provider.id.rawValue.lowercased())") else {
                os_log("Failed to load fixture output %@", log: .testsLogger, type: .error, provider.id.rawValue.lowercased() + "/" + name)
                return nil
            }
            let input = try Data(contentsOf: inputFile)
            let outputData = try Data(contentsOf: outputFile)
            guard let output = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSArray.self, T.self], from: outputData) as? T else {
                os_log("Failed to unarchive fixture output %@", log: .testsLogger, type: .error, provider.id.rawValue.lowercased() + "/" + name)
                return nil
            }
            
            let request = HttpRequest(urlBuilder: UrlBuilder())
            request.responseData = input
            return (request, output)
        } catch let error as NSError {
            os_log("Failed to load fixture %@: %@", log: .testsLogger, type: .error, provider.id.rawValue.lowercased() + "/" + name, error.description)
            return nil
        }
    }
    
    func loadFixtureWithoutOutput(name: String) -> HttpRequest? {
        do {
            guard let inputFile = TestUtils.bundle.url(forResource: name, withExtension: "input", subdirectory: "Fixtures/\(provider.id.rawValue.lowercased())") else {
                os_log("Failed to load fixture input %@", log: .testsLogger, type: .error, provider.id.rawValue.lowercased() + "/" + name)
                return nil
            }
            let input = try Data(contentsOf: inputFile)

            let request = HttpRequest(urlBuilder: UrlBuilder())
            request.responseData = input
            return request
        } catch let error as NSError {
            os_log("Failed to load fixture %@: %@", log: .testsLogger, type: .error, provider.id.rawValue.lowercased() + "/" + name, error.description)
            return nil
        }
    }
    
}

