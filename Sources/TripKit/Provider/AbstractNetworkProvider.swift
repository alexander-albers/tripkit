import Foundation

public class AbstractNetworkProvider: NetworkProvider {
    
    public let id: NetworkId
    public var supportedQueryTraits: Set<QueryTrait> { return [] }
    
    public var styles: [String: LineStyle] = [:]
    var numTripsRequested = 6
    public var timeZone: TimeZone = TimeZone(abbreviation: "CET")!
    
    init(networkId: NetworkId) {
        self.id = networkId
    }
    
    public func suggestLocations(constraint: String, types: [LocationType]?, maxLocations: Int, completion: @escaping (HttpRequest, SuggestLocationsResult) -> Void) -> AsyncRequest {
        fatalError("suggest locations has not been implemented.")
    }
    
    public func queryNearbyLocations(location: Location, types: [LocationType]?, maxDistance: Int, maxLocations: Int, completion: @escaping (HttpRequest, NearbyLocationsResult) -> Void) -> AsyncRequest {
        fatalError("query nearby locations has not been implemented.")
    }
    
    public final func queryTrips(from: Location, via: Location?, to: Location, date: Date, departure: Bool, products: [Product]?, optimize: Optimize?, walkSpeed: WalkSpeed?, accessibility: Accessibility?, options: [Option]?, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        return queryTrips(from: from, via: via, to: to, date: date, departure: departure, tripOptions: TripOptions(products: products, optimize: optimize, walkSpeed: walkSpeed, accessibility: accessibility, options: options), completion: completion)
    }
    
    public func queryTrips(from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        fatalError("query trips has not been implemented.")
    }
    
    public func queryMoreTrips(context: QueryTripsContext, later: Bool, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        fatalError("query more trips has not been implemented.")
    }
    
    public func refreshTrip(context: RefreshTripContext, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        fatalError("refresh trip has not been implemented.")
    }
    
    public func queryDepartures(stationId: String, departures: Bool, time: Date?, maxDepartures: Int, equivs: Bool, completion: @escaping (HttpRequest, QueryDeparturesResult) -> Void) -> AsyncRequest {
        fatalError("query departuers has not been implemented.")
    }
    
    public func queryJourneyDetail(context: QueryJourneyDetailContext, completion: @escaping (HttpRequest, QueryJourneyDetailResult) -> Void) -> AsyncRequest {
        fatalError("query journey detail has not been implemented.")
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
                return LineStyle(shape: .rect, backgroundColor: LineStyle.white, backgroundColor2: 0, foregroundColor: LineStyle.red, borderColor: LineStyle.red)
                
            case .regionalTrain:
                return LineStyle(shape: .rect, backgroundColor: LineStyle.gray, backgroundColor2: 0, foregroundColor: LineStyle.white, borderColor: 0)
            case .suburbanTrain:
                return LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#006e34"), backgroundColor2: 0, foregroundColor: LineStyle.white, borderColor: 0)
            case .subway:
                return LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#003090"), backgroundColor2: 0, foregroundColor: LineStyle.white, borderColor: 0)
            case .tram:
                return LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#cc0000"), backgroundColor2: 0, foregroundColor: LineStyle.white, borderColor: 0)
            case .bus:
                return LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#993399"), backgroundColor2: 0, foregroundColor: LineStyle.white, borderColor: 0)
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
        guard let position = position else { return nil }
        if let match = position.match(pattern: P_NAME_SECTION) {
            let name = match[0] ?? ""
            if let m = match[1] {
                return name + m.components(separatedBy: .whitespaces).joined()
            } else {
                return name
            }
        }
        if let match = position.match(pattern: P_NAME_NOSW) {
            return match[0] ?? "" + (match[1]?.substring(to: 1) ?? "")
        }
        return position
    }
    
}

public class QueryTripsContext: NSObject, NSSecureCoding {
    
    public static var supportsSecureCoding: Bool { return true }
    
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

public class RefreshTripContext: NSObject, NSSecureCoding { // TODO: make all public
    
    public class var supportsSecureCoding: Bool { return true }
    
    public override init() {
    }
    
    public required init?(coder aDecoder: NSCoder) {
    }
    
    public func encode(with aCoder: NSCoder) {
    }
}
