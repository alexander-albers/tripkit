import Foundation
import os.log
import SwiftyJSON

public class AbstractNetworkProvider: NetworkProvider {
    
    public let id: NetworkId
    public var supportedQueryTraits: Set<QueryTrait> { return [] }
    public var tariffReductionTypes: [TariffReduction] { return [] }
    public var supportedLanguages: Set<String> { [] }
    public var defaultLanguage: String {
        // First, check whether the current locale is supported
        if let currentLocale = Locale.current.languageCode, supportedLanguages.contains(currentLocale) {
            return currentLocale
        } else if supportedLanguages.contains("en") {
            // Fallback to en, if it is supported
            return "en"
        } else if let first = supportedLanguages.first {
            // Fallback to any other supported language
            return first
        } else {
            // Fallback to en
            return "en"
        }
    }
    public var queryLanguage: String? {
        didSet(newValue) {
            // ensure language code is supported
            if let newValue = newValue, !supportedLanguages.contains(newValue) {
                queryLanguage = nil
            }
        }
    }
    
    public var styles: [String: LineStyle] = [:]
    var numTripsRequested = 6
    public var timeZone: TimeZone = TimeZone(abbreviation: "CET")!
    
    init(networkId: NetworkId) {
        self.id = networkId
    }
    
    // MARK: API methods
    
    public func suggestLocations(constraint: String, types: [LocationType]?, maxLocations: Int, completion: @escaping (HttpRequest, SuggestLocationsResult) -> Void) -> AsyncRequest {
        fatalError("\(#function) not implemented")
    }
    
    public func queryNearbyLocations(location: Location, types: [LocationType]?, maxDistance: Int, maxLocations: Int, completion: @escaping (HttpRequest, NearbyLocationsResult) -> Void) -> AsyncRequest {
        fatalError("\(#function) not implemented")
    }
    
    public func queryDepartures(stationId: String, departures: Bool, time: Date?, maxDepartures: Int, equivs: Bool, completion: @escaping (HttpRequest, QueryDeparturesResult) -> Void) -> AsyncRequest {
        fatalError("\(#function) not implemented")
    }
    
    public final func queryTrips(from: Location, via: Location?, to: Location, date: Date, departure: Bool, products: [Product]?, optimize: Optimize?, walkSpeed: WalkSpeed?, accessibility: Accessibility?, options: [Option]?, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        return queryTrips(from: from, via: via, to: to, date: date, departure: departure, tripOptions: TripOptions(products: products, optimize: optimize, walkSpeed: walkSpeed, accessibility: accessibility, options: options), completion: completion)
    }
    
    public func queryTrips(from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        fatalError("\(#function) not implemented")
    }
    
    public func queryMoreTrips(context: QueryTripsContext, later: Bool, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        fatalError("\(#function) not implemented")
    }
    
    public func refreshTrip(context: RefreshTripContext, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        fatalError("\(#function) not implemented")
    }
    
    public func queryJourneyDetail(context: QueryJourneyDetailContext, completion: @escaping (HttpRequest, QueryJourneyDetailResult) -> Void) -> AsyncRequest {
        fatalError("\(#function) not implemented")
    }
    
    public func queryWagonSequence(line: Line, stationId: String, departureTime: Date, completion: @escaping (HttpRequest, QueryWagonSequenceResult) -> Void) -> AsyncRequest {
        return AsyncRequest(task: nil)
    }
    
    // MARK: Parsing methods
    
    func suggestLocationsParsing(request: HttpRequest, constraint: String, types: [LocationType]?, maxLocations: Int, completion: @escaping (HttpRequest, SuggestLocationsResult) -> Void) throws {
        fatalError("\(#function) not implemented")
    }
    
    func queryNearbyLocationsByCoordinateParsing(request: HttpRequest, location: Location, types: [LocationType]?, maxDistance: Int, maxLocations: Int, completion: @escaping (HttpRequest, NearbyLocationsResult) -> Void) throws {
        fatalError("\(#function) not implemented")
    }
    
    func queryDeparturesParsing(request: HttpRequest, stationId: String, departures: Bool, time: Date?, maxDepartures: Int, equivs: Bool, completion: @escaping (HttpRequest, QueryDeparturesResult) -> Void) throws {
        fatalError("\(#function) not implemented")
    }
    
    func queryTripsParsing(request: HttpRequest, from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions, previousContext: QueryTripsContext?, later: Bool, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) throws {
        fatalError("\(#function) not implemented")
    }
    
    func refreshTripParsing(request: HttpRequest, context: RefreshTripContext, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) throws {
        fatalError("\(#function) not implemented")
    }
    
    func queryJourneyDetailParsing(request: HttpRequest, context: QueryJourneyDetailContext, completion: @escaping (HttpRequest, QueryJourneyDetailResult) -> Void) throws {
        fatalError("\(#function) not implemented")
    }
    
    func queryWagonSequenceParsing(request: HttpRequest, line: Line, stationId: String, departureTime: Date, completion: @escaping (HttpRequest, QueryWagonSequenceResult) -> Void) throws {
        fatalError("\(#function) not implemented")
    }
    
    // MARK: Utility methods
    
    func makeRequest(_ httpRequest: HttpRequest, parseHandler: @escaping () throws -> Void, errorHandler: @escaping (Error) -> Void, caller: String = #function) -> AsyncRequest {
        return HttpClient.get(httpRequest: httpRequest) { result in
            switch result {
            case .success((_, let data)):
                httpRequest.responseData = data
                do {
                    try parseHandler()
                } catch let err as ParseError {
                    os_log("%{public}@ parse error: %{public}@", log: .requestLogger, type: .error, caller, err.reason)
                    errorHandler(err)
                } catch let err {
                    os_log("%{public}@ handle response error: %{public}@", log: .requestLogger, type: .error, caller, (err as NSError).description)
                    errorHandler(err)
                }
            case .failure(let err):
                os_log("%{public}@ network error: %{public}@", log: .requestLogger, type: .error, caller, (err as NSError).description)
                if case .invalidStatusCode(_, let data) = err {
                    httpRequest.responseData = data
                }
                errorHandler(err)
            }
        }
    }
    
    func getResponse(from request: HttpRequest) throws -> JSON {
        guard let data = request.responseData, let json = try? JSON(data: data) else {
            throw ParseError(reason: "failed to get data")
        }
        return json
    }
    
    func lineStyle(network: String?, product: Product?, label: String?) -> LineStyle {
        var style: LineStyle?
        if let product = product {
            if let network = network {
                style = styles["\(network)|\(product.rawValue + (label ?? ""))"]
                if let style = style {
                    return style
                }
                
                style = styles["\(network)|\(product.rawValue)"]
                if let style = style {
                    return style
                }
                
                if product == .bus, let label = label, label.hasPrefix("N") {
                    style = styles["\(network)|BN"]
                    if let style = style {
                        return style
                    }
                }
            }
            
            style = styles[product.rawValue + (label ?? "")]
            if let style = style {
                return style
            }
            
            style = styles[product.rawValue]
            if let style = style {
                return style
            }
            
            if product == .bus, let label = label, label.hasPrefix("N") {
                style = styles["BN"]
                if let style = style {
                    return style
                }
            }
        }
        
        if let product = product {
            switch product {
            case .highSpeedTrain:
                if label?.starts(with: "FLX") ?? false {
                    return LineStyle(shape: .rect, backgroundColor: LineStyle.white, backgroundColor2: 0, foregroundColor: LineStyle.parseColor("#6fd000"), borderColor: LineStyle.parseColor("#6fd000"))
                } else if label?.starts(with: "TGV") ?? false {
                    return LineStyle(shape: .rect, backgroundColor: LineStyle.white, backgroundColor2: 0, foregroundColor: LineStyle.parseColor("#034c9c"), borderColor: LineStyle.parseColor("#034c9c"))
                } else {
                    return LineStyle(shape: .rect, backgroundColor: LineStyle.white, backgroundColor2: 0, foregroundColor: LineStyle.red, borderColor: LineStyle.red)
                }
            case .regionalTrain:
                return LineStyle(shape: .rect, backgroundColor: LineStyle.gray, backgroundColor2: 0, foregroundColor: LineStyle.white, borderColor: 0)
            case .suburbanTrain:
                return LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#006e34"), backgroundColor2: 0, foregroundColor: LineStyle.white, borderColor: 0)
            case .subway:
                return LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#003090"), backgroundColor2: 0, foregroundColor: LineStyle.white, borderColor: 0)
            case .tram:
                return LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#cc0000"), backgroundColor2: 0, foregroundColor: LineStyle.white, borderColor: 0)
            case .bus:
                if label?.starts(with: "FLX") ?? false {
                    // Flixmobility
                    return LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#6fd000"), backgroundColor2: 0, foregroundColor: LineStyle.white, borderColor: 0)
                } else {
                    return LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#993399"), backgroundColor2: 0, foregroundColor: LineStyle.white, borderColor: 0)
                }
            case .ferry:
                return LineStyle(shape: .circle, backgroundColor: LineStyle.blue, backgroundColor2: 0, foregroundColor: LineStyle.white, borderColor: 0)
            default:
                return LineStyle(shape: .rounded, backgroundColor: LineStyle.darkGray, backgroundColor2: 0, foregroundColor: LineStyle.white, borderColor: 0)
            }
        } else {
            return LineStyle(shape: .rounded, backgroundColor: LineStyle.darkGray, backgroundColor2: 0, foregroundColor: LineStyle.white, borderColor: 0)
        }
    }
    
    func normalize(stationId: String?) -> String? {
        guard let stationId = stationId, !stationId.isEmpty else { return nil }
        var normalized = stationId
        while !normalized.isEmpty && normalized[0] == "0" {
            normalized.remove(at: normalized.startIndex)
        }
        return normalized
    }
    
    func stripLineFromDestination(line: Line, destinationName: String?) -> String? {
        guard let destinationName = destinationName else { return nil }
        guard let label = line.label else { return destinationName }
        
        if destinationName.hasPrefix(label + " ") {
            return destinationName.substring(from: label.count + 1)
        } else {
            return destinationName
        }
    }
    
    let P_NAME_SECTION = try! NSRegularExpression(pattern: "^(\\d{1,5})\\s*([A-Z](?:\\s*-?\\s*[A-Z])?)?$", options: .caseInsensitive)
    let P_NAME_NOSW = try! NSRegularExpression(pattern: "^(\\d{1,5})\\s*(Nord|Süd|Ost|West)$", options: .caseInsensitive)
    
    func parsePosition(position: String?) -> String? {
        guard let position = position, !position.isEmpty else { return nil }
        if let match = position.match(pattern: P_NAME_SECTION) {
            let name = match[0] ?? ""
            if let m = match[1] {
                return (name + m.components(separatedBy: .whitespaces).joined()).emptyToNil
            } else {
                return name.emptyToNil
            }
        }
        if let match = position.match(pattern: P_NAME_NOSW) {
            return (match[0] ?? "" + (match[1]?.substring(to: 1) ?? "")).emptyToNil
        }
        if position.count > 10 { return nil }
        return position
    }
    
    func encodeJson(dict: [String: Any], requestUrlEncoding: String.Encoding) -> String? {
        do {
            return String(data: try JSONSerialization.data(withJSONObject: dict, options: []), encoding: requestUrlEncoding)
        } catch {
            return nil
        }
    }
    
}

public class QueryTripsContext: NSObject, NSSecureCoding {
    
    public class var supportsSecureCoding: Bool { return true }
    
    public var canQueryEarlier: Bool { return false }
    
    public var canQueryLater: Bool { return false }
    
    public override init() {
    }
    
    public required init?(coder aDecoder: NSCoder) {
    }
    
    public func encode(with aCoder: NSCoder) {
    }
    
}

public class QueryJourneyDetailContext: NSObject, NSSecureCoding { // TODO: make all public
    
    public class var supportsSecureCoding: Bool { return true }
    
    public override init() {
    }
    
    public required init?(coder aDecoder: NSCoder) {
    }
    
    public func encode(with aCoder: NSCoder) {
    }
}

public class QueryWagonSequenceContext: NSObject, NSSecureCoding { // TODO: make all public
    
    public class var supportsSecureCoding: Bool { return true }
    
    public override init() {
    }
    
    public required init?(coder aDecoder: NSCoder) {
    }
    
    public func encode(with aCoder: NSCoder) {
    }
}

public class RefreshTripContext: NSObject, NSSecureCoding { // TODO: make all public
    
    public class var supportsSecureCoding: Bool { return true }
    
    public override init() {
    }
    
    public required init?(coder aDecoder: NSCoder) {
    }
    
    public func encode(with aCoder: NSCoder) {
    }
}
