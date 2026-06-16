import Foundation
import os.log
import SwiftyJSON

/// Bern-Lötschberg-Simplon (CH)
///
/// BLS migrated away from the HAFAS mgate interface and now uses the standardized
/// Open Journey Planner (OJP) 2.0 API. See ``AbstractOjpProvider``.
///
/// The BLS OJP endpoint is secured with an OAuth2 bearer token. This is a BLS-specific quirk (OJP
/// itself mandates no authentication), so the token handling lives here rather than in the generic
/// base class: ``authorizeRequest(_:completion:)`` fetches a token via the client-credentials grant
/// on first use and caches it in memory until shortly before it expires.
public class BlsProvider: AbstractOjpProvider {

    static let API_ENDPOINT = "https://api.bls.ch/mmzd/rest/ojp/v2.0/servicerequest"
    static let TOKEN_ENDPOINT = "https://fahrplan.bls.ch/token"
    private let tokenGrantType = "client_credentials"

    public override var supportedLanguages: Set<String> { ["de", "en", "fr", "it"] }

    // MARK: Token cache (guarded by `tokenQueue`)
    private let tokenQueue = DispatchQueue(label: "TripKit.BlsProvider.token")
    private var cachedToken: String?
    private var cachedTokenExpiry: Date?
    /// Completions waiting for an in-flight token fetch, so concurrent requests share one fetch.
    private var pendingTokenCompletions: [(Result<String, Error>) -> Void] = []
    private var isFetchingToken = false
    /// Refresh the token this many seconds before it actually expires, to avoid races near expiry.
    private let tokenExpiryLeeway: TimeInterval = 30

    public init() {
        // Accept a ready-made bearer token for backwards compatibility / tests.
        super.init(networkId: .BLS, apiEndpoint: BlsProvider.API_ENDPOINT)
        requestorRef = "BLS_IOS_SDK_1.5.0"
        requestHeaders["Accept"] = "application/xml"

        styles = [
            // Tram
            "T3": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#98bbc5"), foregroundColor: LineStyle.white),
            "T6": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#0090d3"), foregroundColor: LineStyle.white),
            "T7": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ff2e18"), foregroundColor: LineStyle.white),
            "T8": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#fc72b6"), foregroundColor: LineStyle.white),
            "T9": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ffbe33"), foregroundColor: LineStyle.white),

            // Bus
            "B10": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#02ab4f"), foregroundColor: LineStyle.white),
            "B11": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#34ccf7"), foregroundColor: LineStyle.white),
            "B12": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#ff9127"), foregroundColor: LineStyle.white),
            "B16": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#50c8b1"), foregroundColor: LineStyle.white),
            "B17": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#ada430"), foregroundColor: LineStyle.white),
            "B19": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#821041"), foregroundColor: LineStyle.white),
            "B20": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#821041"), foregroundColor: LineStyle.white),
            "B21": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#f7cd35"), foregroundColor: LineStyle.white),
            "B22": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#98bbc5"), foregroundColor: LineStyle.white),
            "B26": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#ff9a33"), foregroundColor: LineStyle.white),
            "B27": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#5c5515"), foregroundColor: LineStyle.white),
            "B28": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#ada430"), foregroundColor: LineStyle.white),
            "B29": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#fc5757"), foregroundColor: LineStyle.white),
            "B30": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#98bbc5"), foregroundColor: LineStyle.white),
            "B31": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#a3cf44"), foregroundColor: LineStyle.white),
            "B32": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#50c8b1"), foregroundColor: LineStyle.white),
            "B33": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#5c5515"), foregroundColor: LineStyle.white),
            "B34": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#42140e"), foregroundColor: LineStyle.white),
            "B36": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#50c8b1"), foregroundColor: LineStyle.white),
            "B40": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#50c8b1"), foregroundColor: LineStyle.white),
            "B41": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#fc5757"), foregroundColor: LineStyle.white),
            "B43": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#98bbc5"), foregroundColor: LineStyle.white),
            "B44": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#5c5515"), foregroundColor: LineStyle.white),
            "B46": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#ada430"), foregroundColor: LineStyle.white),
            "B47": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#fc5757"), foregroundColor: LineStyle.white),
            
            "B100": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#50c8b1"), foregroundColor: LineStyle.white),
            "B101": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#42140e"), foregroundColor: LineStyle.white),
            "B102": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#5c5515"), foregroundColor: LineStyle.white),
            "B103": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#ff9a33"), foregroundColor: LineStyle.white),
            "B104": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#821041"), foregroundColor: LineStyle.white),
            "B105": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#ada430"), foregroundColor: LineStyle.white),
            "B106": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#ef451a"), foregroundColor: LineStyle.white),
            "B107": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#98bbc5"), foregroundColor: LineStyle.white),
            
            "B340": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#ada430"), foregroundColor: LineStyle.white),
            "B451": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#821041"), foregroundColor: LineStyle.white),
            "B570": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#ada430"), foregroundColor: LineStyle.white),
            "B631": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#5c5515"), foregroundColor: LineStyle.white),
            
            // S-Bahn
            "SS1": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#50bc4a"), foregroundColor: LineStyle.white),
            "SS2": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#1cb7ea"), foregroundColor: LineStyle.white),
            "SS20": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#fc5757"), foregroundColor: LineStyle.white),
            "SS21": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ada430"), foregroundColor: LineStyle.white),
            "SS3": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#7e6bb6"), foregroundColor: LineStyle.white),
            "SS31": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ada430"), foregroundColor: LineStyle.white),
            "SS35": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ff9a33"), foregroundColor: LineStyle.white),
            "SS36": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#1cb7ea"), foregroundColor: LineStyle.white),
            "SS37": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#5d5615"), foregroundColor: LineStyle.white),
            "SS4": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#50c8b1"), foregroundColor: LineStyle.white),
            "SS41": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ff9a33"), foregroundColor: LineStyle.white),
            "SS42": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#fc5757"), foregroundColor: LineStyle.white),
            "SS44": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#5d5615"), foregroundColor: LineStyle.white),
            "SS45": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ada430"), foregroundColor: LineStyle.white),
            "SS5": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#821041"), foregroundColor: LineStyle.white),
            "SS51": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#96cb45"), foregroundColor: LineStyle.white),
            "SS52": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#f7cd35"), foregroundColor: LineStyle.white),
            "SS6": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#fc5757"), foregroundColor: LineStyle.white),
            "SS7": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ff863a"), foregroundColor: LineStyle.white),
            "SS8": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#2c2e35"), foregroundColor: LineStyle.white),
            "SS9": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ff2e18"), foregroundColor: LineStyle.white),
            
            // RE
            "RRE1": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#f7cd35"), foregroundColor: LineStyle.white),
            "RRE2": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#98bbc5"), foregroundColor: LineStyle.white),
            "RRE3": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#821041"), foregroundColor: LineStyle.white),
            "RRE5": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#821041"), foregroundColor: LineStyle.white),
            "RRE7": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#821041"), foregroundColor: LineStyle.white),
        ]
    }

    // MARK: Authorization (OAuth2 client-credentials)

    override func authorizeRequest(_ httpRequest: HttpRequest, completion: @escaping (Result<HttpRequest, Error>) -> Void) {
        bearerToken { result in
            switch result {
            case .success(let token):
                var headers = httpRequest.headers ?? [:]
                headers["Authorization"] = "Bearer \(token)"
                httpRequest.setHeaders(headers)
                completion(.success(httpRequest))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// Returns a valid bearer token, using the in-memory cache if still valid, otherwise fetching a
    /// new one. Concurrent callers during an in-flight fetch are coalesced onto the same request.
    private func bearerToken(completion: @escaping (Result<String, Error>) -> Void) {
        tokenQueue.async {
            if let token = self.cachedToken, let expiry = self.cachedTokenExpiry, expiry > Date() {
                completion(.success(token))
                return
            }
            // A fetch is already running: just wait for its result.
            self.pendingTokenCompletions.append(completion)
            if self.isFetchingToken { return }
            self.isFetchingToken = true
            self.fetchToken()
        }
    }

    /// Performs the actual token request and resolves all pending completions. Must be called on `tokenQueue`.
    private func fetchToken() {
        let urlBuilder = UrlBuilder(path: BlsProvider.TOKEN_ENDPOINT, encoding: .utf8)
        let httpRequest = HttpRequest(urlBuilder: urlBuilder)
            .setPostPayload("grant_type=\(tokenGrantType)")
            .setContentType("application/x-www-form-urlencoded")
            .setHeaders(["Accept": "application/json"])

        _ = HttpClient.getJson(httpRequest: httpRequest) { [weak self] result in
            guard let self = self else { return }
            self.tokenQueue.async {
                let outcome: Result<String, Error>
                switch result {
                case .success(let json):
                    if let token = json["access_token"].string {
                        let expiresIn = json["expires_in"].double ?? 900
                        self.cachedToken = token
                        self.cachedTokenExpiry = Date().addingTimeInterval(max(0, expiresIn - self.tokenExpiryLeeway))
                        outcome = .success(token)
                    } else {
                        os_log("BLS token response missing access_token", log: .requestLogger, type: .error)
                        outcome = .failure(ParseError(reason: "missing access_token in token response"))
                    }
                case .failure(let error):
                    outcome = .failure(error)
                }

                let completions = self.pendingTokenCompletions
                self.pendingTokenCompletions.removeAll()
                self.isFetchingToken = false
                for completion in completions {
                    completion(outcome)
                }
            }
        }
    }

    override func newLine(id: String?, network: String?, product: Product?, name: String?, shortName: String?, number: String?, vehicleNumber: String?, direction: Line.Direction?, style: LineStyle) -> Line {
        let newName: String?
        if product == .suburbanTrain, let number = number {
            newName = number.hasPrefix("S") ? number : "S\(number)"
        } else if product == .regionalTrain, let number = number, let name = name, name.hasPrefix("RE") {
            newName = number.hasPrefix("RE") ? number : "RE\(number)"
        } else {
            newName = name
        }
        return super.newLine(id: id, network: network, product: product, name: newName, shortName: number, number: number, vehicleNumber: vehicleNumber, direction: direction, style: style)
    }
    
    static let PLACES = ["Bern"]
    
    override func split(stationName: String?) -> (String?, String?) {
        guard let stationName = stationName else { return super.split(stationName: nil) }
        
        for place in BlsProvider.PLACES {
            if stationName.hasPrefix(place + ", ") {
                return (place, stationName.substring(from: place.count + 2))
            } else if stationName.hasPrefix(place + " ") || stationName.hasPrefix(place + "-") {
                return (place, stationName.substring(from: place.count + 1))
            }
        }
        
        if let m = stationName.match(pattern: P_SPLIT_NAME_FIRST_COMMA) {
            return (m[0], m[1])
        }
        
        return super.split(stationName: stationName)
    }
    
    override func split(poi: String?) -> (String?, String?) {
        guard let poi = poi else { return super.split(poi: nil) }
        if let m = poi.match(pattern: P_SPLIT_NAME_FIRST_COMMA) {
            return (m[0], m[1])
        }
        return super.split(poi: poi)
    }
    
    override func split(address: String?) -> (String?, String?) {
        guard let address = address else { return super.split(address: nil) }
        if let m = address.match(pattern: P_SPLIT_NAME_FIRST_COMMA) {
            return (m[0], m[1])
        }
        return super.split(address: address)
    }
    
}
