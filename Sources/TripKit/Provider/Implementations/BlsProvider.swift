import Foundation
import os.log
import SwiftyJSON
import SWXMLHash

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

    static let API_BASE = "https://api.bls.ch/mmzd/rest/ojp/v2.0"
    static let API_ENDPOINT = API_BASE + "/servicerequest"
    static let FORMATIONS_ENDPOINT = API_BASE + "/formations_stop_based"
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

    override func newLine(id: String?, network: String?, product: Product?, name: String?, shortName: String?, number: String?, vehicleNumber: String?, direction: Line.Direction?, attr: [Line.Attr]?, style: LineStyle) -> Line {
        let newName: String?
        if product == .suburbanTrain, let number = number {
            newName = number.hasPrefix("S") ? number : "S\(number)"
        } else if product == .regionalTrain, let number = number, let name = name, name.hasPrefix("RE") {
            newName = number.hasPrefix("RE") ? number : "RE\(number)"
        } else {
            newName = name
        }
        return super.newLine(id: id, network: network, product: product, name: newName, shortName: number, number: number, vehicleNumber: vehicleNumber, direction: direction, attr: attr, style: style)
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

    /// Railway undertaking, see atlas GO list of swiss open transport data
    enum EvuType {
        case SBB, BLS, MBC, RHB, SOB, THURBO, TPF, ZB, TRN, VDBB, OBB
        
        var code: String {
            switch self {
            case .SBB: return "SBBP"
            case .BLS: return "BLSP"
            case .MBC: return "MBC"
            case .RHB: return "RhB"
            case .SOB: return "SOB"
            case .THURBO: return "THURBO"
            case .TPF: return "TPF"
            case .ZB: return "ZB"
            case .TRN: return "TRN"
            case .VDBB: return "VDBB"
            case .OBB: return "OeBB"
            }
        }
        
        static func parse(from operatorRef: String) -> EvuType? {
            // from OjpExtensionKt
            var operatorRef = operatorRef
            if let index = operatorRef.lastIndex(of: ":"), index < operatorRef.endIndex {
                operatorRef = String(operatorRef[operatorRef.index(after: index)...])
            }
            switch operatorRef {
            case "11": return .SBB
            case "29": return .MBC
            case "33": return .BLS
            case "36": return .SOB
            case "44": return .TRN
            case "53": return .TPF
            case "65": return .THURBO
            case "68": return .OBB
            case "72": return .RHB
            case "73": return .TRN
            case "82": return .SOB
            case "86": return .ZB
            case "344": return .MBC
            case "3004", "7223": return .TPF
            case "7232": return .SOB
            case "7234": return .ZB
            case "7250": return .RHB
            case "7255": return .TRN
            case "7256": return .MBC
            case "9014": return .VDBB
            case "15300", "15301": return .TRN
            default: return nil
            }
        }
    }

    // The wagon formation of a train is not part of the OJP standard. BLS exposes it through a
    // separate REST endpoint on the same host, keyed by the railway undertaking (EVU), the operation
    // date and the train number. We derive the EVU from the OJP <siri:OperatorRef> and keep the
    // other two values from the <Service> element in an ``BlsWagonSequenceContext``.
    override func makeWagonSequenceContext(from service: XMLIndexer, boardingStop: Location) -> QueryWagonSequenceContext? {
        guard
            let operatorRef = service["siri:OperatorRef"].element?.text.emptyToNil,
            let evu = EvuType.parse(from: operatorRef)?.code,
            let trainNumber = service["TrainNumber"].element?.text.emptyToNil,
            let operationDate = service["OperatingDayRef"].element?.text.emptyToNil
        else { return nil }
        // The formation API keys its per-stop entries by UIC and stop name. OJP stop refs are SLOIDs
        // (`ch:1:sloid:…`), not UICs, so we match on the boarding stop's name instead.
        return BlsWagonSequenceContext(evu: evu, operationDate: operationDate, trainNumber: trainNumber, boardingStopName: boardingStop.name, boardingStopPlace: boardingStop.place)
    }

    public override func queryWagonSequence(context: QueryWagonSequenceContext, completion: @escaping (HttpRequest, QueryWagonSequenceResult) -> Void) -> AsyncRequest {
        guard let context = context as? BlsWagonSequenceContext else {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .invalidId)
            return AsyncRequest(task: nil)
        }
        let urlBuilder = UrlBuilder(path: BlsProvider.FORMATIONS_ENDPOINT, encoding: .utf8)
        urlBuilder.addParameter(key: "evu", value: context.evu)
        urlBuilder.addParameter(key: "operationDate", value: context.operationDate)
        urlBuilder.addParameter(key: "trainNumber", value: context.trainNumber)

        let httpRequest = HttpRequest(urlBuilder: urlBuilder).setContentType("application/json")
        let proxy = AsyncRequest(task: nil)
        authorizeRequest(httpRequest) { result in
            switch result {
            case .success(let authorizedRequest):
                let request = self.makeRequest(authorizedRequest, parseHandler: {
                    try self.queryWagonSequenceParsing(request: authorizedRequest, context: context, completion: completion)
                }, errorHandler: { err in
                    completion(authorizedRequest, .failure(err))
                })
                proxy.task = request.task
            case .failure(let error):
                completion(httpRequest, .failure(error))
            }
        }
        return proxy
    }

    override func queryWagonSequenceParsing(request: HttpRequest, context: QueryWagonSequenceContext, completion: @escaping (HttpRequest, QueryWagonSequenceResult) -> Void) throws {
        let json = try getResponse(from: request)

        let formations = json["formationsAtScheduledStops"].arrayValue
        guard !formations.isEmpty else {
            completion(request, .invalidId)
            return
        }

        // Pick the formation at the boarding stop, falling back to the first one. OJP stop refs are
        // SLOIDs rather than UICs, so we match on the boarding stop's name (the formation API exposes a
        // `stopPoint.name` per scheduled stop).
        let ctx = context as? BlsWagonSequenceContext
        let candidateNames = [ctx?.boardingStopName, ctx?.boardingStopPlace].compactMap { $0 }
        let formation = formations.first(where: { formationMatchesBoardingStop($0, names: candidateNames) }) ?? formations[0]

        let formationString = formation["formationShort", "formationShortString"].stringValue
        let parsed = parseFormationString(formationString)
        let allWagons = parsed.groups.flatMap { $0.wagons }
        guard !allWagons.isEmpty else {
            completion(request, .invalidId)
            return
        }

        // Build the track and its sectors from all parsed wagons.
        let track = StationTrack(trackNumber: formation["scheduledStop", "track"].string, start: allWagons[0].trackPosition.start, end: allWagons[allWagons.count - 1].trackPosition.end, sectors: mergeSectors(from: allWagons))

        // A train may split, so each goal covers a range of vehicle positions (OrdNr) and carries its
        // own destination. Assign each wagon group the destination of the goal covering its wagons.
        let goals = parseVehicleGoals(formation["formationShort", "vehicleGoals"])
        var wagonGroups: [WagonGroup] = []
        var wagonCount = 1
        for group in parsed.groups {
            let destination = goals.first(where: {$0.fromPosition <= wagonCount && $0.toPosition >= wagonCount + group.wagons.count - 1})?.destination
            wagonGroups.append(WagonGroup(designation: group.designation, wagons: group.wagons, destination: destination, lineLabel: nil))
            wagonCount += group.wagons.count
        }
        completion(request, .success(wagonSequence: WagonSequence(travelDirection: parsed.travelDirection, wagonGroups: wagonGroups, track: track)))
    }

    private struct VehicleGoal {
        let destination: String?
        let fromPosition: Int
        let toPosition: Int
    }

    private func parseVehicleGoals(_ json: JSON) -> [VehicleGoal] {
        return json.arrayValue.map {
            VehicleGoal(
                destination: $0["destinationStopPoint", "name"].string,
                fromPosition: $0["fromVehicleAtPosition"].intValue,
                toPosition: $0["toVehicleAtPosition"].intValue
            )
        }
    }

    /// Returns true if the formation's scheduled stop matches one of the boarding stop names from OJP.
    private func formationMatchesBoardingStop(_ formation: JSON, names: [String]) -> Bool {
        let stopName = formation["scheduledStop", "stopPoint", "name"].stringValue.lowercased()
        guard !stopName.isEmpty else { return false }
        for name in names.map({ $0.lowercased() }) where !name.isEmpty {
            // OJP may carry only the bare station name (e.g. "Bern") while the formation API uses the
            // full name; accept either as a substring of the other.
            if stopName == name || stopName.contains(name) || name.contains(stopName) {
                return true
            }
        }
        return false
    }

    /// Width assumed per wagon, in meters, to lay out sector positions.
    private static let WAGON_WIDTH = 20.0

    private struct ParsedFormation {
        var groups: [(designation: String, wagons: [Wagon])]
        var travelDirection: WagonSequence.TravelDirection?
    }

    /// Parses a BLS/SBB "formationShortString" into wagon groups.
    /// See: https://opentransportdata.swiss/en/cookbook/realtime-prediction-cookbook/formationsdaten/#The_answer
    ///
    /// Grammar (per the official customer-information specification), one wagon per comma-separated
    /// token, shaped `[Sector][Status]*[(]FzTypKl[)][:OrdNr]#Service(;Service)*`:
    /// - `@X` is the **sector** (point A…Z) the wagon boundary crosses into. As a standalone token or
    ///   leading a wagon it sets the current sector; trailing a wagon it announces the sector for the
    ///   *next* wagon (the current wagon keeps the current sector).
    /// - **Status** (`-`,`>`,`=`,`%`, combinable) precedes the type. `-` = closed (and only on its own),
    ///   `>` = group boarding here, `=` = (partly) reserved for groups in transit, `%` = open but not
    ///   served (dining cars).
    /// - `(` / `)` mark that there is **no access to the neighbouring vehicle** on that side. A `(`
    ///   therefore starts a walk-through-isolated unit and `)` ends it — we surface each such unit as a
    ///   separate ``WagonGroup``.
    /// - **FzTypKl** is the vehicle type/class: `1`/`2`/`12` (and `W1`/`W2`/`K`) carry class info; other
    ///   types are `CC`,`FA`,`WL`,`WR`,`LK`,`D`,`F`,`X`.
    /// - `:OrdNr` (optional) is the printed coach number used for seat reservations.
    /// - `#Service;…` are vehicle offers (`BHP`,`BZ`,`FZ`,`KW`,`NF`,`VH`,`VR`).
    /// - `[` / `]` delimit the vehicles belonging to the moving train; anything outside (e.g. sector-fill
    ///   `F` cars or stabled `X` cars) is not part of the train and is dropped.
    private func parseFormationString(_ string: String) -> ParsedFormation {
        var groups: [(designation: String, wagons: [Wagon])] = []
        var currentWagons: [Wagon] = []
        var currentDesignation = ""
        var currentSector = ""
        var pendingSector: String?
        var position = 0.0
        var insideTrain = false

        func flushGroup() {
            if !currentWagons.isEmpty {
                groups.append((designation: currentDesignation, wagons: currentWagons))
            }
            currentWagons = []
            currentDesignation = ""
        }

        for rawToken in string.split(separator: ",").map(String.init) {
            var body = rawToken.trimmingCharacters(in: .whitespaces)

            // `[` / `]` bound the moving train. Update state and strip them.
            if body.contains("[") { insideTrain = true }
            let leavesTrain = body.contains("]")
            body = body.replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "")

            // `(` / `)` are per-vehicle "no access on this side" markers; a `(` begins a walk-through
            // isolated unit (new group) and a `)` ends it.
            let noAccessLeft = body.contains("(")
            let noAccessRight = body.contains(")")
            body = body.replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "")

            if noAccessLeft {
                flushGroup()
            }

            // Leading `@X` markers set the current sector for what follows.
            while body.hasPrefix("@"), body.count >= 2 {
                currentSector = String(body[body.index(body.startIndex, offsetBy: 1)])
                body = String(body.dropFirst(2))
            }
            // A trailing `@X` marker announces the sector for the *next* wagon.
            var nextSector: String?
            if let marker = body.last, body.dropLast().last == "@", marker.isLetter {
                nextSector = String(marker)
                body = String(body.dropLast(2))
            }

            let wagonBody = body.trimmingCharacters(in: .whitespaces)
            if wagonBody.isEmpty {
                if let nextSector = nextSector { pendingSector = nextSector }
                if noAccessRight { flushGroup() }
                if leavesTrain { insideTrain = false }
                continue
            }

            // Apply a sector announced by the previous wagon's trailing marker.
            if let pending = pendingSector {
                currentSector = pending
                pendingSector = nil
            }

            let parsed = parseWagon(wagonBody, sector: currentSector, start: position)
            position += BlsProvider.WAGON_WIDTH

            // Only vehicles inside the `[ … ]` brackets belong to the train. The vehicle type (FzTypKl)
            // is a per-wagon property; a dining/restaurant car gives the group a designation.
            if insideTrain {
                if currentDesignation.isEmpty, let type = parsed.type, type.hasPrefix("W") || type == "CC" || type == "WL" {
                    currentDesignation = type
                }
                currentWagons.append(parsed.wagon)
            }

            if let nextSector = nextSector { pendingSector = nextSector }
            if noAccessRight { flushGroup() }
            if leavesTrain { insideTrain = false }
        }
        flushGroup()
        return ParsedFormation(groups: groups, travelDirection: .left)
    }

    /// Parses a single wagon body into a ``Wagon`` plus its vehicle type (FzTypKl).
    ///
    /// The body has the shape `[Status]*[FzTypKl][:OrdNr]#[Service;Service;…]`, where the status flags
    /// (`-`,`>`,`=`,`%`) precede the type, the type carries class information (`1`/`2`/`12`/`W1`/`W2`/`K`),
    /// and `:OrdNr` (optional) is the printed coach number.
    ///
    /// A bare `F` is a fictitious sector-fill car with no further detail.
    private func parseWagon(_ body: String, sector: String, start: Double) -> (wagon: Wagon, type: String?) {
        // Split off services after `#`.
        let hashParts = body.split(separator: "#", maxSplits: 1).map(String.init)
        var head = hashParts.first ?? ""

        // Strip the leading status flags. `-` means the vehicle is closed.
        var isOpen = true
        while let first = head.first, "->=%".contains(first) {
            if first == "-" { isOpen = false }
            head = String(head.dropFirst())
        }

        // The OrdNr (printed coach number) is an optional `:n` suffix; the rest is the vehicle type.
        var number: Int?
        if let colon = head.firstIndex(of: ":") {
            number = Int(head[head.index(after: colon)...])
            head = String(head[head.startIndex..<colon])
        }
        let type = head.emptyToNil
        let (firstClass, secondClass) = classFlags(forVehicleType: head)

        var attributes: [WagonAttributes] = []
        if hashParts.count > 1 {
            for code in hashParts[1].split(separator: ";").map(String.init) {
                if let attribute = mapWagonAttribute(code) {
                    attributes.append(WagonAttributes(attribute: attribute, state: .available))
                }
            }
        }

        let trackPosition = StationTrackSector(sectorName: sector, start: start, end: start + BlsProvider.WAGON_WIDTH)
        let wagon = Wagon(number: number, orientation: nil, trackPosition: trackPosition, attributes: attributes, firstClass: firstClass, secondClass: secondClass, loadFactor: nil, isOpen: isOpen)
        return (wagon, type)
    }

    /// Derives the first/second-class flags from a vehicle type (FzTypKl).
    ///
    /// Besides the explicit class types (`1`, `2`, `12`) and the combined dining cars (`W1`/`W2`), the
    /// accommodation types `FA` (family coach) and `CC` (couchette) carry 2nd-class seating. Classless
    /// or seatless vehicles (`K`, `WL`, `WR`, `LK`, `D`, `F`, `X`) report neither.
    private func classFlags(forVehicleType type: String) -> (firstClass: Bool, secondClass: Bool) {
        switch type {
        case "1", "W1":
            return (true, false)
        case "2", "W2", "FA", "CC":
            return (false, true)
        case "12":
            return (true, true)
        default:
            return (false, false)
        }
    }

    /// Maps a BLS formation service code (`Angebot`) to a ``WagonAttributes/Type``.
    private func mapWagonAttribute(_ code: String) -> WagonAttributes.`Type`? {
        switch code {
        case "BHP": return .wheelchairSpace     // Wheelchair spaces
        case "FZ": return .zoneFamily           // Family zone
        case "KW": return .cabinInfant          // Pram platform
        case "NF": return .boardingAid          // Low-floor access
        case "VH", "VR": return .bikeSpace      // Bicycle hooks/platform (VR: reservation required)
        default: return nil
        }
    }

    /// Collapses consecutive wagons in the same sector into merged ``StationTrackSector`` spans.
    private func mergeSectors(from wagons: [Wagon]) -> [StationTrackSector] {
        var sectors: [StationTrackSector] = []
        for wagon in wagons {
            let s = wagon.trackPosition
            if let last = sectors.last, last.sectorName == s.sectorName {
                sectors[sectors.count - 1] = StationTrackSector(sectorName: last.sectorName, start: last.start, end: s.end)
            } else {
                sectors.append(StationTrackSector(sectorName: s.sectorName, start: s.start, end: s.end))
            }
        }
        return sectors
    }

}

/// Context for the BLS wagon-formation API (`formations_stop_based`). It carries the railway
/// undertaking code (EVU), the operation date and the train number — the three query parameters the
/// endpoint requires — plus the boarding stop name so the right per-stop formation can be picked.
public class BlsWagonSequenceContext: QueryWagonSequenceContext {
    
    public override class var supportsSecureCoding: Bool { return true }
    
    let evu: String
    let operationDate: String
    let trainNumber: String
    /// Name of the boarding stop, used to select the matching per-stop formation. OJP stop refs are
    /// SLOIDs rather than UICs, so the response can only be matched by name.
    let boardingStopName: String?
    let boardingStopPlace: String?

    init(evu: String, operationDate: String, trainNumber: String, boardingStopName: String?, boardingStopPlace: String?) {
        self.evu = evu
        self.operationDate = operationDate
        self.trainNumber = trainNumber
        self.boardingStopName = boardingStopName
        self.boardingStopPlace = boardingStopPlace
        super.init()
    }

    public required init?(coder aDecoder: NSCoder) {
        guard
            let evu = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.evu) as String?,
            let operationDate = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.operationDate) as String?,
            let trainNumber = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.trainNumber) as String?
        else { return nil }
        self.evu = evu
        self.operationDate = operationDate
        self.trainNumber = trainNumber
        self.boardingStopName = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.boardingStopName) as String?
        self.boardingStopPlace = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.boardingStopPlace) as String?
        super.init(coder: aDecoder)
    }

    public override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(evu, forKey: PropertyKey.evu)
        aCoder.encode(operationDate, forKey: PropertyKey.operationDate)
        aCoder.encode(trainNumber, forKey: PropertyKey.trainNumber)
        aCoder.encode(boardingStopName, forKey: PropertyKey.boardingStopName)
        aCoder.encode(boardingStopPlace, forKey: PropertyKey.boardingStopPlace)
    }

    struct PropertyKey {
        static let evu = "evu"
        static let operationDate = "operationDate"
        static let trainNumber = "trainNumber"
        static let boardingStopName = "boardingStopName"
        static let boardingStopPlace = "boardingStopPlace"
    }
}
