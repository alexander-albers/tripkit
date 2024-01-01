import Foundation
import os.log
import SWXMLHash
import SwiftyJSON

public class AbstractEfaProvider: AbstractNetworkProvider {
    
    override public var supportedQueryTraits: Set<QueryTrait> { [.maxChanges, .maxFootpathTime] }
    
    let departureMonitorEndpoint: String
    let tripEndpoint: String
    let stopFinderEndpoint: String
    let coordEndpoint: String
    let tripStopTimesEndpoint: String
    
    static let DEFAULT_DEPARTURE_MONITOR_ENDPOINT = "XSLT_DM_REQUEST"
    static let DEFAULT_TRIP_ENDPOINT = "XSLT_TRIP_REQUEST2"
    static let DEFAULT_STOPFINDER_ENDPOINT = "XML_STOPFINDER_REQUEST"
    static let DEFAULT_COORD_ENDPOINT = "XML_COORD_REQUEST"
    static let DEFAULT_TRIPSTOPTIMES_ENDPOINT = "XML_STOPSEQCOORD_REQUEST"
    
    lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        dateFormatter.timeZone = timeZone
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateFormatter
    }()
    lazy var timeFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HHmm"
        dateFormatter.timeZone = timeZone
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateFormatter
    }()
    
    var includeRegionId: Bool = true
    var useRouteIndexAsTripId: Bool = true
    var requestUrlEncoding: String.Encoding = .utf8
    var needsSpEncId: Bool = false
    var useLineRestriction: Bool = true
    var useProxFootSearch: Bool = true
    var useStatelessTripContexts = false
    
    init(networkId: NetworkId, departureMonitorEndpoint: String, tripEndpoint: String, stopFinderEndpoint: String, coordEndpoint: String, tripStopTimesEndpoint: String) {
        self.departureMonitorEndpoint = departureMonitorEndpoint
        self.tripEndpoint = tripEndpoint
        self.stopFinderEndpoint = stopFinderEndpoint
        self.coordEndpoint = coordEndpoint
        self.tripStopTimesEndpoint = tripStopTimesEndpoint
        
        super.init(networkId: networkId)
    }
    
    init(networkId: NetworkId, apiBase: String, departureMonitorEndpoint: String = AbstractEfaProvider.DEFAULT_DEPARTURE_MONITOR_ENDPOINT, tripEndpoint: String = AbstractEfaProvider.DEFAULT_TRIP_ENDPOINT, stopFinderEndpoint: String = AbstractEfaProvider.DEFAULT_STOPFINDER_ENDPOINT, coordEndpoint: String = AbstractEfaProvider.DEFAULT_COORD_ENDPOINT, tripStopTimesEndpoint: String = AbstractEfaProvider.DEFAULT_TRIPSTOPTIMES_ENDPOINT) {
        self.departureMonitorEndpoint = apiBase + departureMonitorEndpoint
        self.tripEndpoint = apiBase + tripEndpoint
        self.stopFinderEndpoint = apiBase + stopFinderEndpoint
        self.coordEndpoint = apiBase + coordEndpoint
        self.tripStopTimesEndpoint = apiBase + tripStopTimesEndpoint
        
        super.init(networkId: networkId)
    }
    
    init(networkId: NetworkId, apiBase: String) {
        self.departureMonitorEndpoint = apiBase + AbstractEfaProvider.DEFAULT_DEPARTURE_MONITOR_ENDPOINT
        self.tripEndpoint = apiBase + AbstractEfaProvider.DEFAULT_TRIP_ENDPOINT
        self.stopFinderEndpoint = apiBase + AbstractEfaProvider.DEFAULT_STOPFINDER_ENDPOINT
        self.coordEndpoint = apiBase + AbstractEfaProvider.DEFAULT_COORD_ENDPOINT
        self.tripStopTimesEndpoint = apiBase + AbstractEfaProvider.DEFAULT_TRIPSTOPTIMES_ENDPOINT
        
        super.init(networkId: networkId)
    }
    
    // MARK: Request parameters
    
    func stopFinderRequestParameters(builder: UrlBuilder, constraint: String, types: [LocationType]?, maxLocations: Int, outputFormat: String) {
        appendCommonRequestParameters(builder: builder, outputFormat: outputFormat)
        builder.addParameter(key: "locationServerActive", value: 1)
        
        if includeRegionId {
            builder.addParameter(key: "regionID_sf", value: 1)
        }
        builder.addParameter(key: "type_sf", value: "any")
        builder.addParameter(key: "name_sf", value: constraint)
        if needsSpEncId {
            builder.addParameter(key: "SpEncId", value: 0)
        }
        // 1=place 2=stop 4=street 8=address 16=crossing 32=poi 64=postcode
        var filter = 0
        if types == nil || types!.contains(.station) {
            filter += 2
        }
        if types == nil || types!.contains(.poi) {
            filter += 32
        }
        if types == nil || types!.contains(.address) {
            filter += 4 + 8 + 16 + 64
        }
        builder.addParameter(key: "anyObjFilter_sf", value: filter)
        builder.addParameter(key: "reducedAnyPostcodeObjFilter_sf", value: 64)
        builder.addParameter(key: "reducedAnyTooManyObjFilter_sf", value: 2)
        builder.addParameter(key: "useHouseNumberList", value: true)
        if maxLocations > 0 {
            builder.addParameter(key: "anyMaxSizeHitList", value: maxLocations)
        }
    }
    
    func nearbyStationsRequestParameters(builder: UrlBuilder, stationId: String, maxLocations: Int) {
        appendCommonRequestParameters(builder: builder, outputFormat: "XML")
        builder.addParameter(key: "type_dm", value: "stop")
        builder.addParameter(key: "name_dm", value: normalize(stationId: stationId))
        builder.addParameter(key: "itOptionsActive", value: 1)
        builder.addParameter(key: "ptOptionsActive", value: 1)
        if useProxFootSearch {
            builder.addParameter(key: "useProxFootSearch", value: 1)
        }
        builder.addParameter(key: "mergeDep", value: 1)
        builder.addParameter(key: "useAllStops", value: 1)
        builder.addParameter(key: "mode", value: "direct")
    }
    
    func commandLink(builder: UrlBuilder, sessionId: String, requestId: String) {
        builder.addParameter(key: "sessionID", value: sessionId)
        builder.addParameter(key: "requestID", value: requestId)
        builder.addParameter(key: "calcNumberOfTrips", value: numTripsRequested)
    }
    
    func queryTripsParameters(builder: UrlBuilder, from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions) {
        appendCommonRequestParameters(builder: builder, outputFormat: "XML")
        builder.addParameter(key: "sessionID", value: 0)
        builder.addParameter(key: "requestID", value: 0)
        builder.addParameter(key: "coordListOutputFormat", value: "STRING")
        appendLocation(builder: builder, location: from, suffix: "origin")
        appendLocation(builder: builder, location: to, suffix: "destination")
        if let via = via {
            appendLocation(builder: builder, location: via, suffix: "via")
        }
        appendDate(builder: builder, date: date)
        builder.addParameter(key: "itdTripDateTimeDepArr", value: departure ? "dep" : "arr")
        builder.addParameter(key: "calcNumberOfTrips", value: numTripsRequested)
        builder.addParameter(key: "ptOptionsActive", value: 1) // enable public transport options
        builder.addParameter(key: "itOptionsActive", value: 1) // enable individual transport options
        
        if let optimize = tripOptions.optimize {
            switch optimize {
            case .leastDuration:
                builder.addParameter(key: "routeType", value: "LEASTTIME")
                break
            case .leastChanges:
                builder.addParameter(key: "routeType", value: "LEASTINTERCHANGE")
                break
            case .leastWalking:
                builder.addParameter(key: "routeType", value: "LEASTWALKING")
                break
            }
        }
        if let walkSpeed = tripOptions.walkSpeed {
            switch walkSpeed {
            case .slow:
                builder.addParameter(key: "changeSpeed", value: "slow")
                break
            case .normal:
                builder.addParameter(key: "changeSpeed", value: "normal")
                break
            case .fast:
                builder.addParameter(key: "changeSpeed", value: "fast")
                break
            }
        }
        if let accessibility = tripOptions.accessibility {
            if accessibility == .barrierFree {
                builder.addParameter(key: "imparedOptionsActive", value: 1)
                builder.addParameter(key: "wheelchair", value: "on")
                builder.addParameter(key: "noSolidStairs", value: "on")
            } else if accessibility == .limited {
                builder.addParameter(key: "imparedOptionsActive", value: 1)
                builder.addParameter(key: "wheelchair", value: "on")
                builder.addParameter(key: "lowPlatformVhcl", value: "on")
                builder.addParameter(key: "noSolidStairs", value: "on")
            }
        }
        
        if let products = tripOptions.products {
            builder.addParameter(key: "includedMeans", value: "checkbox")
            
            for product in products {
                switch product {
                case .highSpeedTrain:
                    builder.addParameter(key: "inclMOT_0", value: "on")
                    builder.addParameter(key: "inclMOT_14", value: "on")
                    builder.addParameter(key: "inclMOT_15", value: "on")
                    builder.addParameter(key: "inclMOT_16", value: "on")
                case .regionalTrain:
                    builder.addParameter(key: "inclMOT_0", value: "on")
                    builder.addParameter(key: "inclMOT_11", value: "on")
                    builder.addParameter(key: "inclMOT_13", value: "on")
                    builder.addParameter(key: "inclMOT_18", value: "on")
                case .suburbanTrain:
                    builder.addParameter(key: "inclMOT_1", value: "on")
                case .subway:
                    builder.addParameter(key: "inclMOT_2", value: "on")
                case .tram:
                    builder.addParameter(key: "inclMOT_3", value: "on")
                    builder.addParameter(key: "inclMOT_4", value: "on")
                case .bus:
                    builder.addParameter(key: "inclMOT_5", value: "on")
                    builder.addParameter(key: "inclMOT_6", value: "on")
                    builder.addParameter(key: "inclMOT_7", value: "on")
                    builder.addParameter(key: "inclMOT_17", value: "on")
                    builder.addParameter(key: "inclMOT_19", value: "on")
                case .cablecar:
                    builder.addParameter(key: "inclMOT_8", value: "on")
                case .ferry:
                    builder.addParameter(key: "inclMOT_9", value: "on")
                case .onDemand:
                    builder.addParameter(key: "inclMOT_10", value: "on")
                }
            }
            if useLineRestriction && products.contains(.regionalTrain) && !products.contains(.highSpeedTrain) {
                builder.addParameter(key: "lineRestriction", value: "403")
            }
        }
        
        if useProxFootSearch {
            builder.addParameter(key: "useProxFootSearch", value: 1) // walk if it makes journeys quicker
        }
        builder.addParameter(key: "trITMOTvalue100", value: tripOptions.maxFootpathTime ?? 10) // maximum time to walk to first or from last stop
        
        if let options = tripOptions.options, options.contains(.bike) {
            builder.addParameter(key: "bikeTakeAlong", value: 1)
        }
        
        if let maxChanges = tripOptions.maxChanges {
            builder.addParameter(key: "maxChanges", value: maxChanges)
        }
        
        builder.addParameter(key: "locationServerActive", value: 1)
        builder.addParameter(key: "useRealtime", value: 1)
        builder.addParameter(key: "nextDepsPerLeg", value: 1)
    }
    
    func coordRequestParameters(builder: UrlBuilder, types: [LocationType]?, lat: Int, lon: Int, maxDistance: Int, maxLocations: Int) {
        appendCommonRequestParameters(builder: builder, outputFormat: "XML")
        builder.addParameter(key: "coord", value: String(format: "%2.6f:%2.6f:WGS84", Double(lon) / 1e6, Double(lat) / 1e6))
        builder.addParameter(key: "coordListOutputFormat", value: "STRING")
        builder.addParameter(key: "max", value: maxLocations == 0 ? 50 : maxLocations)
        builder.addParameter(key: "inclFilter", value: 1)
        for (index, type) in (types ?? [.station]).enumerated() {
            builder.addParameter(key: "radius_\(index + 1)", value: maxDistance == 0 ? 1320 : maxDistance)
            builder.addParameter(key: "type_\(index + 1)", value: type == .poi ? "POI_POINT" : "STOP")
        }
    }
    
    func appendDate(builder: UrlBuilder, date: Date, dateParam: String = "itdDate", timeParam: String = "itdTime") {
        builder.addParameter(key: dateParam, value: dateFormatter.string(from: date))
        builder.addParameter(key: timeParam, value: timeFormatter.string(from: date))
    }
    
    func queryDeparturesParameters(builder: UrlBuilder, stationId: String, departures: Bool, time: Date?, maxDepartures: Int, equivs: Bool) {
        appendCommonRequestParameters(builder: builder, outputFormat: "XML")
        builder.addParameter(key: "type_dm", value: "stop")
        builder.addParameter(key: "name_dm", value: stationId)
        if let time = time {
            appendDate(builder: builder, date: time)
        }
        builder.addParameter(key: "useRealtime", value: 1)
        builder.addParameter(key: "mode", value: "direct")
        builder.addParameter(key: "ptOptionsActive", value: 1)
        builder.addParameter(key: "deleteAssignedStops_dm", value: equivs ? 0 : 1)
        if useProxFootSearch {
            builder.addParameter(key: "useProxFootSearch", value: equivs ? 1 : 0)
        }
        builder.addParameter(key: "mergeDep", value: 1)
        if maxDepartures > 0 {
            builder.addParameter(key: "limit", value: maxDepartures)
        }
        builder.addParameter(key: "itdDateTimeDepArr", value: departures ? "dep" : "arr")
    }
    
    func appendCommonRequestParameters(builder: UrlBuilder, outputFormat: String? = "JSON") {
        if let outputFormat = outputFormat {
            builder.addParameter(key: "outputFormat", value: outputFormat)
        }
        builder.addParameter(key: "language", value: queryLanguage ?? defaultLanguage)
        builder.addParameter(key: "stateless", value: 1)
        builder.addParameter(key: "coordOutputFormat", value: "WGS84")
    }
    
    func appendLocation(builder: UrlBuilder, location: Location, suffix: String) {
        switch (location.type, normalize(stationId: location.id), location.coord) {
        case let (.station, id?, _):
            builder.addParameter(key: "type_\(suffix)", value: "stop")
            builder.addParameter(key: "name_\(suffix)", value: id)
        case let (.poi, id?, _):
            builder.addParameter(key: "type_\(suffix)", value: "poi")
            builder.addParameter(key: "name_\(suffix)", value: id)
        case let (.address, id?, _):
            builder.addParameter(key: "type_\(suffix)", value: "any")
            builder.addParameter(key: "name_\(suffix)", value: id)
        case let (type, _, coord?) where type == .coord || type == .address:
            builder.addParameter(key: "type_\(suffix)", value: "coord")
            builder.addParameter(key: "name_\(suffix)", value: String(format: "%.6f:%.6f:WGS84", Double(coord.lon) / 1e6, Double(coord.lat) / 1e6))
        default:
            builder.addParameter(key: "type_\(suffix)", value: "any")
            builder.addParameter(key: "name_\(suffix)", value: location.getUniqueLongName())
        }
    }
    
    func locationValue(location: Location) -> String {
        return location.id ?? location.getUniqueLongName()
    }
    
    // MARK: Response parse methods
    
    func checkSessionExpired(httpRequest: HttpRequest, err: Error, completion: (HttpRequest, QueryTripsResult) -> Void) {
        if let err = err as? HttpError {
            switch err {
            case .invalidStatusCode(let code, let _):
                if code == 404 {
                    completion(httpRequest, .sessionExpired)
                    return
                }
            default: break
            }
        }
        completion(httpRequest, .failure(err))
    }
    
    let P_STATION_NAME_WHITESPACE = try! NSRegularExpression(pattern: "\\s+", options: .caseInsensitive)
    
    func normalizeLocationName(name: String?) -> String? {
        guard let name = name else { return nil }
        let result = P_STATION_NAME_WHITESPACE.stringByReplacingMatches(in: name, options: [], range: NSMakeRange(0, name.count), withTemplate: " ")
        if result == "" {
            return nil
        }
        return result
    }
    
    func split(directionName: String?) -> (name: String?, place: String?) {
        return (directionName, nil)
    }
    
    func processCoordinateStrings(_ coordString: String) -> [LocationPoint] {
        var path: [LocationPoint] = []
        for coords in coordString.components(separatedBy: " ") {
            if coords.isEmpty { continue }
            path.append(parseCoord(coords))
        }
        return path
    }
    
    func parseCoordinates(string: String?) -> LocationPoint? {
        if let string = string {
            let coordArr = string.components(separatedBy: ",")
            if coordArr.count == 2, let x = Double(coordArr[0]), let y = Double(coordArr[1]) {
                return LocationPoint(lat: Int(y), lon: Int(x))
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    func parseCoord(_ coordStr: String) -> LocationPoint {
        let parts = coordStr.components(separatedBy: ",")
        let lat = Int(Double(parts[1]) ?? 0)
        let lon = Int(Double(parts[0]) ?? 0)
        
        return LocationPoint(lat: lat, lon: lon)
    }
    
    let P_POSITION = try! NSRegularExpression(pattern: "(?:Gleis|Gl\\.|Bahnsteig|Bstg\\.|Bussteig|Busstg\\.|Steig|Hp\\.|Stop|Pos\\.|Zone|Platform|Stand|Bay|Stance)?\\s*(.+)", options: .caseInsensitive)
    
    override func parsePosition(position: String?) -> String? {
        guard let position = position else { return nil }
        if position.hasPrefix("Ri.") || position.hasPrefix("Richtung ") { return nil }
        if let match = position.match(pattern: P_POSITION) {
            return super.parsePosition(position: match[0])
        } else {
            return super.parsePosition(position: position)
        }
    }
    
    func parseDuration(from durationString: String?) -> TimeInterval {
        guard let components = durationString?.components(separatedBy: ":"), components.count == 2 else {
            return 0
        }
        var result: TimeInterval = 0
        result += (Double(components[0]) ?? 0) * 60 * 60 // hours
        result += (Double(components[1]) ?? 0) * 60 // minutes
        return result
    }
    
    // MARK: Line styles
    
    func parseLine(id: String?, network: String?, mot: String?, symbol: String?, name: String?, longName: String?, trainType: String?, trainNum: String?, trainName: String?) -> Line {
        if mot == nil {
            if let trainName = trainName {
                let name = name == nil ? "" : name
                switch trainName {
                case "S-Bahn":
                    return Line(id: id, network: network, product: .suburbanTrain, label: name)
                case "U-Bahn":
                    return Line(id: id, network: network, product: .subway, label: name)
                case "Straßenbahn", "Badner Bahn":
                    return Line(id: id, network: network, product: .tram, label: name)
                case "Stadtbus", "Citybus", "Regionalbus", "ÖBB-Postbus", "Autobus", "Discobus", "Nachtbus", "Anrufsammeltaxi", "Ersatzverkehr", "Vienna Airport Lines":
                    return Line(id: id, network: network, product: .bus, label: name)
                default:
                    break
                }
            }
        } else {
            let mot = mot!
            let symbolName: String?
            if let symbol = symbol, !symbol.isEmpty {
                symbolName = symbol
            } else {
                symbolName = name
            }
            if mot == "0" {
                let trainNum = trainNum ?? ""
                let trainName = trainName ?? ""
                let trainType = trainType  ?? ""
                let symbol = symbol ?? ""
                
                if ("EC" == trainType || "EuroCity" == trainName || "Eurocity" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "EC\(trainNum)")
                } else if ("EN" == trainType || "EuroNight" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "EN\(trainNum)")
                } else if ("IC" == trainType || "IC" == trainName || "InterCity" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "IC\(trainNum)")
                } else if ("ICE" == trainType || "ICE" == trainName || "Intercity-Express" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "ICE\(trainNum)")
                } else if ("ICN" == trainType || "InterCityNight" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "ICN\(trainNum)")
                } else if ("X" == trainType || "InterConnex" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "X\(trainNum)")
                } else if ("CNL" == trainType || "CityNightLine" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "CNL\(trainNum)")
                } else if ("THA" == trainType || "Thalys" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "THA\(trainNum)")
                } else if "RHI" == trainType && trainNum != "" {
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "RHI\(trainNum)")
                } else if ("TGV" == trainType || "TGV" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "TGV\(trainNum)")
                } else if "TGD" == trainType && trainNum != "" {
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "TGD\(trainNum)")
                } else if "INZ" == trainType && trainNum != "" {
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "INZ\(trainNum)")
                } else if ("RJ" == trainType || "railjet" == trainName) { // railjet
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "RJ\(trainNum)")
                } else if ("RJX" == trainType || "railjet xpress" == trainName) { // railjet
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "RJX\(trainNum)")
                } else if ("WB" == trainType || "WESTbahn" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "WB\(trainNum)")
                } else if ("HKX" == trainType || "Hamburg-Köln-Express" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "HKX\(trainNum)")
                } else if "INT" == trainType && trainNum != "" { // SVV, VAGFR
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "INT\(trainNum)")
                } else if ("SC" == trainType || "SC Pendolino" == trainName) && trainNum != "" { // SuperCity
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "SC\(trainNum)")
                } else if "ECB" == trainType && trainNum != "" { // EC, Verona-München
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "ECB\(trainNum)")
                } else if "ES" == trainType && trainNum != "" { // Eurostar Italia
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "ES\(trainNum)")
                } else if ("EST" == trainType || "EUROSTAR" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "EST\(trainNum)")
                } else if "EIC" == trainType && trainNum != "" { // Ekspres InterCity, Polen
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "EIC\(trainNum)")
                } else if "MT" == trainType && "Schnee-Express" == trainName && trainNum != "" {
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "MT\(trainNum)")
                } else if ("TLK" == trainType || "Tanie Linie Kolejowe" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "TLK\(trainNum)")
                } else if "DNZ" == trainType && trainNum != "" { // Nacht-Schnellzug
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "DNZ\(trainNum)")
                } else if "AVE" == trainType && trainNum != "" { // klimatisierter Hochgeschwindigkeitszug
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "DNZ\(trainNum)")
                } else if "ARC" == trainType && trainNum != "" { // Arco/Alvia/Avant (Renfe), Spanien
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "ARC\(trainNum)")
                } else if "HOT" == trainType && trainNum != "" { // Spanien, Nacht
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "HOT\(trainNum)")
                } else if "LCM" == trainType && "Locomore" == trainName && trainNum != "" {
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "LCM\(trainNum)")
                } else if "Locomore" == longName {
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "LOC\(trainNum)")
                } else if "NJ" == trainType {
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "NJ\(trainNum)")
                } else if "FLX" == trainType && trainName == "FlixTrain" {
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "FLX\(trainNum)")
                    
                } else if "IR" == trainType || "Interregio" == trainName || "InterRegio" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "IR\(trainNum)")
                } else if "IRE" == trainType || "Interregio-Express" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "IRE\(trainNum)")
                } else if "InterRegioExpress" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "IRE\(trainNum)")
                } else if "RE" == trainType || "Regional-Express" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "RE\(trainNum)")
                } else if trainType == "" && trainNum != "" && (trainNum =~ "RE ?\\d+") {
                    return Line(id: id, network: network, product: .regionalTrain, label: trainNum)
                } else if "RE6a" == trainNum && trainType == "" && trainName == "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: trainNum)
                } else if "RE3 / RB30" == trainNum && trainType == "" && trainName == "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "RE3/RB30")
                } else if "Regionalexpress" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: symbol)
                } else if "R-Bahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: symbol)
                } else if "RB-Bahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: symbol)
                } else if trainType == "" && "RB67/71" == trainNum {
                    return Line(id: id, network: network, product: .regionalTrain, label: trainNum)
                } else if trainType == "" && "RB65/68" == trainNum {
                    return Line(id: id, network: network, product: .regionalTrain, label: trainNum)
                } else if "RE-Bahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: symbol)
                } else if "REX" == trainType { // RegionalExpress, Österreich
                    return Line(id: id, network: network, product: .regionalTrain, label: "REX\(trainNum)")
                } else if ("RB" == trainType || "Regionalbahn" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "RB\(trainNum)")
                } else if trainType == "" && trainNum != "" && (trainNum =~ "RB ?\\d+") {
                    return Line(id: id, network: network, product: .regionalTrain, label: trainNum)
                } else if "Abellio-Zug" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: symbol)
                } else if "Westfalenbahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: symbol)
                } else if "Chiemseebahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: symbol)
                } else if "R" == trainType || "Regionalzug" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "R\(trainNum)")
                } else if trainType == "" && trainNum != "" && (trainNum =~ "R ?\\d+") {
                    return Line(id: id, network: network, product: .regionalTrain, label: trainNum)
                } else if "D" == trainType || "Schnellzug" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "D\(trainNum)")
                } else if "E" == trainType || "Eilzug" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "E\(trainNum)")
                } else if "WFB" == trainType || "WestfalenBahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "WFB\(trainNum)")
                } else if ("NWB" == trainType || "NordWestBahn" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "NWB\(trainNum)")
                } else if "WES" == trainType || "Westbahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "WES\(trainNum)")
                } else if "ERB" == trainType || "eurobahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "ERB\(trainNum)")
                } else if "CAN" == trainType || "cantus Verkehrsgesellschaft" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "CAN\(trainNum)")
                } else if "HEX" == trainType || "Veolia Verkehr Sachsen-Anhalt" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "HEX\(trainNum)")
                } else if "EB" == trainType || "Erfurter Bahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "EB\(trainNum)")
                } else if "Erfurter Bahn" == longName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "EB")
                } else if "EBx" == trainType || "Erfurter Bahn Express" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "EBx\(trainNum)")
                } else if "Erfurter Bahn Express" == longName && symbol == "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "EBx")
                } else if "MR" == trainType && "Märkische Regiobahn" == trainName && trainNum != "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "MR\(trainNum)")
                } else if "MRB" == trainType || "Mitteldeutsche Regiobahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "MRB\(trainNum)")
                } else if "ABR" == trainType || "ABELLIO Rail NRW GmbH" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "ABR\(trainNum)")
                } else if "NEB" == trainType || "NEB Niederbarnimer Eisenbahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "NEB\(trainNum)")
                } else if "OE" == trainType || "Ostdeutsche Eisenbahn GmbH" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "OE\(trainNum)")
                } else if "Ostdeutsche Eisenbahn GmbH" == longName && symbol == "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "OE");
                } else if "ODE" == trainType && symbol != "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: symbol)
                } else if "OLA" == trainType || "Ostseeland Verkehr GmbH" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "OLA\(trainNum)")
                } else if "UBB" == trainType || "Usedomer Bäderbahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "UBB\(trainNum)")
                } else if "EVB" == trainType || "ELBE-WESER GmbH" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "EVB\(trainNum)")
                } else if "RTB" == trainType || "Rurtalbahn GmbH" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "RTB\(trainNum)")
                } else if "STB" == trainType || "Süd-Thüringen-Bahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "STB\(trainNum)")
                } else if "HTB" == trainType || "Hellertalbahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "HTB\(trainNum)")
                } else if "VBG" == trainType || "Vogtlandbahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "VBG\(trainNum)")
                } else if "CB" == trainType || "City-Bahn Chemnitz" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "CB\(trainNum)")
                } else if trainType == "" && ("C11" == trainNum || "C13" == trainNum || "C14" == trainNum
                    || "C15" == trainNum) {
                    return Line(id: id, network: network, product: .regionalTrain, label: trainNum)
                } else if "VEC" == trainType || "vectus Verkehrsgesellschaft" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "VEC\(trainNum)")
                } else if "HzL" == trainType || "Hohenzollerische Landesbahn AG" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "HzL\(trainNum)")
                } else if "SBB" == trainType || "SBB GmbH" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "SBB\(trainNum)")
                } else if "MBB" == trainType || "Mecklenburgische Bäderbahn Molli" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "MBB\(trainNum)")
                } else if "OS" == trainType {  // Osobní vlak
                    return Line(id: id, network: network, product: .regionalTrain, label: "OS\(trainNum)")
                } else if "SP" == trainType || "Sp" == trainType { // Spěšný vlak
                    return Line(id: id, network: network, product: .regionalTrain, label: "SP\(trainNum)")
                } else if "Dab" == trainType || "Daadetalbahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "Dab\(trainNum)")
                } else if "FEG" == trainType || "Freiberger Eisenbahngesellschaft" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "FEG\(trainNum)")
                } else if "ARR" == trainType || "ARRIVA" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "ARR\(trainNum)")
                } else if "HSB" == trainType || "Harzer Schmalspurbahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "HSB\(trainNum)")
                } else if "ALX" == trainType || "alex - Länderbahn und Vogtlandbahn GmbH" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "ALX\(trainNum)")
                } else if "EX" == trainType || "Fatra" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "EX\(trainNum)")
                } else if "ME" == trainType || "metronom" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "ME\(trainNum)")
                } else if "metronom" == longName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "ME");
                } else if "MEr" == trainType {
                    return Line(id: id, network: network, product: .regionalTrain, label: "MEr\(trainNum)")
                } else if "AKN" == trainType || "AKN Eisenbahn AG" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "AKN\(trainNum)")
                } else if "SOE" == trainType || "Sächsisch-Oberlausitzer Eisenbahngesellschaft" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "SOE\(trainNum)")
                } else if "VIA" == trainType || "VIAS GmbH" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "VIA\(trainNum)")
                } else if "BRB" == trainType || "Bayerische Regiobahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "BRB\(trainNum)")
                } else if "BLB" == trainType || "Berchtesgadener Land Bahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "BLB\(trainNum)")
                } else if "HLB" == trainType || "Hessische Landesbahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "HLB\(trainNum)")
                } else if "NOB" == trainType || "NordOstseeBahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "NOB\(trainNum)")
                } else if "NBE" == trainType || "Nordbahn Eisenbahngesellschaft" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "NBE\(trainNum)")
                } else if "VEN" == trainType || "Rhenus Veniro" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "VEN\(trainType)")
                } else if "DPN" == trainType || "Nahreisezug" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "DPN\(trainNum)")
                } else if "RBG" == trainType || "Regental Bahnbetriebs GmbH" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "RBG\(trainNum)")
                } else if "BOB" == trainType || "Bodensee-Oberschwaben-Bahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "BOB\(trainNum)")
                } else if "VE" == trainType || "Vetter" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "VE\(trainNum)")
                } else if "SDG" == trainType || "SDG Sächsische Dampfeisenbahngesellschaft mbH" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "SDG\(trainNum)")
                } else if "PRE" == trainType || "Pressnitztalbahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "PRE\(trainNum)")
                } else if "VEB" == trainType || "Vulkan-Eifel-Bahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "VEB\(trainNum)")
                } else if "neg" == trainType || "Norddeutsche Eisenbahn Gesellschaft" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "neg\(trainNum)")
                } else if "AVG" == trainType || "Felsenland-Express" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "AVG\(trainNum)")
                } else if "P" == trainType || "BayernBahn Betriebs-GmbH" == trainName
                    || "Brohltalbahn" == trainName || "Kasbachtalbahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "P\(trainNum)")
                } else if "SBS" == trainType || "Städtebahn Sachsen" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "SBS\(trainNum)")
                } else if "SES" == trainType || "Städteexpress Sachsen" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "SES\(trainNum)")
                } else if "SB-" == trainType { // Städtebahn Sachsen
                    return Line(id: id, network: network, product: .regionalTrain, label: "SB\(trainNum)")
                } else if "ag" == trainType { // agilis
                    return Line(id: id, network: network, product: .regionalTrain, label: "ag\(trainNum)")
                } else if "agi" == trainType || "agilis" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "agi\(trainNum)")
                } else if "as" == trainType || "agilis-Schnellzug" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "as\(trainNum)")
                } else if "TLX" == trainType || "TRILEX" == trainName { // Trilex (Vogtlandbahn)
                    return Line(id: id, network: network, product: .regionalTrain, label: "TLX\(trainNum)")
                } else if "MSB" == trainType || "Mainschleifenbahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "MSB\(trainNum)")
                } else if "BE" == trainType || "Bentheimer Eisenbahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "BE\(trainNum)")
                } else if "erx" == trainType || "erixx - Der Heidesprinter" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "erx\(trainNum)")
                } else if ("ERX" == trainType || "Erixx" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "ERX\(trainNum)")
                } else if ("SWE" == trainType || "Südwestdeutsche Verkehrs-AG" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "SWE\(trainNum)")
                } else if "SWEG-Zug" == trainName { // Südwestdeutschen Verkehrs-Aktiengesellschaft
                    return Line(id: id, network: network, product: .regionalTrain, label: "SWEG\(trainNum)")
                } else if let longName = longName, longName.hasPrefix("SWEG-Zug") {
                    return Line(id: id, network: network, product: .regionalTrain, label: "SWEG\(trainNum)")
                } else if "EGP Eisenbahngesellschaft Potsdam" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "EGP\(trainNum)")
                } else if "ÖBB" == trainType || "ÖBB" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "ÖBB\(trainNum)")
                } else if "CAT" == trainType { // City Airport Train Wien
                    return Line(id: id, network: network, product: .regionalTrain, label: "CAT\(trainNum)")
                } else if "DZ" == trainType || "Dampfzug" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "DZ\(trainNum)")
                } else if "CD" == trainType { // Tschechien
                    return Line(id: id, network: network, product: .regionalTrain, label: "CD\(trainNum)")
                } else if "VR" == trainType { // Polen
                    return Line(id: id, network: network, product: .regionalTrain, label: symbol)
                } else if "PR" == trainType { // Polen
                    return Line(id: id, network: network, product: .regionalTrain, label: symbol)
                } else if "KD" == trainType { // Koleje Dolnośląskie (Niederschlesische Eisenbahn)
                    return Line(id: id, network: network, product: .regionalTrain, label: symbol)
                } else if "Koleje Dolnoslaskie" == trainName && symbol != "" { // Koleje Dolnośląskie
                    return Line(id: id, network: network, product: .regionalTrain, label: symbol)
                } else if "OO" == trainType || "Ordinary passenger (o.pas.)" == trainName { // GB
                    return Line(id: id, network: network, product: .regionalTrain, label: "OO\(trainNum)")
                } else if "XX" == trainType || "Express passenger    (ex.pas.)" == trainName { // GB
                    return Line(id: id, network: network, product: .regionalTrain, label: "XX\(trainNum)")
                } else if "XZ" == trainType || "Express passenger sleeper" == trainName { // GB
                    return Line(id: id, network: network, product: .regionalTrain, label: "XZ\(trainNum)")
                } else if "ATB" == trainType { // Autoschleuse Tauernbahn
                    return Line(id: id, network: network, product: .regionalTrain, label: "ATB\(trainNum)")
                } else if "ATZ" == trainType { // Autozug
                    return Line(id: id, network: network, product: .regionalTrain, label: "ATZ\(trainNum)")
                } else if "AZ" == trainType || "Auto-Zug" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "AZ\(trainNum)")
                } else if "AZS" == trainType && trainNum != "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "AZS\(trainNum)")
                } else if "DWE" == trainType || "Dessau-Wörlitzer Eisenbahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "DWE\(trainNum)")
                } else if "KTB" == trainType || "Kandertalbahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "KTB\(trainNum)")
                } else if "CBC" == trainType || "CBC" == trainName { // City-Bahn Chemnitz
                    return Line(id: id, network: network, product: .regionalTrain, label: "CBC\(trainNum)")
                } else if "Bernina Express" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: trainNum)
                } else if "STR" == trainType { // Harzquerbahn, Nordhausen
                    return Line(id: id, network: network, product: .regionalTrain, label: "STR\(trainNum)")
                } else if "EXT" == trainType || "Extrazug" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "EXT\(trainNum)")
                } else if "Heritage Railway" == trainName { // GB
                    return Line(id: id, network: network, product: .regionalTrain, label: symbol)
                } else if "WTB" == trainType || "Wutachtalbahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "WTB\(trainNum)")
                } else if "DB" == trainType || "DB Regio" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "DB\(trainNum)")
                } else if "M" == trainType && "Meridian" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "M\(trainNum)")
                } else if "M" == trainType && "Messezug" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "M\(trainNum)")
                } else if "EZ" == trainType { // ÖBB Erlebniszug
                    return Line(id: id, network: network, product: .regionalTrain, label: "EZ\(trainNum)")
                } else if "DPF" == trainType {
                    return Line(id: id, network: network, product: .regionalTrain, label: "DPF\(trainNum)")
                } else if "WBA" == trainType || "Waldbahn" == trainName {
                    return Line(id: id, network: network, product: .regionalTrain, label: "WBA\(trainNum)")
                } else if "ÖB" == trainType && "Öchsle-Bahn-Betriebsgesellschaft mbH" == trainName && trainNum != "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "ÖB\(trainNum)")
                } else if "ÖBA" == trainType && trainNum != "" { // Eisenbahn-Betriebsgesellschaft Ochsenhausen
                    return Line(id: id, network: network, product: .regionalTrain, label: "ÖBA\(trainNum)")
                } else if ("UEF" == trainType || "Ulmer Eisenbahnfreunde" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "UEF\(trainNum)")
                } else if ("DBG" == trainType || "Döllnitzbahn" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "DBG\(trainNum)")
                } else if ("TL" == trainType || "Trilex" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "TL\(trainNum)")
                } else if ("OPB" == trainType || "oberpfalzbahn" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "OPB\(trainNum)")
                } else if ("OPX" == trainType || "oberpfalz-express" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "OPX\(trainNum)")
                } else if ("LEO" == trainType || "Chiemgauer Lokalbahn" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "LEO\(trainNum)")
                } else if ("VAE" == trainType || "Voralpen-Express" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "VAE\(trainNum)")
                } else if ("V6" == trainType || "vlexx" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "vlexx\(trainNum)")
                } else if ("ARZ" == trainType || "Autoreisezug" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "ARZ\(trainNum)")
                } else if "RR" == trainType {
                    return Line(id: id, network: network, product: .regionalTrain, label: "RR\(trainNum)")
                } else if ("TER" == trainType || "Train Express Regional" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "TER\(trainNum)")
                } else if ("ENO" == trainType || "enno" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "ENO\(trainNum)")
                } else if "enno" == longName && symbol == "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "enno");
                } else if ("PLB" == trainType || "Pinzgauer Lokalbahn" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "PLB\(trainNum)")
                } else if ("NX" == trainType || "National Express" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "NX\(trainNum)")
                } else if ("SE" == trainType || "ABELLIO Rail Mitteldeutschland GmbH" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "SE\(trainNum)")
                } else if "DNA" == trainType, trainNum != "" { // Dieselnetz Augsburg
                    return Line(id: id, network: network, product: .regionalTrain, label: "DNA\(trainNum)")
                } else if "Dieselnetz" == trainType && "Augsburg" == trainNum {
                    return Line(id: id, network: network, product: .regionalTrain, label: "DNA")
                    
                } else if ("BSB" == trainType || "Breisgau-S-Bahn Gmbh" == trainName) && trainNum != "" {
                    return Line(id: id, network: network, product: .regionalTrain, label: "BSB\(trainNum)")
                } else if "BSB-Zug" == trainName && trainNum != "" { // Breisgau-S-Bahn
                    return Line(id: id, network: network, product: .suburbanTrain, label: trainNum)
                } else if "BSB-Zug" == trainName && trainNum == "" {
                    return Line(id: id, network: network, product: .suburbanTrain, label: "BSB")
                } else if let longName = longName, longName.hasPrefix("BSB-Zug") {
                    return Line(id: id, network: network, product: Product.suburbanTrain, label: "BSB")
                } else if "RSB" == trainType { // Regionalschnellbahn, Wien
                    return Line(id: id, network: network, product: Product.suburbanTrain, label: "RSB\(trainNum)")
                } else if "RER" == trainName && symbol != "" && symbol.count == 1 { // Réseau Express Régional
                    return Line(id: id, network: network, product: .suburbanTrain, label: symbol)
                } else if "S" == trainType {
                    return Line(id: id, network: network, product: .suburbanTrain, label: "S\(trainNum)")
                } else if "S-Bahn" == trainName {
                    return Line(id: id, network: network, product: .suburbanTrain, label: "S\(trainNum)")
                    
                } else if "RT" == trainType || "RegioTram" == trainName {
                    return Line(id: id, network: network, product: .tram, label: "RT\(trainNum)")
                    
                } else if "Bus" == trainType && trainNum != "" {
                    return Line(id: id, network: network, product: .bus, label: trainNum)
                } else if "Bus" == longName && symbol == "" {
                    return Line(id: id, network: network, product: .bus, label: longName)
                } else if "SEV" == trainType || "SEV" == trainNum || "SEV" == trainName || "SEV" == symbol
                    || "BSV" == trainType || "Ersatzverkehr" == trainName
                    || "Schienenersatzverkehr" == trainName {
                    return Line(id: id, network: network, product: .bus, label: "SEV\(trainNum)");
                } else if "Bus replacement" == trainName { // GB
                    return Line(id: id, network: network, product: .bus, label: "BR");
                } else if "BR" == trainType && trainName != "" && trainName.hasPrefix("Bus") { // GB
                    return Line(id: id, network: network, product: .bus, label: "BR\(trainNum)")
                } else if "EXB" == trainType && trainNum != "" {
                    return Line(id: id, network: network, product: .bus, label: "EXB\(trainNum)")
                    
                } else if "GB" == trainType { // Gondelbahn
                    return Line(id: id, network: network, product: .cablecar, label: "GB\(trainNum)")
                } else if "SB" == trainType { // Seilbahn
                    return Line(id: id, network: network, product: .suburbanTrain, label: "SB\(trainNum)")
                    
                } else if "Zug" == trainName && symbol != "" {
                    return Line(id: id, network: network, product: nil, label: symbol)
                } else if "Zug" == longName && symbol == "" {
                    return Line(id: id, network: network, product: nil, label: "Zug")
                } else if "Zuglinie" == trainName && symbol != "" {
                    return Line(id: id, network: network, product: nil, label: symbol)
                } else if "ZUG" == trainType && trainNum != "" {
                    return Line(id: id, network: network, product: nil, label: trainNum)
                } else if symbol != "" && (symbol =~ "\\d+") && trainType == "" && trainName == "" {
                    return Line(id: id, network: network, product: nil, label: symbol)
                } else if "N" == trainType && trainName == "" && symbol == "" {
                    return Line(id: id, network: network, product: nil, label: "N\(trainNum)")
                } else if "Train" == trainName {
                    return Line(id: id, network: network, product: nil, label: nil)
                } else if "PPN" == trainType && "Osobowy" == trainName, trainNum != "" {
                    return Line(id: id, network: network, product: nil, label: "PPN\(trainNum)")
                }
                
                // generic
                if trainName != "" && trainType == "" && trainNum == "" {
                    return Line(id: id, network: network, product: nil, label: trainName + trainNum)
                }
            } else if mot == "1" {
                if let symbol = symbol, symbol =~ "S ?\\d+" {
                    return Line(id: id, network: network, product: .suburbanTrain, label: symbol)
                } else if let name = name, name =~ "S ?\\d+" {
                    return Line(id: id, network: network, product: .suburbanTrain, label: name)
                } else if trainName == "S-Bahn" {
                    return Line(id: id, network: network, product: .suburbanTrain, label: "S\(trainNum ?? "")")
                    //                } else if let symbol = symbol, name == symbol, symbol =~ "(S\\d+) \\((?:DB Regio AG)\\)" {
                    //                    return Line(id: id, network: network, product: .SUBURBAN_TRAIN, label: "")
                } else if "REX" == trainType {
                    return Line(id: id, network: network, product: .regionalTrain, label: "REX\(trainNum ?? "")")
                }
                var label: String = ""
                if let symbol = symbol {
                    label += symbol
                }
                if let name = name {
                    label += name
                }
                return Line(id: id, network: network, product: .regionalTrain, label: label)
            } else if mot == "2" {
                return Line(id: id, network: network, product: .subway, label: symbolName)
            } else if mot == "3" || mot == "4" {
                return Line(id: id, network: network, product: .tram, label: symbolName)
            } else if mot == "5" || mot == "6" || mot == "7" {
                if name == "Schienenersatzverkehr" {
                    return Line(id: id, network: network, product: .bus, label: "SEV")
                } else if longName?.hasPrefix("Flixbus") ?? false || trainName == "Flixbus" {
                    return Line(id: id, network: network, product: .bus, label: "FLX\(name ?? "")")
                } else {
                    return Line(id: id, network: network, product: .bus, label: name)
                }
            } else if mot == "8" {
                return Line(id: id, network: network, product: .cablecar, label: name)
            } else if mot == "9" {
                return Line(id: id, network: network, product: .ferry, label: name)
            } else if mot == "10" {
                return Line(id: id, network: network, product: .onDemand, label: symbolName)
            } else if mot == "11" {
                return Line(id: id, network: network, product: nil, label: symbolName)
            } else if mot == "12" {
                if trainName == "Schulbus", symbol != nil {
                    return Line(id: id, network: network, product: .bus, label: symbol)
                }
            } else if mot == "13" {
                if (trainName == "SEV" || trainName == "Ersatzverkehr") && trainType == nil {
                    return Line(id: id, network: network, product: .bus, label: "SEV")
                }
                return Line(id: id, network: network, product: .regionalTrain, label: symbolName)
            } else if mot == "14" || mot == "15" || mot == "16" {
                if trainNum != nil || trainType != nil {
                    var label: String = ""
                    if let trainType = trainType {
                        label += trainType
                    }
                    if let trainNum = trainNum {
                        label += trainNum
                    }
                    return Line(id: id, network: network, product: .highSpeedTrain, label: label)
                }
                return Line(id: id, network: network, product: .highSpeedTrain, label: name)
            } else if mot == "17" {
                if trainNum == nil, let trainName = trainName,  trainName.hasPrefix("Schienenersatz") {
                    return Line(id: id, network: network, product: .bus, label: "SEV")
                }
            } else if mot == "18" { // Zug-Shuttle
                return Line(id: id, network: network, product: .regionalTrain, label: name)
            } else if mot == "19" {
                if (trainName == "Bürgerbus" || trainName == "BürgerBus" || trainName == "Kleinbus") && symbol != nil {
                    return Line(id: id, network: network, product: .bus, label: symbol)
                }
            }
        }
        return Line(id: id, network: network, product: nil, label: name)
    }
    
    public class Context: QueryTripsContext {
        
        public override class var supportsSecureCoding: Bool { return true }
        
        public override var canQueryEarlier: Bool { return true }
        public override var canQueryLater: Bool { return true }
        
        public let queryEarlierContext: (sessionId: String, requestId: String)
        public let queryLaterContext: (sessionId: String, requestId: String)
        
        init(queryEarlierContext: (sessionId: String, requestId: String), queryLaterContext: (sessionId: String, requestId: String)) {
            self.queryEarlierContext = queryEarlierContext
            self.queryLaterContext = queryLaterContext
            super.init()
        }
        
        public required convenience init?(coder aDecoder: NSCoder) {
            guard
                let earlierSession = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.queryEarlierContextSession) as String?,
                let earlierRequest = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.queryEarlierContextRequest) as String?,
                let laterSession = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.queryLaterContextSession) as String?,
                let laterRequest = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.queryLaterContextRequest) as String?
                else {
                    return nil
            }
            self.init(queryEarlierContext: (sessionId: earlierSession, requestId: earlierRequest), queryLaterContext: (sessionId: laterSession, requestId: laterRequest))
        }
        
        public override func encode(with aCoder: NSCoder) {
            aCoder.encode(queryEarlierContext.sessionId, forKey: PropertyKey.queryEarlierContextSession)
            aCoder.encode(queryEarlierContext.requestId, forKey: PropertyKey.queryEarlierContextRequest)
            aCoder.encode(queryLaterContext.sessionId, forKey: PropertyKey.queryLaterContextSession)
            aCoder.encode(queryLaterContext.requestId, forKey: PropertyKey.queryLaterContextRequest)
        }
        
        struct PropertyKey {
            static let queryEarlierContextSession = "earlierSession"
            static let queryEarlierContextRequest = "earlierRequest"
            static let queryLaterContextSession = "laterSession"
            static let queryLaterContextRequest = "laterRequest"
        }
        
    }
    
    /// MVV, VRN and others use load balancing. Therefore, stateful API functionality only works
    /// correctly if we coincidentally hit the same server again. The session ID cookie does include
    /// the server ID that the session was created on, but apparently the load balancer does not
    /// respect this.
    ///
    /// See: https://github.com/schildbach/public-transport-enabler/commit/72ef473998cbf8d808fcf013759e9fe655ae3eef
    public class StatelessContext: QueryTripsContext {
        
        public override class var supportsSecureCoding: Bool { return true }
        
        public override var canQueryEarlier: Bool { return true }
        public override var canQueryLater: Bool { return true }
        
        public let from: Location
        public let via: Location?
        public let to: Location
        public let tripOptions: TripOptions
        public let lastDepartureTime: Date
        public let firstArrivalTime: Date
        
        public convenience init?(from: Location, via: Location?, to: Location, tripOptions: TripOptions, trips: [Trip], previousContext: QueryTripsContext?) {
            guard trips.count > 1 else { return nil }
            let firstTrip = trips[0]
            var lastTrip = trips[trips.count - 1]
            // if the last included trip is a walking route, use the previous one
            let lastTripIsIndividual = lastTrip.legs.count == 1 && lastTrip.legs[0] is IndividualLeg
            if lastTripIsIndividual, trips.count > 1 {
                lastTrip = trips[trips.count - 2]
            }
            
            var lastDepartureTime = lastTrip.departureTime.addingTimeInterval(60)
            var firstArrivalTime = firstTrip.arrivalTime.addingTimeInterval(-60)
            if let context = previousContext as? StatelessContext {
                if context.firstArrivalTime < firstArrivalTime {
                    firstArrivalTime = context.firstArrivalTime
                }
                if context.lastDepartureTime > lastDepartureTime {
                    lastDepartureTime = context.lastDepartureTime
                }
            }
            
            self.init(from: from, via: via, to: to, tripOptions: tripOptions, lastDepartureTime: lastDepartureTime, firstArrivalTime: firstArrivalTime)
        }
        
        public init?(from: Location, via: Location?, to: Location, tripOptions: TripOptions, lastDepartureTime: Date, firstArrivalTime: Date) {
            self.from = from
            self.via = via
            self.to = to
            self.tripOptions = tripOptions
            self.lastDepartureTime = lastDepartureTime
            self.firstArrivalTime = firstArrivalTime
            super.init()
        }
        
        public required convenience init?(coder aDecoder: NSCoder) {
            guard
                let from = aDecoder.decodeObject(of: Location.self, forKey: PropertyKey.from),
                let to = aDecoder.decodeObject(of: Location.self, forKey: PropertyKey.to),
                let tripOptions = aDecoder.decodeObject(of: TripOptions.self, forKey: PropertyKey.tripOptions),
                let lastDepartureTime = aDecoder.decodeObject(of: NSDate.self, forKey: PropertyKey.lastDepartureTime) as Date?,
                let firstArrivalTime = aDecoder.decodeObject(of: NSDate.self, forKey: PropertyKey.firstArrivalTime) as Date?
            else {
                return nil
            }
            let via = aDecoder.decodeObject(of: Location.self, forKey: PropertyKey.via)
            self.init(from: from, via: via, to: to, tripOptions: tripOptions, lastDepartureTime: lastDepartureTime, firstArrivalTime: firstArrivalTime)
        }
        
        public override func encode(with aCoder: NSCoder) {
            aCoder.encode(from, forKey: PropertyKey.from)
            aCoder.encode(via, forKey: PropertyKey.via)
            aCoder.encode(to, forKey: PropertyKey.to)
            aCoder.encode(tripOptions, forKey: PropertyKey.tripOptions)
            aCoder.encode(lastDepartureTime, forKey: PropertyKey.lastDepartureTime)
            aCoder.encode(firstArrivalTime, forKey: PropertyKey.firstArrivalTime)
        }
        
        struct PropertyKey {
            static let from = "from"
            static let via = "via"
            static let to = "to"
            static let tripOptions = "tripOptions"
            static let lastDepartureTime = "lastDepartureTime"
            static let firstArrivalTime = "firstArrivalTime"
        }
    }
    
    fileprivate struct ServingLineState {
        let line: Line
        let destination: Location?
        let cancelled: Bool
    }
    
}

public class EfaJourneyContext: QueryJourneyDetailContext {
    
    public override class var supportsSecureCoding: Bool { return true }
    
    let stopId: String
    let stopDepartureTime: Date
    let line: Line
    let tripCode: String
    
    init(stopId: String, stopDepartureTime: Date, line: Line, tripCode: String) {
        self.stopId = stopId
        self.stopDepartureTime = stopDepartureTime
        self.line = line
        self.tripCode = tripCode
        super.init()
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let stopId = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.stopId) as String?, let stopDepartureTime = aDecoder.decodeObject(of: NSDate.self, forKey: PropertyKey.stopDepartureTime) as Date?, let line = aDecoder.decodeObject(of: Line.self, forKey: PropertyKey.line), let tripCode = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.tripCode) as String? else { return nil }
        
        self.init(stopId: stopId, stopDepartureTime: stopDepartureTime, line: line, tripCode: tripCode)
    }
    
    public override func encode(with aCoder: NSCoder) {
        aCoder.encode(stopId, forKey: PropertyKey.stopId)
        aCoder.encode(stopDepartureTime, forKey: PropertyKey.stopDepartureTime)
        aCoder.encode(line, forKey: PropertyKey.line)
        aCoder.encode(tripCode, forKey: PropertyKey.tripCode)
    }
    
    struct PropertyKey {
        
        static let stopId = "stopId"
        static let stopDepartureTime = "stopDepartureTime"
        static let line = "line"
        static let tripCode = "tripCode"
        
    }
    
}

public class EfaRefreshTripContext: RefreshTripContext {
    
    public override class var supportsSecureCoding: Bool { return true }
    
    let sessionId: String
    let requestId: String
    let routeIndex: String
    
    init(sessionId: String, requestId: String, routeIndex: String) {
        self.sessionId = sessionId
        self.requestId = requestId
        self.routeIndex = routeIndex
        super.init()
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let sessionId = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.sessionId) as String?, let requestId = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.requestId) as String?, let routeIndex = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.routeIndex) as String? else { return nil }
        self.init(sessionId: sessionId, requestId: requestId, routeIndex: routeIndex)
    }
    
    public override func encode(with aCoder: NSCoder) {
        aCoder.encode(sessionId, forKey: PropertyKey.sessionId)
        aCoder.encode(requestId, forKey: PropertyKey.requestId)
        aCoder.encode(routeIndex, forKey: PropertyKey.routeIndex)
    }
    
    public override var description: String {
        return "\(sessionId):\(requestId):\(routeIndex)"
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? EfaRefreshTripContext else { return false }
        if self === other { return true }
        return self.sessionId == other.sessionId && self.requestId == other.requestId && self.routeIndex == other.routeIndex
    }
    
    struct PropertyKey {
        
        static let sessionId = "sessionId"
        static let requestId = "requestId"
        static let routeIndex = "routeIndex"
        
    }
    
}
