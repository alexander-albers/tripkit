import Foundation
import os.log
import SwiftyJSON
import CoreLocation
import MapKit

/// Schweizer Bundesbahnen (CH)
public class SbbProvider: AbstractNetworkProvider {
    
    /// Thanks a lot to @marudor! https://blog.marudor.de/SBB-Apis/
    static let API_BASE = "https://active.vnext.app.sbb.ch/unauth/fahrplanservice/v2/"
    static let USER_AGENT = "SBBmobile/flavorprodRelease-10.5.2-RELEASE Android/9 (Google;Pixel 3a XL)"
    
    var P_SPLIT_NAME_FIRST_COMMA: NSRegularExpression { return try! NSRegularExpression(pattern: "^(?:([^,]*), (?!$))?([^,]*)(?:, )?$") }
    
    private var apiKey: String = ""
    
    private lazy var timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    public init(certAuthorization: [String: Any]) {
        // Load tls client certificate
        if let certName = certAuthorization["certName"] as? String, let key = certAuthorization["password"] as? String {
            do {
                //let certificate = try Bundle.module.certificate(named: certName)
                //HttpClient.cacheIdentity(for: "active.vnext.app.sbb.ch", identity: identity)
                guard let url = Bundle.module.url(forResource: (certName as NSString).deletingPathExtension, withExtension: (certName as NSString).pathExtension) else {
                    throw ParseError(reason: "could not find specified certificate")
                }
                let data = try Data(contentsOf: url)
                let certHash = data.sha1.base64
                apiKey = (certHash + key).sha256.hex
            } catch let error as NSError {
                os_log("SBB: failed to load client certificate! %{public}@", log: .requestLogger, type: .error, error.description)
            }
        } else {
            os_log("SBB: failed to load client certificate!", log: .requestLogger, type: .error)
        }
        
        super.init(networkId: .SBB)
    }
    
    public override func suggestLocations(constraint: String, types: [LocationType]?, maxLocations: Int, completion: @escaping (HttpRequest, SuggestLocationsResult) -> Void) -> AsyncRequest {
        let urlBuilder = UrlBuilder(path: SbbProvider.API_BASE + "standorte/\(constraint.encodeUrl(using: .utf8)! ?? constraint)/", encoding: .utf8)
        let onlyStations: Bool
        if let types = types, types.count == 1, types.contains(.station) {
             onlyStations = true
        } else {
            onlyStations = false
        }
        urlBuilder.addParameter(key: "onlyHaltestellen", value: onlyStations)
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder).setUserAgent(SbbProvider.USER_AGENT).setHeaders(getHeaders(urlBuilder))
        return makeRequest(httpRequest) {
            try self.suggestLocationsParsing(request: httpRequest, constraint: constraint, types: types, maxLocations: maxLocations, completion: completion)
        } errorHandler: { err in
            completion(httpRequest, .failure(err))
        }
    }
    
    override func suggestLocationsParsing(request: HttpRequest, constraint: String, types: [LocationType]?, maxLocations: Int, completion: @escaping (HttpRequest, SuggestLocationsResult) -> Void) throws {
        let json = try getResponse(from: request)
        
        var locations: [SuggestedLocation] = []
        for (_, locJSON) in json["standorte"] {
            guard let location = parseLocation(json: locJSON) else { continue }
            if let types = types, !types.contains(location.type) && !types.contains(.any) { continue }
            locations.append(SuggestedLocation(location: location, priority: 0))
        }
        
        locations = Array(locations.prefix(maxLocations))
        
        completion(request, .success(locations: locations))
    }
    
    public override func queryNearbyLocations(location: Location, types: [LocationType]?, maxDistance: Int, maxLocations: Int, completion: @escaping (HttpRequest, NearbyLocationsResult) -> Void) -> AsyncRequest {
        guard let coord = location.coord else {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .invalidId)
            return AsyncRequest(task: nil)
        }
        
        // Calculate bounding box from center location and max distance
        let center = CLLocationCoordinate2D(latitude: Double(coord.lat) / 1e6, longitude: Double(coord.lon) / 1e6)
        let region = MKCoordinateRegion(center: center, latitudinalMeters: CLLocationDistance(maxDistance), longitudinalMeters: CLLocationDistance(maxDistance))
        let nwLat = Int((center.latitude  + (region.span.latitudeDelta  / 2.0)) * 1e6)
        let nwLon = Int((center.longitude - (region.span.longitudeDelta / 2.0)) * 1e6)
        let seLat = Int((center.latitude  - (region.span.latitudeDelta  / 2.0)) * 1e6)
        let seLon = Int((center.longitude + (region.span.longitudeDelta / 2.0)) * 1e6)
        
        let urlBuilder = UrlBuilder(path: SbbProvider.API_BASE + "standorteboundingbox/\(nwLat)/\(nwLon)/\(seLat)/\(seLon)/", encoding: .utf8)
        let httpRequest = HttpRequest(urlBuilder: urlBuilder).setUserAgent(SbbProvider.USER_AGENT).setHeaders(getHeaders(urlBuilder))
        return makeRequest(httpRequest) {
            try self.queryNearbyLocationsByCoordinateParsing(request: httpRequest, location: location, types: types, maxDistance: maxDistance, maxLocations: maxLocations, completion: completion)
        } errorHandler: { err in
            completion(httpRequest, .failure(err))
        }
    }
    
    override func queryNearbyLocationsByCoordinateParsing(request: HttpRequest, location: Location, types: [LocationType]?, maxDistance: Int, maxLocations: Int, completion: @escaping (HttpRequest, NearbyLocationsResult) -> Void) throws {
        try suggestLocationsParsing(request: request, constraint: location.getUniqueShortName(), types: types ?? [.station], maxLocations: maxLocations) { _, result in
            switch result {
            case .success(let locations):
                completion(request, .success(locations: locations.map { $0.location }))
            case .failure(let error):
                completion(request, .failure(error))
            }
        }
    }
    
    public override func queryDepartures(stationId: String, departures: Bool, time: Date?, maxDepartures: Int, equivs: Bool, completion: @escaping (HttpRequest, QueryDeparturesResult) -> Void) -> AsyncRequest {
        let urlBuilder = UrlBuilder(path: SbbProvider.API_BASE + "s/abfahrtstabelle/\(stationId)/", encoding: .utf8)
        urlBuilder.addParameter(key: "abAn", value: departures ? "ab" : "an")
        urlBuilder.addParameter(key: "vonId", value: stationId)
        
        // parameters for time?
        let httpRequest = HttpRequest(urlBuilder: urlBuilder).setUserAgent(SbbProvider.USER_AGENT).setHeaders(getHeaders(urlBuilder))
        return makeRequest(httpRequest) {
            try self.queryDeparturesParsing(request: httpRequest, stationId: stationId, departures: departures, time: time, maxDepartures: maxDepartures, equivs: equivs, completion: completion)
        } errorHandler: { err in
            completion(httpRequest, .failure(err))
        }
    }
    
    override func queryDeparturesParsing(request: HttpRequest, stationId: String, departures: Bool, time: Date?, maxDepartures: Int, equivs: Bool, completion: @escaping (HttpRequest, QueryDeparturesResult) -> Void) throws {
        let json = try getResponse(from: request)
        print(json)
        // TODO: wip
    }
    
    // MARK: parsing utils
    
    private func parseLocation(json: JSON) -> Location? {
        let type: LocationType
        switch json["type"].stringValue {
        case "STATION":     type = .station
        case "POI":         type = .poi
        case "ADDRESS":     type = .address
        case "COORDINATE":  type = .coord
        default:            type = .any
        }
        let id = normalize(stationId: json["externalId"].string)
        let (place, name) = split(stationName: json["displayName"].string)
        
        let coord: LocationPoint?
        if let lat = json["latitude"].int, let lon = json["longitude"].int {
            coord = LocationPoint(lat: lat, lon: lon)
        } else {
            coord = nil
        }
        return Location(type: type, id: id, coord: coord, place: place, name: name)
    }
    
    /**
     Splits the station name into place and station name.
     - Parameter stationName: the display name of the station.
     - Returns: the place and name of the station.
     */
    func split(stationName: String?) -> (place: String?, name: String?) {
        guard let stationName = stationName else {
            return (nil, nil)
        }
        if let m = stationName.match(pattern: P_SPLIT_NAME_FIRST_COMMA) {
            return (m[0], m[1])
        }
        return (nil, stationName)
    }
    
    private func getHeaders(_ urlBuilder: UrlBuilder) -> [String: String]? {
        guard let url = urlBuilder.build() else { return nil }
        var headers: [String: String] = [:]
        
        let timestamp = timestampFormatter.string(from: Date())
        headers["X-API-DATE"] = timestamp
        
        let input = url.path + "/" + timestamp
        headers["X-API-AUTHORIZATION"] = input.hmacSha1(key: apiKey).base64
        
        headers["Accept-Language"] = "de-DE"
        
        return headers
    }
    
}
