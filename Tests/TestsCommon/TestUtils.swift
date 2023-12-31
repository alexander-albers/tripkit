import Foundation
@testable import TripKit
import os.log
import SwiftyJSON


public class TestUtils {
#if XCODE_BUILD
    public static let bundle = Bundle(for: TestUtils.self)
#else
    public static let bundle = Bundle.module
#endif
}

public protocol TripKitProviderTestsDelegate {
    
    var networkId: NetworkId { get }
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider
    
    var supportsQueryMoreTrips: Bool { get }
    var supportsRefreshTrip: Bool { get }
    var supportsJourneyDetails: Bool { get }
}

public extension TripKitProviderTestsDelegate {
    // the goal should be that all providers support the following features
    var supportsQueryMoreTrips: Bool { return true }
    var supportsRefreshTrip: Bool { return true }
    var supportsJourneyDetails: Bool { return true }
}

public extension OSLog {
    static let testsLogger = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "Tests")
}

public struct TimeoutError: Error {
    public init() {}
}

public func parseTestCaseLocation(_ json: JSON) -> Location {
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


fileprivate let P_HAFAS_ID = try! NSRegularExpression(pattern: ".*?@(?:L|b)=([^@]+).*@", options: [])
fileprivate let P_EFA_ID = try! NSRegularExpression(pattern: "streetID:[^:]*:[^:]*:[^:]*:[^:]*:([^:]*:[^:]*:[^:]*):.*", options: [])

public func extractLocationId(id: String?) -> String? {
    guard let id = id else { return nil }
    if let matches = id.match(pattern: P_HAFAS_ID), let res = matches[0] {
        return res
    } else if let matches = id.match(pattern: P_EFA_ID), let res = matches[0] {
        return res
    } else {
        return id
    }
}
