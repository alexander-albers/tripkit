import Foundation
import os.log
import Gzip
import SWXMLHash
import SwiftyJSON

public class AbstractHafasLegacyProvider: AbstractHafasProvider, QueryJourneyDetailManually {
    
    override public var supportedQueryTraits: Set<QueryTrait> { return [.minChangeTime] }
    
    let languageCodeMap = [
        "de": "dn",
        "nl": "nn",
        "pl": "pn",
        "en": "en",
        "it": "in",
        "fr": "fn",
        "da": "mn",
        "es": "hn"
    ]
    var stationBoardEndpoint: String
    var getStopEndpoint: String
    var queryEndpoint: String
    
    var apiLanguage: String {  languageCodeMap[queryLanguage ?? defaultLanguage]! }
    var stationBoardHasStationTable: Bool = true
    var stationBoardHasLocation: Bool = false
    var jsonGetStopsUseWeight: Bool = true
    var dominantPlanStopTime: Bool = false
    var jsonGetStopsEncoding: String.Encoding = .isoLatin1
    var jsonNearbyLocationsEncoding: String.Encoding = .isoLatin1
    
    init(networkId: NetworkId, apiBase: String, productsMap: [Product?]) {
        self.stationBoardEndpoint = apiBase + "stboard.exe/"
        self.getStopEndpoint = apiBase + "ajax-getstop.exe/"
        self.queryEndpoint = apiBase + "query.exe/"
        super.init(networkId: networkId, productsMap: productsMap)
    }
    
    // MARK: NetworkProvider implementations – Requests
    
    let P_AJAX_GET_STOPS_JSON = try! NSRegularExpression(pattern: "SLs\\.sls\\s*=\\s*(.*?);\\s*SLs\\.showSuggestion\\(\\);", options: .caseInsensitive)
    let P_AJAX_GET_STOPS_ID = try! NSRegularExpression(pattern: ".*?@L=0*(\\d+)@.*?", options: .caseInsensitive)
    
    override public func suggestLocations(constraint: String, types: [LocationType]?, maxLocations: Int, completion: @escaping (HttpRequest, SuggestLocationsResult) -> Void) -> AsyncRequest {
        let urlBuilder = UrlBuilder(path: getStopEndpoint + apiLanguage, encoding: requestUrlEncoding)
        jsonGetStopParameters(builder: urlBuilder, constraint: constraint)
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder)
        return makeRequest(httpRequest) {
            guard let data = httpRequest.responseData, let string = String(data: data, encoding: self.jsonGetStopsEncoding) else {
                throw ParseError(reason: "failed to parse data")
            }
            
            if let match = self.P_AJAX_GET_STOPS_JSON.firstMatch(in: string, options: [], range: NSMakeRange(0, string.count)) {
                let substring = (string as NSString).substring(with: match.range(at: 1))
                
                let encodedData = substring.data(using: .utf8, allowLossyConversion: true)
                httpRequest.responseData = encodedData
                try self.suggestLocationsParsing(request: httpRequest, constraint: constraint, types: types, maxLocations: maxLocations, completion: completion)
            } else {
                throw ParseError(reason: "illegal match")
            }
        } errorHandler: { err in
            completion(httpRequest, .failure(err))
        }
    }
    
    override public func queryNearbyLocations(location: Location, types: [LocationType]?, maxDistance: Int, maxLocations: Int, completion: @escaping (HttpRequest, NearbyLocationsResult) -> Void) -> AsyncRequest {
        if let coord = location.coord {
            return nearbyLocationsBy(lat: coord.lat, lon: coord.lon, types: types, maxDistance: maxDistance, maxLocations: maxLocations, completion: completion)
        } else if let id = location.id, location.type == .station {
            return nearbyStationsBy(id: id, maxDistance: maxDistance, completion: completion)
        } else {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .invalidId)
            return AsyncRequest(task: nil)
        }
    }
    
    func nearbyLocationsBy(lat: Int, lon: Int, types: [LocationType]?, maxDistance: Int, maxLocations: Int, completion: @escaping (HttpRequest, NearbyLocationsResult) -> Void) -> AsyncRequest {
        let types = types ?? [.station]
        if types.contains(.station) {
            let urlBuilder = UrlBuilder(path: queryEndpoint + apiLanguage + "y", encoding: requestUrlEncoding)
            jsonNearbyStationParameters(builder: urlBuilder, lat: lat, lon: lon, maxDistance: maxDistance, maxLocations: maxLocations)
            
            return jsonNearbyLocations(url: urlBuilder, location: Location(lat: lat, lon: lon), types: types, maxDistance: maxDistance, maxLocations: maxLocations, completion: completion)
        } else if types.contains(.poi) {
            let urlBuilder = UrlBuilder(path: queryEndpoint + apiLanguage + "y", encoding: requestUrlEncoding)
            jsonNearbyPOIsParameters(builder: urlBuilder, lat: lat, lon: lon, maxDistance: maxDistance, maxLocations: maxLocations)
            
            return jsonNearbyLocations(url: urlBuilder, location: Location(lat: lat, lon: lon), types: types, maxDistance: maxDistance, maxLocations: maxLocations, completion: completion)
        } else {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .invalidId)
            return AsyncRequest(task: nil)
        }
    }
    
    func jsonNearbyLocations(url: UrlBuilder, location: Location, types: [LocationType]?, maxDistance: Int, maxLocations: Int, completion: @escaping (HttpRequest, NearbyLocationsResult) -> Void) -> AsyncRequest {
        let httpRequest = HttpRequest(urlBuilder: url)
        return makeRequest(httpRequest) {
            guard let data = httpRequest.responseData else { throw ParseError(reason: "failed to parse response") }
            let string = String(data: data, encoding: self.jsonNearbyLocationsEncoding)
            guard
                let data = string?
                    .replacingOccurrences(of: "\\'", with: "'")
                    .data(using: self.jsonNearbyLocationsEncoding)
            else {
                throw ParseError(reason: "failed to parse response")
            }
            httpRequest.responseData = data
            try self.queryNearbyLocationsByCoordinateParsing(request: httpRequest, location: location, types: types, maxDistance: maxDistance, maxLocations: maxLocations, completion: completion)
        } errorHandler: { err in
            completion(httpRequest, .failure(err))
        }
    }
    
    func nearbyStationsBy(id: String, maxDistance: Int, completion: @escaping (HttpRequest, NearbyLocationsResult) -> Void) -> AsyncRequest {
        let urlBuilder = UrlBuilder(path: stationBoardEndpoint + apiLanguage, encoding: requestUrlEncoding)
        xmlNearbyStationsParameters(builder: urlBuilder, id: id)
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder)
        return makeRequest(httpRequest) {
            try self.handleXmlNearbyLocations(httpRequest: httpRequest, completion: completion)
        } errorHandler: { err in
            completion(httpRequest, .failure(err))
        }
    }

    override public func queryDepartures(stationId: String, departures: Bool, time: Date?, maxDepartures: Int, equivs: Bool, completion: @escaping (HttpRequest, QueryDeparturesResult) -> Void) -> AsyncRequest {
        let urlBuilder = UrlBuilder(path: stationBoardEndpoint + apiLanguage, encoding: requestUrlEncoding)
        xmlStationBoardParameters(builder: urlBuilder, stationId: stationId, departures: departures, time: time, maxDepartures: maxDepartures, equivs: equivs, styleSheet: "vs_java3")
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder)
        return makeRequest(httpRequest) {
            try self.queryDeparturesParsing(request: httpRequest, stationId: stationId, departures: departures, time: time, maxDepartures: maxDepartures, equivs: equivs, completion: completion)
        } errorHandler: { err in
            completion(httpRequest, .failure(err))
        }
    }
    
    public override func queryTrips(from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        return queryTripsBinary(from: from, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions, completion: completion)
    }
    
    func queryTripsBinary(from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        
        if !from.isIdentified() {
            return suggestLocations(constraint: [from.place, from.name].compactMap({$0}).joined(separator: " "), types: [.station], maxLocations: 10, completion: { (request, result) in
                switch result {
                case .success(let locations):
                    if locations.count > 1 {
                        completion(request, .ambiguous(ambiguousFrom: locations.map({$0.location}), ambiguousVia: [], ambiguousTo: []))
                    } else if let location = locations.first?.location {
                        let _ = self.queryTripsBinary(from: location, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions, completion: completion)
                    } else {
                        completion(request, .unknownFrom)
                    }
                case .failure(_):
                    completion(request, .unknownFrom)
                }
            })
        } else if let via = via, !via.isIdentified() {
            return suggestLocations(constraint: [via.place, via.name].compactMap({$0}).joined(separator: " "), types: [.station], maxLocations: 10, completion: { (request, result) in
                switch result {
                case .success(let locations):
                    if locations.count > 1 {
                        completion(request, .ambiguous(ambiguousFrom: [], ambiguousVia: locations.map({$0.location}), ambiguousTo: []))
                    } else if let location = locations.first?.location {
                        let _ = self.queryTripsBinary(from: from, via: location, to: to, date: date, departure: departure, tripOptions: tripOptions, completion: completion)
                    } else {
                        completion(request, .unknownVia)
                    }
                case .failure(_):
                    completion(request, .unknownVia)
                }
            })
        } else if !to.isIdentified() {
            return suggestLocations(constraint: [to.place, to.name].compactMap({$0}).joined(separator: " "), types: [.station], maxLocations: 10, completion: { (request, result) in
                switch result {
                case .success(let locations):
                    if locations.count > 1 {
                        completion(request, .ambiguous(ambiguousFrom: [], ambiguousVia: [], ambiguousTo: locations.map({$0.location})))
                    } else if let location = locations.first?.location {
                        let _ = self.queryTripsBinary(from: from, via: via, to: location, date: date, departure: departure, tripOptions: tripOptions, completion: completion)
                    } else {
                        completion(request, .unknownTo)
                    }
                case .failure(_):
                    completion(request, .unknownTo)
                }
            })
        } else {
            return self.doQueryBinary(from: from, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions, completion: completion)
        }
    }
    
    func doQueryBinary(from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        let urlBuilder = UrlBuilder(path: queryEndpoint + apiLanguage, encoding: requestUrlEncoding)
        queryTripsBinaryParameters(builder: urlBuilder, from: from, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions)
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder)
        return makeRequest(httpRequest) {
            guard let data = httpRequest.responseData else { throw ParseError(reason: "failed to parse data") }
            let uncompressedData: Data
            if data.isGzipped {
                uncompressedData = try data.gunzipped()
            } else {
                uncompressedData = data
            }
            httpRequest.responseData = uncompressedData
            try self.queryTripsParsing(request: httpRequest, from: from, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions, previousContext: nil, later: false, completion: completion)
        } errorHandler: { err in
            if err is SessionExpiredError {
                completion(httpRequest, .sessionExpired)
            } else {
                completion(httpRequest, .failure(err))
            }
        }
    }
    
    override public func queryMoreTrips(context: QueryTripsContext, later: Bool, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        guard let context = context as? QueryTripsBinaryContext else {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .sessionExpired)
            return AsyncRequest(task: nil)
        }
        let urlBuilder = UrlBuilder(path: queryEndpoint + apiLanguage, encoding: requestUrlEncoding)
        queryMoreTripsBinaryParameters(builder: urlBuilder, context: context, later: later)
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder)
        return makeRequest(httpRequest) {
            guard let data = httpRequest.responseData else { throw ParseError(reason: "failed to parse data") }
            let uncompressedData: Data
            if data.isGzipped {
                uncompressedData = try data.gunzipped()
            } else {
                uncompressedData = data
            }
            httpRequest.responseData = uncompressedData
            try self._queryTripsParsing(request: httpRequest, from: nil, via: nil, to: nil, previousContext: context, later: later, completion: completion)
        } errorHandler: { err in
            if err is SessionExpiredError {
                completion(httpRequest, .sessionExpired)
            } else {
                completion(httpRequest, .failure(err))
            }
        }
    }
    
    public override func refreshTrip(context: RefreshTripContext, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        guard let context = context as? HafasLegacyRefreshTripContext else {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .sessionExpired)
            return AsyncRequest(task: nil)
        }
        let urlBuilder = UrlBuilder(path: queryEndpoint + apiLanguage, encoding: requestUrlEncoding)
        refreshTripBinaryParameters(builder: urlBuilder, context: context)
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder)
        return makeRequest(httpRequest) {
            guard let data = httpRequest.responseData else { throw ParseError(reason: "failed to parse data") }
            let uncompressedData: Data
            if data.isGzipped {
                uncompressedData = try data.gunzipped()
            } else {
                uncompressedData = data
            }
            httpRequest.responseData = uncompressedData
            try self.refreshTripParsing(request: httpRequest, context: context, completion: completion)
        } errorHandler: { err in
            completion(httpRequest, .failure(err))
        }
    }
    
    public override func queryJourneyDetail(context: QueryJourneyDetailContext, completion: @escaping (HttpRequest, QueryJourneyDetailResult) -> Void) -> AsyncRequest {
        return queryJourneyDetailManually(context: context, completion: completion)
    }
    
    // MARK: NetworkProvider responses
    
    override func suggestLocationsParsing(request: HttpRequest, constraint: String, types: [LocationType]?, maxLocations: Int, completion: @escaping (HttpRequest, SuggestLocationsResult) -> Void) throws {
        guard let data = request.responseData else {
            throw ParseError(reason: "no response")
        }
        let json = try JSON(data: data, options: .allowFragments)
        if let error = json["error"].string, error != "0" {
            throw ParseError(reason: "received hafas error code \(error)")
        }
        
        var locations: [SuggestedLocation] = []
        for (index, suggestion) in json["suggestions"].arrayValue.enumerated() {
            guard let type = Int(suggestion["type"].stringValue) else {
                continue
            }
            let id = suggestion["id"].string
            let value = suggestion["value"].string
            
            let coord: LocationPoint?
            if let lat = Int(suggestion["ycoord"].stringValue), let lon = Int(suggestion["xcoord"].stringValue) {
                coord = LocationPoint(lat: lat, lon: lon)
            } else {
                coord = nil
            }
            
            let weight = jsonGetStopsUseWeight ? Int(suggestion["weight"].stringValue) ?? -index : -index
            let localId: String?
            if let id = id, let match = self.P_AJAX_GET_STOPS_ID.firstMatch(in: id, options: [], range: NSMakeRange(0, id.count)) {
                localId = (id as NSString).substring(with: match.range(at: 1))
            } else {
                localId = nil
            }
            
            let location: Location?
            if type == 1 {
                let placeAndName = split(stationName: value)
                location = Location(type: .station, id: localId, coord: coord, place: placeAndName.0, name: placeAndName.1)
            } else if type == 2 {
                let placeAndName = split(address: value)
                location = Location(type: .address, id: localId, coord: coord, place: placeAndName.0, name: placeAndName.1)
            } else if type == 4 {
                let placeAndName = split(poi: value)
                location = Location(type: .poi, id: localId, coord: coord, place: placeAndName.0, name: placeAndName.1)
            } else if type == 128 {
                let placeAndName = split(address: value)
                location = Location(type: .address, id: localId, coord: coord, place: placeAndName.0, name: placeAndName.1)
            } else {
                location = nil
            }
            if let location = location {
                locations.append(SuggestedLocation(location: location, priority: weight))
            }
        }
        completion(request, .success(locations: locations))
    }
    
    override func queryNearbyLocationsByCoordinateParsing(request: HttpRequest, location: Location, types: [LocationType]?, maxDistance: Int, maxLocations: Int, completion: @escaping (HttpRequest, NearbyLocationsResult) -> Void) throws {
        guard let data = request.responseData?.encodedData(encoding: self.jsonNearbyLocationsEncoding) else {
            throw ParseError(reason: "no response")
        }
        let json = try JSON(data: data)
        if let error = json["error"].string, error != "0" {
            throw ParseError(reason: "received hafas error code \(error)")
        }
        var locations: [Location] = []
        for stop in json["stops"].arrayValue {
            let id = stop["extId"].string
            let urlname = stop["urlname"].string
            
            let coord: LocationPoint?
            if let lat = Int(stop["y"].stringValue), let lon = Int(stop["x"].stringValue) {
                coord = LocationPoint(lat: lat, lon: lon)
            } else {
                coord = nil
            }
            
            let name = urlname?.decodeUrl(using: jsonNearbyLocationsEncoding) ?? urlname
            let prodclass = Int(stop["prodclass"].stringValue) ?? -1
            let stopWeight = Int(stop["stopweight"].stringValue) ?? -1
            
            guard stopWeight != 0 else { continue }
            let placeAndName = split(stationName: name)
            let products = prodclass != -1 ? self.products(from: prodclass) : nil
            
            guard let location = Location(type: .station, id: id, coord: coord, place: placeAndName.0, name: placeAndName.1, products: products) else { continue }
            locations.append(location)
        }
        for poi in json["pois"].arrayValue {
            let id = poi["extId"].string
            let urlname = poi["urlname"].string
            
            let coord: LocationPoint?
            if let lat = Int(poi["y"].stringValue), let lon = Int(poi["x"].stringValue) {
                coord = LocationPoint(lat: lat, lon: lon)
            } else {
                coord = nil
            }
            
            let placeAndName = split(stationName: urlname)
            guard let location = Location(type: .poi, id: id, coord: coord, place: placeAndName.0, name: placeAndName.1) else { continue }
            locations.append(location)
        }
        
        completion(request, .success(locations: locations))
    }
    
    func handleXmlNearbyLocations(httpRequest: HttpRequest, completion: @escaping (HttpRequest, NearbyLocationsResult) -> Void) throws {
        guard let data = httpRequest.responseData else {
            throw ParseError(reason: "failed to get data")
        }
        var body = String(data: data, encoding: .isoLatin1)!
        if !body.contains("<Journey>") {
            body = "<Journey>\(body)</Journey>"
        }
        body = body.replacingOccurrences(of: "<b>", with: " ")
        body = body.replacingOccurrences(of: "</b>", with: " ")
        body = body.replacingOccurrences(of: "<u>", with: " ")
        body = body.replacingOccurrences(of: "</u>", with: " ")
        body = body.replacingOccurrences(of: "<i>", with: " ")
        body = body.replacingOccurrences(of: "</i>", with: " ")
        body = body.replacingOccurrences(of: "<br />", with: " ")
        body = body.replacingOccurrences(of: " ->", with: " &#x2192;")
        body = body.replacingOccurrences(of: " <-", with: " &#x2190;")
        body = body.replacingOccurrences(of: " <> ", with: " &#x2194; ")
        
        let newData = body.data(using: .utf8) // swift xml parser apparently requires utf8
        let xml = XMLHash.parse(newData!)
        if let errorCode = xml["Err"].element?.attribute(by: "code")?.text, let errorText = xml["Err"].element?.attribute(by: "text")?.text {
            if errorCode == "H730" {
                completion(httpRequest, .invalidId)
                return
            } else if errorCode == "H890" {
                completion(httpRequest, .success(locations: []))
                return
            } else {
                throw ParseError(reason: "unknown hafas error \(errorCode) \(errorText)")
            }
        }
        var locations: [Location] = []
        for station in xml["Journey"]["St"].all {
            guard let id = station.element?.attribute(by: "evaId")?.text, let name = station.element?.attribute(by: "name")?.text, let lat = Int(station.element?.attribute(by: "y")?.text ?? ""), let lon = Int(station.element?.attribute(by: "x")?.text ?? "") else {
                throw ParseError(reason: "failed to parse station")
            }
            let placeAndName = split(stationName: name)
            let location = Location(type: .station, id: id, coord: LocationPoint(lat: lat, lon: lon), place: placeAndName.0, name: placeAndName.1)
            if let location = location {
                locations.append(location)
            }
        }
        completion(httpRequest, .success(locations: locations))
    }
    
    let P_XML_STATION_BOARD_DELAY = try! NSRegularExpression(pattern: "(?:-|k\\.A\\.?|cancel|([+-]?\\s*\\d+))", options: .caseInsensitive)
    
    override func queryDeparturesParsing(request: HttpRequest, stationId: String, departures: Bool, time: Date?, maxDepartures: Int, equivs: Bool, completion: @escaping (HttpRequest, QueryDeparturesResult) -> Void) throws {
        let normalizedStationId = normalize(stationId: stationId)
        
        guard let data = request.responseData else {
            throw ParseError(reason: "no response")
        }
        var body = String(data: data, encoding: .isoLatin1)! // TODO: encoding
        if body.hasPrefix("<?xml "), let index = body.firstIndex(of: "\n") {
            body = String(body[body.index(after: index)...])
        }
        if !body.contains("<StationTable>") {
            body = "<StationTable>\(body)</StationTable>"
        }
        body = body.replacingOccurrences(of: "<b>", with: " ")
        body = body.replacingOccurrences(of: "</b>", with: " ")
        body = body.replacingOccurrences(of: "<u>", with: " ")
        body = body.replacingOccurrences(of: "</u>", with: " ")
        body = body.replacingOccurrences(of: "<i>", with: " ")
        body = body.replacingOccurrences(of: "</i>", with: " ")
        body = body.replacingOccurrences(of: "<br />", with: " ")
        body = body.replacingOccurrences(of: " ->", with: " &#x2192;")
        body = body.replacingOccurrences(of: " <-", with: " &#x2190;")
        body = body.replacingOccurrences(of: " <> ", with: " &#x2194; ")
        
        let newData = body.data(using: .utf8)
        let xml = XMLHash.parse(newData!)
        if let errorCode = xml["StationTable"]["Err"].element?.attribute(by: "code")?.text, let errorText = xml["StationTable"]["Err"].element?.attribute(by: "text")?.text {
            if errorCode == "H730" {
                completion(request, .invalidStation)
                return
            } else if errorCode == "H890" {
                completion(request, .success(departures: []))
                return
            } else {
                throw ParseError(reason: "unknown hafas error \(errorCode) \(errorText)")
            }
        }
        
        var placeAndName: (String?, String?) = (nil, nil)
        if stationBoardHasLocation {
            if let st = xml["StationTable"]["St"].element, let efaId = st.attribute(by: "evaId")?.text {
                if efaId != stationId {
                    throw ParseError(reason: "illegal efa id")
                }
                if let name = st.attribute(by: "name")?.text {
                    placeAndName = split(stationName: name.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            }
        }
        
        var stationDepartures: [StationDepartures] = []
        let journeys = xml["StationTable"]["Journey"].all
        for journey in journeys {
            guard let element = journey.element, let fpTime = element.attribute(by: "fpTime")?.text, let fpDate = element.attribute(by: "fpDate")?.text, let delay = element.attribute(by: "delay")?.text, let prod = element.attribute(by: "prod")?.text else {
                os_log("%{public}@: could not parse journey", log: .requestLogger, type: .error, #function)
                continue
            }
            let eDelay = element.attribute(by: "e_delay")?.text
            let platform = element.attribute(by: "platform")?.text
            let targetLoc = element.attribute(by: "targetLoc")?.text
            let dirnr = element.attribute(by: "dirnr")?.text
            let classStr = element.attribute(by: "class")?.text
            let dir = element.attribute(by: "dir")?.text
            let capacityStr = element.attribute(by: "capacity")?.text
            let depStation = element.attribute(by: "depStation")?.text
            let delayReason = element.attribute(by: "delayReason")?.text
            let administration = normalize(lineAdministration: element.attribute(by: "administration")?.text)
            
            let cancelled = delay == "cancel" || eDelay == "cancel"
            
            let plannedTime = try parseTimeAndDate(timeString: fpTime, dateString: fpDate)
            let predictedTime: Date?
            if let eDelay = eDelay, let delay = Int(eDelay) {
                predictedTime = plannedTime.addingTimeInterval(Double(delay) * 60.0)
            } else {
                if let matcher = P_ISO_DATE.firstMatch(in: delay, options: [], range: NSMakeRange(0, delay.count)), let delay = Int((delay as NSString).substring(with: matcher.range(at: 1))) {
                    predictedTime = plannedTime.addingTimeInterval(Double(delay) * 60.0)
                } else {
                    predictedTime = nil
                }
            }
            
            let position = parsePosition(position: platform)
            
            let destinationName: String?
            if let dir = dir {
                destinationName = dir.trimmingCharacters(in: .whitespacesAndNewlines)
            } else if let targetLoc = targetLoc {
                destinationName = targetLoc.trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                destinationName = nil
            }
            
            let destination: Location?
            if let dirnr = dirnr {
                let destPlaceAndName = split(stationName: destinationName)
                destination = Location(type: .station, id: dirnr, coord: nil, place: destPlaceAndName.0, name: destPlaceAndName.1)
            } else {
                destination = Location(anyName: destinationName)
            }
            let prodLine = try parse(lineAndType: prod)
            let line: Line
            if let classStr = classStr, let classInt = Int(classStr) {
                guard let product = try intToProduct(productInt: classInt) else { throw ParseError(reason: "illegal product") }
                line = newLine(network: administration, product: product, normalizedName: prodLine.label, comment: nil, attrs: prodLine.attr ?? [])
            } else {
                line = newLine(network: administration, product: prodLine.product, normalizedName: prodLine.label, comment: nil, attrs: prodLine.attr ?? [])
            }
            
            let capacity: [Int]?
            if let capacityStr = capacityStr, capacityStr != "0|0" {
                let parts = capacityStr.components(separatedBy: "|")
                capacity = [Int(parts[0])!, Int(parts[1])!]
            } else {
                capacity = nil
            }
            
            let message: String?
            if let delayReason = delayReason {
                let msg = delayReason.trimmingCharacters(in: .whitespacesAndNewlines)
                message = !msg.isEmpty ? msg : nil
            } else {
                message = nil
            }
            
            let location: Location?
            if depStation == nil {
                location = Location(type: .station, id: normalizedStationId, coord: nil, place: placeAndName.0, name: placeAndName.0)
            } else {
                let placeAndName = split(stationName: depStation)
                location = Location(type: .station, id: normalizedStationId, coord: nil, place: placeAndName.0, name: placeAndName.1)
            }
            guard let stopLocation = location else { continue }
            
            let journeyContext: HafasLegacyJourneyContext?
            if let destination = destination {
                journeyContext = HafasLegacyJourneyContext(from: stopLocation, to: destination, time: predictedTime ?? plannedTime , plannedTime: plannedTime, product: line.product, line: line)
            } else {
                journeyContext = nil
            }
            
            let departure = Departure(plannedTime: plannedTime, predictedTime: predictedTime, line: line, position: position, plannedPosition: position, cancelled: cancelled, destination: destination, capacity: capacity, message: message, journeyContext: journeyContext)
            
            let first = stationDepartures.first(where: {$0.stopLocation.isEqual(stopLocation)})
            let departures: StationDepartures
            if let first = first {
                departures = first
            } else {
                departures = StationDepartures(stopLocation: stopLocation, departures: [], lines: [])
                stationDepartures.append(departures)
            }
            departures.departures.append(departure)
        }
        completion(request, .success(departures: stationDepartures))
    }
    
    override func queryTripsParsing(request: HttpRequest, from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions, previousContext: QueryTripsContext?, later: Bool, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) throws {
        try _queryTripsParsing(request: request, from: from, via: via, to: to, previousContext: nil, later: false, completion: completion)
    }
    
    override func refreshTripParsing(request: HttpRequest, context: RefreshTripContext, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) throws {
        try _queryTripsParsing(request: request, from: nil, via: nil, to: nil, previousContext: nil, later: false, completion: completion)
    }
    
    /// Binary protocol documentation located here:
    /// https://docs.google.com/spreadsheets/d/1Qzm4fbjp3uH7xQPmXIlzYFMQxI7R3cdcWwHe7svYsR0
    func _queryTripsParsing(request: HttpRequest, from: Location?, via: Location?, to: Location?, previousContext: QueryTripsContext?, later: Bool, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) throws {
        guard let data = request.responseData else { throw ParseError(reason: "no response") }
        let reader = Reader(data: data)
        let version = reader.readShortReverse()
        if version != 6 && version != 5 {
            throw ParseError(reason: "unknown version \(version)")
        }
        reader.reset()
        reader.skipBytes(0x20)
        let serviceDaysTablePtr = reader.readIntReverse()
        let stringTablePtr = reader.readIntReverse()
        reader.reset()
        reader.skipBytes(0x36)
        let stationTablePtr = reader.readIntReverse()
        let commentTablePtr = reader.readIntReverse()
        reader.reset()
        reader.skipBytes(0x46)
        let extensionHeaderPtr = reader.readIntReverse()
        let strings = StringTable(reader: reader, stringTablePtr: stringTablePtr, length: serviceDaysTablePtr - stringTablePtr)
        reader.reset()
        reader.skipBytes(extensionHeaderPtr)
        let extensionHeaderLength = reader.readIntReverse()
        reader.skipBytes(12)
        let errorCode = reader.readShortReverse()
        if errorCode != 0 {
            os_log("Hafas error while querying trips: %d", log: .requestLogger, type: .error, errorCode)
            switch errorCode {
            case 1:
                completion(request, .sessionExpired)
            case 2:
                os_log("Your search results could not be stored internally.", log: .requestLogger, type: .error)
                completion(request, .sessionExpired)
            case 8:
                completion(request, .ambiguous(ambiguousFrom: [], ambiguousVia: [], ambiguousTo: []))
            case 13:
                throw ParseError(reason: "IN13: Our booking system is currently being used by too many users at the same time.")
            case 19:
                throw ParseError(reason: "IN19")
            case 207:
                throw ParseError(reason: "H207: Unfortunately your connection request can currently not be processed.")
            case 887:
                os_log("H887: Your inquiry was too complex. Please try entering less intermediate stations.", log: .requestLogger, type: .error)
                completion(request, .noTrips)
            case 890:
                os_log("H890: No connections have been found that correspond to your request. It is possible that the requested service does not operate from or to the places you stated on the requested date of travel.", log: .requestLogger, type: .error)
                completion(request, .noTrips)
            case 891:
                os_log("H891: Unfortunately there was no route found. Missing timetable data could be the reason.", log: .requestLogger, type: .error)
                completion(request, .noTrips)
            case 892:
                os_log("H892: Your inquiry was too complex. Please try entering less intermediate stations.", log: .requestLogger, type: .error)
                completion(request, .noTrips)
            case 899:
                os_log("H899: there was an unsuccessful or incomplete search due to a timetable change.", log: .requestLogger, type: .error)
                completion(request, .noTrips)
            case 900:
                os_log("Unsuccessful or incomplete search (timetable change)", log: .requestLogger, type: .error)
                completion(request, .noTrips)
            case 9220:
                os_log("H9220: Nearby to the given address stations could not be found.", log: .requestLogger, type: .error)
                completion(request, .noTrips)
            case 9240:
                os_log("H9240: Unfortunately there was no route found. Perhaps your start or destination is not served at all or with the selected means of transport on the required date/time.", log: .requestLogger, type: .error)
                completion(request, .noTrips)
            case 9260:
                os_log("H9260: Unknown departure station", log: .requestLogger, type: .error)
                completion(request, .unknownFrom)
            case 9280:
                os_log("H9280: Unknown intermediate station", log: .requestLogger, type: .error)
                completion(request, .unknownVia)
            case 9300:
                os_log("H9300: Unknown arrival station", log: .requestLogger, type: .error)
                completion(request, .unknownTo)
            case 9320:
                os_log("The input is incorrect or incomplete", log: .requestLogger, type: .error)
                completion(request, .invalidDate)
            case 9360:
                os_log("H9360: Unfortunately your connection request can currently not be processed.", log: .requestLogger, type: .error)
                completion(request, .invalidDate)
            case 9380:
                os_log("H9380: Dep./Arr./Intermed. or equivalent station defined more than once", log: .requestLogger, type: .error)
                completion(request, .tooClose)
            case 895:
                os_log("H895: Departure/Arrival are too near", log: .requestLogger, type: .error)
                completion(request, .tooClose)
            case 65535:
                throw ParseError(reason: "H65535: unknown error")
            default:
                throw ParseError(reason: "unknown hafas error code \(errorCode)")
            }
            return
        }
        
        reader.skipBytes(14)
        let charset = strings.read(reader: reader)?.lowercased()
        if charset == "iso-8859-1" {
            strings.encoding = .isoLatin1
        } else if charset == "utf-8" || charset == "utf8" {
            strings.encoding = .utf8
        } else {
            throw ParseError(reason: "unknown encoding \(charset ?? "")")
        }
        reader.reset()
        reader.skipBytes(30)
        let numTrips = reader.readShortReverse()
        if numTrips == 0 {
            completion(request, .noTrips)
            return
        }
        reader.reset()
        reader.skipBytes(0x02)
        
        guard let resDeparture = location(reader: reader, strings: strings), let resArrival = location(reader: reader, strings: strings) else { throw ParseError(reason: "could not parse dep/arr location") }
        
        reader.skipBytes(10)
        let resDate = parseDate(reader: reader)
        
        reader.reset()
        reader.skipBytes(extensionHeaderPtr + 0x8)
        
        let seqNr = reader.readShortReverse()
        if seqNr == 0 {
            throw SessionExpiredError()
        } else if seqNr < 0  {
            throw ParseError(reason: "invalid sequence number \(seqNr)")
        }
        let requestId = strings.read(reader: reader)
        let tripDetailsPtr = reader.readIntReverse()
        if tripDetailsPtr == 0 {
            throw ParseError(reason: "no connection details")
        }
        reader.skipBytes(4)
        let disruptionsPtr = reader.readIntReverse()
        reader.skipBytes(10)
        
        let ld = strings.read(reader: reader)
        let attrsOffset = reader.readIntReverse()
        let tripAttrsPtr: Int
        if extensionHeaderLength >= 0x30 {
            if extensionHeaderLength < 0x32 {
                throw ParseError(reason: "extension header length too short \(extensionHeaderLength)")
            }
            reader.reset()
            reader.skipBytes(extensionHeaderPtr + 0x2c)
            tripAttrsPtr = reader.readIntReverse()
        } else {
            tripAttrsPtr = 0
        }
        
        reader.reset()
        reader.skipBytes(tripDetailsPtr)
        let tripDetailsVersion = reader.readShortReverse()
        if tripDetailsVersion != 1 {
            throw ParseError(reason: "unknown trip details version \(tripDetailsVersion)")
        }
        reader.skipBytes(0x02)
        
        let tripDetailsIndexOffset = reader.readShortReverse()
        let tripDetailsLegOffset = reader.readShortReverse()
        let tripDetailsLegSize = reader.readShortReverse()
        let stopsSize = reader.readShortReverse()
        let stopsOffset = reader.readShortReverse()
        
        let stations = StationTable(provider: self, reader: reader, stationTablePtr: stationTablePtr, length: commentTablePtr - stationTablePtr, strings: strings)
        let comments = CommentTable(reader: reader, commentTablePtr: commentTablePtr, length: tripDetailsPtr - commentTablePtr, strings: strings)
        
        var trips: [Trip] = []
        
        for tripIndex in 0..<numTrips {
            reader.reset()
            reader.skipBytes(0x4a + tripIndex * 12)
            
            let serviceDaysTableOffset = reader.readShortReverse()
            let legsOffset = reader.readIntReverse()
            let numLegs = reader.readShortReverse()
            let _ = reader.readShortReverse() // num changes
            let duration = try parseTime(reader: reader, baseDate: 0, dayOffset: 0)
            
            reader.reset()
            reader.skipBytes(serviceDaysTablePtr + serviceDaysTableOffset)
            
            let _ = strings.read(reader: reader) // service days text
            
            let serviceBitBase = reader.readShortReverse()
            let serviceBitLength = reader.readShortReverse()
            var tripDayOffset = serviceBitBase * 8
            for _ in 0..<serviceBitLength {
                var serviceBits = reader.read()
                if serviceBits == 0 {
                    tripDayOffset += 8
                    continue
                }
                while (serviceBits & 0x80) == 0 {
                    serviceBits = serviceBits << 1
                    tripDayOffset+=1
                }
                break
            }
            
            reader.reset()
            reader.skipBytes(tripDetailsPtr + tripDetailsIndexOffset + tripIndex * 2)
            let tripDetailsOffset = reader.readShortReverse()
            reader.reset()
            reader.skipBytes(tripDetailsPtr + tripDetailsOffset)
            let realtimeStatus = reader.readShortReverse()
            reader.skipBytes(2) // delay
            reader.skipBytes(2) // legIndex
            reader.skipBytes(2) // 0xffff
            reader.skipBytes(2) // legStatus
            reader.skipBytes(2) // 0x0000
            
            if tripAttrsPtr != 0 {
                var legs: [Leg] = []
                for legIndex in 0..<numLegs {
                    reader.reset()
                    reader.skipBytes(0x4a + legsOffset + legIndex * 20)
                    
                    let plannedDepartureTime = try parseTime(reader: reader, baseDate: resDate, dayOffset: tripDayOffset)
                    guard let departureLocation = try stations.read(reader: reader) else { throw ParseError(reason: "failed to parse departure location") }
                    
                    let plannedArrivalTime = try parseTime(reader: reader, baseDate: resDate, dayOffset: tripDayOffset)
                    guard let arrivalLocation = try stations.read(reader: reader) else { throw ParseError(reason: "failed to parse arrival location") }
                    
                    let type = reader.readShortReverse()
                    let lineName = strings.read(reader: reader)
                    
                    let plannedDeparturePosition = normalize(position: strings.read(reader: reader))
                    let plannedArrivalPosition = normalize(position: strings.read(reader: reader))
                    
                    let legAttrIndex = reader.readShortReverse()
                    
                    var lineAttrs: [Line.Attr] = []
                    var lineComment: String? = nil
                    var lineOnDemand = false
                    for comment in try comments.read(reader: reader) {
                        if comment.hasPrefix("bf ") {
                            lineAttrs.append(.wheelChairAccess)
                        } else if comment.hasPrefix("FA ") || comment.hasPrefix("FB ") || comment.hasPrefix("Fr ") {
                            lineAttrs.append(.bicycleCarriage)
                        } else if comment.hasPrefix("$R ") || comment.hasPrefix("ga ") || comment.hasPrefix("ja") || comment.hasPrefix("Vs ") || comment.hasPrefix("mu ") || comment.hasPrefix("mx ") {
                            lineOnDemand = true
                            lineComment = String(comment[comment.index(comment.startIndex, offsetBy: 5)...])
                        }
                    }
                    
                    reader.reset()
                    reader.skipBytes(attrsOffset + legAttrIndex * 4)
                    var directionStr: String? = nil
                    var lineClass = 0
                    var lineCategory: String? = nil
                    var routingType: String? = nil
                    var lineNetwork: String? = nil
                    while true {
                        guard let key = strings.read(reader: reader) else { break }
                        if key == "Direction" {
                            directionStr = strings.read(reader: reader)
                        } else if key == "Class" {
                            lineClass = Int(strings.read(reader: reader) ?? "0") ?? 0
                        } else if key == "Category" {
                            lineCategory = strings.read(reader: reader)
                        } else if key == "GisRoutingType" {
                            routingType = strings.read(reader: reader)
                        } else if key == "AdminCode" {
                            lineNetwork = normalize(lineAdministration: strings.read(reader: reader))
                        } else {
                            reader.skipBytes(2)
                        }
                    }
                    if let lineName = lineName, lineCategory == nil {
                        lineCategory = category(from: lineName)
                    }
                    reader.reset()
                    reader.skipBytes(tripDetailsPtr + tripDetailsOffset + tripDetailsLegOffset + legIndex * tripDetailsLegSize)
                    if tripDetailsLegSize != 16 {
                        throw ParseError(reason: "unhandled trip details leg size \(tripDetailsLegSize)")
                    }
                    
                    let predictedDepartureTime = try parseTime(reader: reader, baseDate: resDate, dayOffset: tripDayOffset)
                    let predictedArrivalTime = try parseTime(reader: reader, baseDate: resDate, dayOffset: tripDayOffset)
                    let predictedDeparturePosition = normalize(position: strings.read(reader: reader))
                    let predictedArrivalPosition = normalize(position: strings.read(reader: reader))
                    
                    let bits = reader.readShortReverse()
                    let arrivalCancelled = (bits & 0x10) != 0
                    let departureCancelled = (bits & 0x20) != 0
                    
                    reader.skipBytes(2)
                    
                    let firstStopIndex = reader.readShortReverse()
                    let numStops = reader.readShortReverse()
                    
                    reader.reset()
                    reader.skipBytes(disruptionsPtr)
                    
                    var disruptionText: String? = nil
                    if reader.readShortReverse() == 1 {
                        reader.reset()
                        reader.skipBytes(disruptionsPtr + 2 + tripIndex * 2)
                        var disruptionsOffset = reader.readShortReverse()
                        while disruptionsOffset != 0 {
                            reader.reset()
                            reader.skipBytes(disruptionsPtr + disruptionsOffset)
                            
                            let _ = strings.read(reader: reader) // 0
                            
                            let disruptionLeg = reader.readShortReverse()
                            reader.skipBytes(2) // bitmask
                            let _ = strings.read(reader: reader) // start of line
                            let _ = strings.read(reader: reader) // end of line
                            let _ = strings.read(reader: reader)
                            let _ = strings.read(reader: reader) // disruption title
                            
                            let disruptionShortText = strings.read(reader: reader)?.stripHTMLTags()
                            disruptionsOffset = reader.readShortReverse()
                            
                            if legIndex == disruptionLeg {
                                let disruptionAttrsIndex = reader.readShortReverse()
                                
                                reader.reset()
                                reader.skipBytes(attrsOffset + disruptionAttrsIndex * 4)
                                
                                while true {
                                    guard let key = strings.read(reader: reader) else { break }
                                    if key == "Text" {
                                        disruptionText = strings.read(reader: reader)
                                    } else {
                                        reader.skipBytes(2)
                                    }
                                }
                                if disruptionShortText != nil {
                                    disruptionText = disruptionShortText
                                }
                            }
                        }
                    }
                    
                    var intermediateStops: [Stop] = []
                    
                    if numStops > 0 {
                        reader.reset()
                        reader.skipBytes(tripDetailsPtr + stopsOffset + firstStopIndex * stopsSize)
                        
                        if stopsSize != 26 {
                            throw ParseError(reason: "unhandled stops size \(stopsSize)")
                        }
                        
                        for _ in 0..<numStops {
                            let plannedStopDepartureTime = try parseTime(reader: reader, baseDate: resDate, dayOffset: tripDayOffset)
                            let plannedStopDepartureDate = plannedStopDepartureTime != 0 ? Date(timeIntervalSince1970: plannedStopDepartureTime) : nil
                            let plannedStopArrivalTime = try parseTime(reader: reader, baseDate: resDate, dayOffset: tripDayOffset)
                            let plannedStopArrivalDate = plannedStopArrivalTime != 0 ? Date(timeIntervalSince1970: plannedStopArrivalTime) : nil
                            let plannedStopDeparturePosition = normalize(position: strings.read(reader: reader))
                            let plannedStopArrivalPosition = normalize(position: strings.read(reader: reader))
                            
                            reader.skipBytes(4)
                            
                            let predictedStopDepartureTime = try parseTime(reader: reader, baseDate: resDate, dayOffset: tripDayOffset)
                            let predictedStopDepartureDate = predictedStopDepartureTime != 0 ? Date(timeIntervalSince1970: predictedStopDepartureTime) : nil
                            let predictedStopArrivalTime = try parseTime(reader: reader, baseDate: resDate, dayOffset: tripDayOffset)
                            let predictedStopArrivalDate = predictedStopArrivalTime != 0 ? Date(timeIntervalSince1970: predictedStopArrivalTime) : nil
                            let predictedStopDeparturePosition = normalize(position: strings.read(reader: reader))
                            let predictedStopArrivalPosition = normalize(position: strings.read(reader: reader))
                            
                            let stopBits = reader.readShortReverse()
                            let stopArrivalCancelled = (stopBits & 0x10) != 0
                            let stopDepartureCancelled = (stopBits & 0x20) != 0
                            
                            reader.skipBytes(2)
                            
                            guard let stopLocation = try stations.read(reader: reader) else { throw ParseError(reason: "failed to parse stop location") }
                            
                            let validPredictedDate = !dominantPlanStopTime || (plannedStopArrivalDate != nil && plannedStopDepartureDate != nil)
                            
                            let departure: StopEvent?
                            if let plannedStopDepartureDate = plannedStopDepartureDate {
                                departure = StopEvent(location: stopLocation, plannedTime: plannedStopDepartureDate, predictedTime: validPredictedDate ? predictedStopDepartureDate : nil, plannedPlatform: plannedStopDeparturePosition, predictedPlatform: predictedStopDeparturePosition, cancelled: stopDepartureCancelled)
                            } else {
                                departure = nil
                            }
                            let arrival: StopEvent?
                            if let plannedStopArrivalDate = plannedStopArrivalDate {
                                arrival = StopEvent(location: stopLocation, plannedTime: plannedStopArrivalDate, predictedTime: validPredictedDate ? predictedStopArrivalDate : nil, plannedPlatform: plannedStopArrivalPosition, predictedPlatform: predictedStopArrivalPosition, cancelled: stopArrivalCancelled)
                            } else {
                                arrival = nil
                            }
                            
                            let stop = Stop(location: stopLocation, departure: departure, arrival: arrival, message: nil)
                            intermediateStops.append(stop)
                        }
                    }
                    
                    let leg: Leg
                    if type == 1 /* Fussweg */ || type == 3 /* Uebergang */ || type == 4 /* Uebergang */ {
                        let individualType: IndividualLeg.`Type`
                        if let routingType = routingType {
                            if routingType == "FOOT" {
                                individualType = .walk
                            } else if routingType == "BIKE" {
                                individualType = .bike
                            } else if routingType == "CAR" || routingType == "P+R" {
                                individualType = .car
                            } else {
                                throw ParseError(reason: "unknown routing type \(routingType)")
                            }
                        } else {
                            individualType = type == 1 ? .walk : .transfer
                        }
                        
                        let departureTime = Date(timeIntervalSince1970: predictedDepartureTime != 0 ? predictedDepartureTime : plannedDepartureTime)
                        let arrivalTime = Date(timeIntervalSince1970: predictedArrivalTime != 0 ? predictedArrivalTime : plannedArrivalTime)
                        
                        let lastLeg: Leg? = legs.count > 0 ? legs[legs.count - 1] : nil
                        if let lastLeg = lastLeg as? IndividualLeg, lastLeg.type == individualType {
                            let lastIndividualLeg = legs.remove(at: legs.count - 1)
                            leg = IndividualLeg(type: individualType, departureTime: lastIndividualLeg.departureTime, departure: lastIndividualLeg.departure, arrival: arrivalLocation, arrivalTime: arrivalTime, distance: 0, path: [])
                        } else {
                            let addTime: TimeInterval = !legs.isEmpty ? max(0, -departureTime.timeIntervalSince(legs.last!.maxTime)) : 0
                            leg = IndividualLeg(type: individualType, departureTime: departureTime.addingTimeInterval(addTime), departure: departureLocation, arrival: arrivalLocation, arrivalTime: arrivalTime.addingTimeInterval(addTime), distance: 0, path: [])
                        }
                    } else if type == 2 {
                        let lineProduct: Product?
                        if lineOnDemand {
                            lineProduct = .onDemand
                        } else if lineClass != 0 {
                            lineProduct = try intToProduct(productInt: lineClass)
                        } else if let lineCategory = lineCategory {
                            lineProduct = normalize(type: lineCategory)
                        } else {
                            lineProduct = nil
                        }
                        
                        let line = newLine(network: lineNetwork, product: lineProduct, normalizedName: normalize(lineName: lineName ?? ""), comment: lineComment, attrs: lineAttrs)
                        
                        let direction: Location?
                        if let directionStr = directionStr {
                            let directionPlaceAndName = split(stationName: directionStr)
                            direction = Location(type: .any, id: nil, coord: nil, place: directionPlaceAndName.0, name: directionPlaceAndName.1)
                        } else {
                            direction = nil
                        }
                        
                        guard plannedDepartureTime != 0 else { throw ParseError(reason: "failed to parse departure time") }
                        guard plannedArrivalTime != 0 else { throw ParseError(reason: "failed to parse arrival time") }
                        
                        let departure = StopEvent(location: departureLocation, plannedTime: Date(timeIntervalSince1970: plannedDepartureTime), predictedTime: predictedDepartureTime != 0 ? Date(timeIntervalSince1970: predictedDepartureTime) : nil, plannedPlatform: plannedDeparturePosition, predictedPlatform: predictedDeparturePosition, cancelled: departureCancelled)
                        let arrival = StopEvent(location: arrivalLocation, plannedTime: Date(timeIntervalSince1970: plannedArrivalTime), predictedTime: predictedArrivalTime != 0 ? Date(timeIntervalSince1970: predictedArrivalTime) : nil, plannedPlatform: plannedArrivalPosition, predictedPlatform: predictedArrivalPosition, cancelled: arrivalCancelled)
                        
                        let journeyContext: HafasLegacyJourneyContext?
                        if let destination = direction {
                            journeyContext = HafasLegacyJourneyContext(from: departure.location, to: destination, time: departure.predictedTime ?? departure.plannedTime, plannedTime: departure.plannedTime, product: line.product, line: line)
                        } else {
                            journeyContext = nil
                        }
                        
                        leg = PublicLeg(line: line, destination: direction, departure: departure, arrival: arrival, intermediateStops: intermediateStops, message: disruptionText, path: [], journeyContext: journeyContext, wagonSequenceContext: nil, loadFactor: nil)
                    } else {
                        throw ParseError(reason: "unhandled type \(type)")
                    }
                    legs.append(leg)
                }
                let context: HafasLegacyRefreshTripContext? = nil
                let trip = Trip(id: "", from: resDeparture, to: resArrival, legs: legs, duration: duration, fares: [], refreshContext: context)
                if realtimeStatus == 2 { // Verbindung fällt aus
                    for leg in trip.legs {
                        guard let leg = leg as? PublicLeg else { continue }
                        leg.intermediateStops.forEach({$0.departure?.cancelled = true; $0.arrival?.cancelled = true})
                    }
                }
                trips.append(trip)
            }
            
        }
        let context: QueryTripsBinaryContext?
        if let requestId = requestId {
            let canQueryMore = trips.count != 1 || trips[0].legs.count != 1 || !(trips[0].legs[0] is IndividualLeg)
            context = QueryTripsBinaryContext(ident: requestId, seqNr: "\(seqNr)", ld: ld, canQueryMore: canQueryMore)
        } else {
            context = nil
        }
        
        completion(request, .success(context: context, from: from, via: via, to: to, trips: trips, messages: []))
    }
    
    override func queryJourneyDetailParsing(request: HttpRequest, context: QueryJourneyDetailContext, completion: @escaping (HttpRequest, QueryJourneyDetailResult) -> Void) throws {
        // does not apply
    }
    
    // MARK: Request parameters
    
    func jsonGetStopParameters(builder: UrlBuilder, constraint: String) {
        builder.addParameter(key: "getstop", value: 1)
        builder.addParameter(key: "REQ0JourneyStopsS0A", value: 255)
        builder.addParameter(key: "REQ0JourneyStopsS0G", value: constraint)
        builder.addParameter(key: "js", value: true)
    }
    
    func xmlNearbyStationsParameters(builder: UrlBuilder, id: String) {
        builder.addParameter(key: "productsFilter", value: allProductsString())
        builder.addParameter(key: "boardType", value: "dep")
        builder.addParameter(key: "input", value: normalize(stationId: id))
        builder.addParameter(key: "sTI", value: 1)
        builder.addParameter(key: "start", value: "yes")
        builder.addParameter(key: "hcount", value: 0)
        builder.addParameter(key: "L", value: "vs_java3")
        if let clientType = clientType {
            builder.addParameter(key: "clientType", value: clientType)
        }
    }
    
    func jsonNearbyStationParameters(builder: UrlBuilder, lat: Int, lon: Int, maxDistance: Int, maxLocations: Int) {
        builder.addParameter(key: "performLocating", value: 2)
        builder.addParameter(key: "tpl", value: "stop2json")
        builder.addParameter(key: "look_stopclass", value: allProductsInt())
        builder.addParameter(key: "look_nv", value: "get_stopweight|yes")
        builder.addParameter(key: "look_x", value: lon)
        builder.addParameter(key: "look_y", value: lat)
        builder.addParameter(key: "look_maxno", value: maxLocations != 0 ? maxLocations : 200)
        builder.addParameter(key: "look_maxdist", value: maxDistance != 0 ? maxDistance : 5000)
    }
    
    func jsonNearbyPOIsParameters(builder: UrlBuilder, lat: Int, lon: Int, maxDistance: Int, maxLocations: Int) {
        builder.addParameter(key: "performLocating", value: 4)
        builder.addParameter(key: "tpl", value: "poi2json")
        builder.addParameter(key: "look_x", value: lon)
        builder.addParameter(key: "look_y", value: lat)
        builder.addParameter(key: "look_maxno", value: maxLocations != 0 ? maxLocations : 200)
        builder.addParameter(key: "look_maxdist", value: maxDistance != 0 ? maxDistance : 5000)
    }
    
    func queryMoreTripsBinaryParameters(builder: UrlBuilder, context: QueryTripsBinaryContext, later: Bool) {
        builder.addParameter(key: "seqnr", value: context.seqNr)
        builder.addParameter(key: "ident", value: context.ident)
        if let ld = context.ld {
            builder.addParameter(key: "ld", value: ld)
        }
        builder.addParameter(key: "REQ0HafasScrollDir", value: later ? 1 : 2)
        builder.addParameter(key: "h2g-direct", value: 11)
        if let clientType = clientType {
            builder.addParameter(key: "clientType", value: clientType)
        }
    }
    
    func refreshTripBinaryParameters(builder: UrlBuilder, context: HafasLegacyRefreshTripContext) {
        builder.addParameter(key: "seqnr", value: context.seqNr)
        builder.addParameter(key: "ident", value: context.ident)
        if let ld = context.ld {
            builder.addParameter(key: "ld", value: ld)
        }
        builder.addParameter(key: "HWAI=CONNECTION$\(context.connectionId)!id", value: "\(context.connectionId)!HwaiConId=\(context.connectionId)!HwaiDetailStatus=details!HwaiMoreDetailStatus=none!HwaiAdditionalInformation=none!")
        builder.addParameter(key: "h2g-direct", value: 11)
        if let clientType = clientType {
            builder.addParameter(key: "clientType", value: clientType)
        }
    }
    
    // MARK: Response parse methods
    
    func parseDate(reader: Reader) -> TimeInterval {
        let days = reader.readShortReverse()
        
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents()
        components.timeZone = timeZone
        components.setValue(1980, for: .year)
        let date = calendar.date(from: components as DateComponents)
        let newDate = calendar.date(byAdding: .day, value: days - 1, to: date!)
        
        return newDate!.timeIntervalSince1970
    }
    
    func parseTime(reader: Reader, baseDate: TimeInterval, dayOffset: Int) throws -> TimeInterval {
        let value = reader.readShortReverse()
        if value == 0xffff {
            return 0
        }
        let hours = value / 100
        let minutes = value % 100
        if minutes < 0 || minutes > 60 {
            throw ParseError(reason: "minutes out of range \(minutes)")
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        
        var result = Date(timeIntervalSince1970: baseDate)
        result = calendar.date(byAdding: .day, value: dayOffset, to: result)!
        result = calendar.date(byAdding: .hour, value: hours, to: result)!
        result = calendar.date(byAdding: .minute, value: minutes, to: result)!
        
        return result.timeIntervalSince1970
    }
    
    let P_CATEGORY_FROM_NAME = try! NSRegularExpression(pattern: "([A-Za-zßÄÅäáàâåéèêíìîÖöóòôÜüúùûØ]+).*", options: .caseInsensitive)
    
    private func category(from name: String) -> String {
        if let match = P_CATEGORY_FROM_NAME.firstMatch(in: name, options: [], range: NSMakeRange(0, name.count)) {
            let substring = (name as NSString).substring(with: match.range(at: 1))
            return substring
        }
        return name
    }
    
    let P_EUROPEAN_TIME = try! NSRegularExpression(pattern: "(\\d{1,2}):(\\d{2})(?::(\\d{2}))?", options: .caseInsensitive)
    let P_GERMAN_DATE = try! NSRegularExpression(pattern: "(\\d{2})[\\./-](\\d{2})[\\./-](\\d{2,4})", options: .caseInsensitive)
    
    private func parseTimeAndDate(timeString: String, dateString: String) throws -> Date {
        guard let timeMatch = timeString.match(pattern: P_EUROPEAN_TIME) else {
            throw ParseError(reason: "illegal time format")
        }
        let hourStr = timeMatch[0] ?? ""
        let minuteStr = timeMatch[1] ?? ""
        let secondStr = timeMatch[2] ?? ""
        
        var dateComponents = DateComponents()
        dateComponents.timeZone = timeZone
        dateComponents.hour = Int(hourStr)!
        dateComponents.minute = Int(minuteStr)!
        dateComponents.second = Int(secondStr) ?? 0
        
        if dateString.count == 8, let match = dateString.match(pattern: P_GERMAN_DATE) {
            let dayStr = match[0] ?? ""
            let monthStr = match[1] ?? ""
            let yearStr = match[2] ?? ""
            
            let day = Int(dayStr)
            let month = Int(monthStr)
            
            dateComponents.day = day
            dateComponents.month = month
            
            if let year = Int(yearStr) {
                dateComponents.year = year > 100 ? year : 2000 + year
            }
        } else if dateString.count == 10 {
            parseIsoDate(from: dateString, dateComponents: &dateComponents)
        } else {
            throw ParseError(reason: "illegal date format")
        }
        
        if let date = gregorianCalendar.date(from: dateComponents) {
            return date
        } else {
            throw ParseError(reason: "illegal date format")
        }
    }
    
    private func location(reader: Reader, strings: StringTable) -> Location? {
        let name = strings.read(reader: reader)
        reader.skipBytes(2)
        let type = reader.readShortReverse()
        let lon = reader.readIntReverse()
        let lat = reader.readIntReverse()
        
        if type == 1 {
            let placeAndName = split(stationName: name)
            return Location(type: .station, id: nil, coord: LocationPoint(lat: lat, lon: lon), place: placeAndName.0, name: placeAndName.1)
        } else if type == 2 {
            let placeAndName = split(address: name)
            return Location(type: .address, id: nil, coord: LocationPoint(lat: lat, lon: lon), place: placeAndName.0, name: placeAndName.1)
        } else if type == 3 {
            let placeAndName = split(poi: name)
            return Location(type: .poi, id: nil, coord: LocationPoint(lat: lat, lon: lon), place: placeAndName.0, name: placeAndName.1)
        } else {
            return nil
        }
    }
    
    // MARK: Line styles
    
    //    private let _P_NORMALIZE_LINE_BUS = try! NSRegularExpression(pattern: "Bus\\s*(\\d+)")
    //    private let _P_NORMALIZE_LINE_NACHTBUS = try! NSRegularExpression(pattern: "Bus\\s*N\\s*(\\d+)")
    //    private let _P_NORMALIZE_LINE_BUS_S = try! NSRegularExpression(pattern: "Bus\\s*S\\s*(\\d+)")
    //    private let _P_NORMALIZE_LINE_BUS_X = try! NSRegularExpression(pattern: "Bus\\s*X\\s*(\\d+)")
    private let _P_NORMALIZE_LINE_BUS = try! NSRegularExpression(pattern: "(?:Bus|BUS)\\s*(.*)")
    private let _P_NORMALIZE_LINE_TRAM = try! NSRegularExpression(pattern: "(?:Tram|Tra|Str|STR)\\s*(.*)")
    
    
    func parseLine(type: String, normalizedName: String?, wheelchairAccess: Bool) throws -> Line {
        //        if type == "1" {
        //            if let label = line.match(pattern: _P_NORMALIZE_LINE_BUS)?[0] {
        //                return Line(id: nil, network: nil, product: .BUS, label: label, name: nil, style: lineStyle(network: nil, product: .BUS, label: label), attr: nil, message: nil)
        //            } else if let label = line.match(pattern: _P_NORMALIZE_LINE_NACHTBUS)?[0] {
        //                return Line(id: nil, network: nil, product: .BUS, label: "N" + label, name: nil, style: lineStyle(network: nil, product: .BUS, label: "N" + label), attr: nil, message: nil)
        //            } else if let label = line.match(pattern: _P_NORMALIZE_LINE_BUS_S)?[0] {
        //                return Line(id: nil, network: nil, product: .BUS, label: "S" + label, name: nil, style: lineStyle(network: nil, product: .BUS, label: "S" + label), attr: nil, message: nil)
        //            } else if let label = line.match(pattern: _P_NORMALIZE_LINE_BUS_X)?[0] {
        //                return Line(id: nil, network: nil, product: .BUS, label: "X" + label, name: nil, style: lineStyle(network: nil, product: .BUS, label: "X" + label), attr: nil, message: nil)
        //            }
        //        }
        
        if let normalizedName = normalizedName {
            if let match = normalizedName.match(pattern: _P_NORMALIZE_LINE_BUS)?[0] {
                return newLine(network: nil, product: .bus, normalizedName: match, comment: nil, attrs: [])
            }
            if let match = normalizedName.match(pattern: P_NORMALIZE_LINE_TRAM)?[0] {
                return newLine(network: nil, product: .tram, normalizedName: match, comment: nil, attrs: [])
            }
        }
        let normalizedType = normalize(type: type)
        let attrs: [Line.Attr] = wheelchairAccess ? [.wheelChairAccess] : []
        
        if let normalizedName = normalizedName {
            let name: String
            if let match = normalizedName.match(pattern: P_NORMALIZE_LINE), let m1 = match[0], let m2 = match[2] {
                name = m1 + m2
            } else {
                name = normalizedName
            }
            return newLine(network: nil, product: normalizedType, normalizedName: name, comment: nil, attrs: attrs)
        } else {
            return newLine(network: nil, product: normalizedType, normalizedName: nil, comment: nil, attrs: attrs)
        }
    }
    
    let P_NORMALIZE_LINE_AND_TYPE = try! NSRegularExpression(pattern: "([^#]*)#(.*)", options: .caseInsensitive)
    let P_NORMALIZE_LINE_NUMBER = try! NSRegularExpression(pattern: "\\d{2,5}", options: .caseInsensitive)
    let P_LINE_RUSSIA = try! NSRegularExpression(pattern: "\\d{3}(?:AJ|BJ|CJ|DJ|EJ|FJ|GJ|IJ|KJ|LJ|NJ|MJ|OJ|RJ|SJ|TJ|UJ|VJ|ZJ|CH|KH|ZH|EI|JA|JI|MZ|SH|SZ|PC|Y|YJ)", options: .caseInsensitive)
    let P_NORMALIZE_LINE_BUS = try! NSRegularExpression(pattern: "(?:Bus|BUS)\\s*(.*)", options: .caseInsensitive)
    let P_NORMALIZE_LINE_TRAM = try! NSRegularExpression(pattern: "(?:Tram|Tra|Str|STR)\\s*(.*)", options: .caseInsensitive)
    
    func parse(lineAndType: String) throws -> Line {
        guard let lineAndTypeMatch = P_NORMALIZE_LINE_AND_TYPE.firstMatch(in: lineAndType, options: [], range: NSMakeRange(0, lineAndType.count)) else {
            throw ParseError(reason: "cannot normalize \(lineAndType)")
        }
        let number = (lineAndType as NSString).substring(with: lineAndTypeMatch.range(at: 1))
        let type = (lineAndType as NSString).substring(with: lineAndTypeMatch.range(at: 2))
        
        if type.isEmpty {
            if number.count == 0 {
                return newLine(network: nil, product: nil, normalizedName: nil, comment: nil, attrs: [])
            } else if let _ = P_NORMALIZE_LINE_NUMBER.firstMatch(in: number, options: [], range: NSMakeRange(0, number.count)) {
                return newLine(network: nil, product: nil, normalizedName: number, comment: nil, attrs: [])
            } else if let _ = P_LINE_RUSSIA.firstMatch(in: number, options: [], range: NSMakeRange(0, number.count)) {
                return newLine(network: nil, product: .regionalTrain, normalizedName: number, comment: nil, attrs: [])
            } else {
                throw ParseError(reason: "cannot normalize \(lineAndType)")
            }
        } else {
            let normalizedType = normalize(type: type)
            if let normalizedType = normalizedType {
                if normalizedType == .bus, let matcher = P_NORMALIZE_LINE_BUS.firstMatch(in: number, options: [], range: NSMakeRange(0, number.count)) {
                    return newLine(network: nil, product: .bus, normalizedName: (number as NSString).substring(with: matcher.range(at: 1)), comment: nil, attrs: [])
                } else if normalizedType == .tram, let matcher = P_NORMALIZE_LINE_TRAM.firstMatch(in: number, options: [], range: NSMakeRange(0, number.count)) {
                    return newLine(network: nil, product: .tram, normalizedName: (number as NSString).substring(with: matcher.range(at: 1)), comment: nil, attrs: [])
                }
            }
            return newLine(network: nil, product: normalizedType, normalizedName: number.replacingOccurrences(of: " ", with: ""), comment: nil, attrs: [])
        }
    }
    
    func normalize(type: String) -> Product? {
        let ucType = type.uppercased()
        
        // Intercity
        if "EC" == ucType { // EuroCity
            return .highSpeedTrain
        } else if "ECE" == ucType { // EuroCity Express
            return .highSpeedTrain
        } else if "EN" == ucType { // EuroNight
            return .highSpeedTrain
        } else if "D" == ucType { // EuroNight, Sitzwagenabteil
            return .highSpeedTrain
        } else if "EIC" == ucType { // Ekspres InterCity, Polen
            return .highSpeedTrain
        } else if "ICE" == ucType { // InterCityExpress
            return .highSpeedTrain
        } else if "IC" == ucType { // InterCity
            return .highSpeedTrain
        } else if "ICT" == ucType { // InterCity
            return .highSpeedTrain
        } else if "ICN" == ucType { // InterCityNight
            return .highSpeedTrain
        } else if "ICD" == ucType { // Intercity direkt Amsterdam-Breda
            return .highSpeedTrain
        } else if "CNL" == ucType { // CityNightLine
            return .highSpeedTrain
        } else if "MT" == ucType { // Schnee-Express
            return .highSpeedTrain
        } else if "OEC" == ucType { // ÖBB-EuroCity
            return .highSpeedTrain
        } else if "OIC" == ucType { // ÖBB-InterCity
            return .highSpeedTrain
        } else if "RJ" == ucType { // RailJet, Österreichische Bundesbahnen
            return .highSpeedTrain
        } else if "WB" == ucType { // westbahn
            return .highSpeedTrain
        } else if "THA" == ucType { // Thalys
            return .highSpeedTrain
        } else if "TGV" == ucType { // Train à Grande Vitesse
            return .highSpeedTrain
        } else if "DNZ" == ucType { // Nacht-Schnellzug
            return .highSpeedTrain
        } else if "AIR" == ucType { // Generic Flight
            return .highSpeedTrain
        } else if "ECB" == ucType { // EC, Verona-München
            return .highSpeedTrain
        } else if "LYN" == ucType { // Dänemark
            return .highSpeedTrain
        } else if "NZ" == ucType { // Schweden, Nacht
            return .highSpeedTrain
        } else if "INZ" == ucType { // Nacht
            return .highSpeedTrain
        } else if "RHI" == ucType { // ICE
            return .highSpeedTrain
        } else if "RHT" == ucType { // TGV
            return .highSpeedTrain
        } else if "TGD" == ucType { // TGV
            return .highSpeedTrain
        } else if "IRX" == ucType { // IC
            return .highSpeedTrain
        } else if "EUR" == ucType { // Eurostar
            return .highSpeedTrain
        } else if "ES" == ucType { // Eurostar Italia
            return .highSpeedTrain
        } else if "EST" == ucType { // Eurostar Frankreich
            return .highSpeedTrain
        } else if "EM" == ucType { // Euromed, Barcelona-Alicante, Spanien
            return .highSpeedTrain
        } else if "A" == ucType { // Spain, Highspeed
            return .highSpeedTrain
        } else if "AVE" == ucType { // Alta Velocidad Española, Spanien
            return .highSpeedTrain
        } else if "ARC" == ucType { // Arco (Renfe), Spanien
            return .highSpeedTrain
        } else if "ALS" == ucType { // Alaris (Renfe), Spanien
            return .highSpeedTrain
        } else if "ATR" == ucType { // Altaria (Renfe), Spanien
            return .regionalTrain
        } else if "TAL" == ucType { // Talgo, Spanien
            return .highSpeedTrain
        } else if "TLG" == ucType { // Spanien, Madrid
            return .highSpeedTrain
        } else if "HOT" == ucType { // Spanien, Nacht
            return .highSpeedTrain
        } else if "X2" == ucType { // X2000 Neigezug, Schweden
            return .highSpeedTrain
        } else if "X" == ucType { // InterConnex
            return .highSpeedTrain
        } else if "FYR" == ucType { // Fyra, Amsterdam-Schiphol-Rotterdam
            return .highSpeedTrain
        } else if "FYRA" == ucType { // Fyra, Amsterdam-Schiphol-Rotterdam
            return .highSpeedTrain
        } else if "SC" == ucType { // SuperCity, Tschechien
            return .highSpeedTrain
        } else if "LE" == ucType { // LEO Express, Prag
            return .highSpeedTrain
        } else if "FLUG" == ucType {
            return .highSpeedTrain
        } else if "TLK" == ucType { // Tanie Linie Kolejowe, Polen
            return .highSpeedTrain
        } else if "PKP" == ucType { // Polskie Koleje Państwowe (Polnische Staatsbahnen)
            return .highSpeedTrain
        } else if "EIP" == ucType { // Express Intercity Premium
            return .highSpeedTrain
        } else if "INT" == ucType { // Zürich-Brüssel - Budapest-Istanbul
            return .highSpeedTrain
        } else if "HKX" == ucType { // Hamburg-Koeln-Express
            return .highSpeedTrain
        } else if "LOC" == ucType { // Locomore
            return .regionalTrain
        } else if "NJ" == ucType {
            return .highSpeedTrain
        } else if "FLX" == ucType {
            return .highSpeedTrain
        } else if "RJX" == ucType { // railjet xpress
            return .highSpeedTrain
        } else if "ICL" == ucType { // InterCity Lyn, Denmark
            return .highSpeedTrain
        } else if "FR" == ucType { // Frecciarossa, Italy
            return .highSpeedTrain
        } else if "FA" == ucType { // Frecciarossa, Italy
            return .highSpeedTrain
        }
        
        // Regional
        if "ZUG" == ucType { // Generic Train
            return .regionalTrain
        } else if "R" == ucType { // Generic Regional Train
            return .regionalTrain
        } else if "DPN" == ucType { // Dritter Personen Nahverkehr
            return .regionalTrain
        } else if "RB" == ucType { // RegionalBahn
            return .regionalTrain
        } else if "RE" == ucType { // RegionalExpress
            return .regionalTrain
        } else if "ER" == ucType {
            return .regionalTrain
        } else if "DB" == ucType {
            return .regionalTrain
        } else if "IR" == ucType { // Interregio
            return .regionalTrain
        } else if "IRE" == ucType { // Interregio Express
            return .regionalTrain
        } else if "HEX" == ucType { // Harz-Berlin-Express, Veolia
            return .regionalTrain
        } else if "WFB" == ucType { // Westfalenbahn
            return .regionalTrain
        } else if "RT" == ucType { // RegioTram
            return .regionalTrain
        } else if "REX" == ucType { // RegionalExpress, Österreich
            return .regionalTrain
        } else if "OS" == ucType { // Osobný vlak, Slovakia oder Osobní vlak, Czech Republic
            return .regionalTrain
        } else if "SP" == ucType { // Spěšný vlak, Czech Republic
            return .regionalTrain
        } else if "RX" == ucType { // Express, Czech Republic
            return .regionalTrain
        } else if "EZ" == ucType { // ÖBB ErlebnisBahn
            return .regionalTrain
        } else if "ARZ" == ucType { // Auto-Reisezug Brig - Iselle di Trasquera
            return .regionalTrain
        } else if "OE" == ucType { // Ostdeutsche Eisenbahn
            return .regionalTrain
        } else if "MR" == ucType { // Märkische Regionalbahn
            return .regionalTrain
        } else if "PE" == ucType { // Prignitzer Eisenbahn GmbH
            return .regionalTrain
        } else if "NE" == ucType { // NEB Betriebsgesellschaft mbH
            return .regionalTrain
        } else if "MRB" == ucType { // Mitteldeutsche Regiobahn
            return .regionalTrain
        } else if "ERB" == ucType { // eurobahn (Keolis Deutschland)
            return .regionalTrain
        } else if "HLB" == ucType { // Hessische Landesbahn
            return .regionalTrain
        } else if "VIA" == ucType {
            return .regionalTrain
        } else if "HSB" == ucType { // Harzer Schmalspurbahnen
            return .regionalTrain
        } else if "OSB" == ucType { // Ortenau-S-Bahn
            return .regionalTrain
        } else if "VBG" == ucType { // Vogtlandbahn
            return .regionalTrain
        } else if "AKN" == ucType { // AKN Eisenbahn AG
            return .regionalTrain
        } else if "OLA" == ucType { // Ostseeland Verkehr
            return .regionalTrain
        } else if "UBB" == ucType { // Usedomer Bäderbahn
            return .regionalTrain
        } else if "PEG" == ucType { // Prignitzer Eisenbahn
            return .regionalTrain
        } else if "NWB" == ucType { // NordWestBahn
            return .regionalTrain
        } else if "CAN" == ucType { // cantus Verkehrsgesellschaft
            return .regionalTrain
        } else if "BRB" == ucType { // ABELLIO Rail
            return .regionalTrain
        } else if "SBB" == ucType { // Schweizerische Bundesbahnen
            return .regionalTrain
        } else if "VEC" == ucType { // vectus Verkehrsgesellschaft
            return .regionalTrain
        } else if "TLX" == ucType { // Trilex (Vogtlandbahn)
            return .regionalTrain
        } else if "TL" == ucType { // Trilex (Vogtlandbahn)
            return .regionalTrain
        } else if "HZL" == ucType { // Hohenzollerische Landesbahn
            return .regionalTrain
        } else if "ABR" == ucType { // Bayerische Regiobahn
            return .regionalTrain
        } else if "CB" == ucType { // City Bahn Chemnitz
            return .regionalTrain
        } else if "WEG" == ucType { // Württembergische Eisenbahn-Gesellschaft
            return .regionalTrain
        } else if "NEB" == ucType { // Niederbarnimer Eisenbahn
            return .regionalTrain
        } else if "ME" == ucType { // metronom Eisenbahngesellschaft
            return .regionalTrain
        } else if "MER" == ucType { // metronom regional
            return .regionalTrain
        } else if "ALX" == ucType { // Arriva-Länderbahn-Express
            return .regionalTrain
        } else if "EB" == ucType { // Erfurter Bahn
            return .regionalTrain
        } else if "EBX" == ucType { // Erfurter Bahn
            return .regionalTrain
        } else if "VEN" == ucType { // Rhenus Veniro
            return .regionalTrain
        } else if "BOB" == ucType { // Bayerische Oberlandbahn
            return .regionalTrain
        } else if "SBS" == ucType { // Städtebahn Sachsen
            return .regionalTrain
        } else if "SES" == ucType { // Städtebahn Sachsen Express
            return .regionalTrain
        } else if "EVB" == ucType { // Eisenbahnen und Verkehrsbetriebe Elbe-Weser
            return .regionalTrain
        } else if "STB" == ucType { // Süd-Thüringen-Bahn
            return .regionalTrain
        } else if "STX" == ucType { // Süd-Thüringen-Bahn
            return .regionalTrain
        } else if "AG" == ucType { // Ingolstadt-Landshut
            return .regionalTrain
        } else if "PRE" == ucType { // Pressnitztalbahn
            return .regionalTrain
        } else if "DBG" == ucType { // Döllnitzbahn GmbH
            return .regionalTrain
        } else if "SHB" == ucType { // Schleswig-Holstein-Bahn
            return .regionalTrain
        } else if "NOB" == ucType { // Nord-Ostsee-Bahn
            return .regionalTrain
        } else if "RTB" == ucType { // Rurtalbahn
            return .regionalTrain
        } else if "BLB" == ucType { // Berchtesgadener Land Bahn
            return .regionalTrain
        } else if "NBE" == ucType { // Nordbahn Eisenbahngesellschaft
            return .regionalTrain
        } else if "SOE" == ucType { // Sächsisch-Oberlausitzer Eisenbahngesellschaft
            return .regionalTrain
        } else if "SDG" == ucType { // Sächsische Dampfeisenbahngesellschaft
            return .regionalTrain
        } else if "VE" == ucType { // Lutherstadt Wittenberg
            return .regionalTrain
        } else if "DAB" == ucType { // Daadetalbahn
            return .regionalTrain
        } else if "WTB" == ucType { // Wutachtalbahn e.V.
            return .regionalTrain
        } else if "BE" == ucType { // Grensland-Express
            return .regionalTrain
        } else if "ARR" == ucType { // Ostfriesland
            return .regionalTrain
        } else if "HTB" == ucType { // Hörseltalbahn
            return .regionalTrain
        } else if "FEG" == ucType { // Freiberger Eisenbahngesellschaft
            return .regionalTrain
        } else if "NEG" == ucType { // Norddeutsche Eisenbahngesellschaft Niebüll
            return .regionalTrain
        } else if "RBG" == ucType { // Regental Bahnbetriebs GmbH
            return .regionalTrain
        } else if "MBB" == ucType { // Mecklenburgische Bäderbahn Molli
            return .regionalTrain
        } else if "VEB" == ucType { // Vulkan-Eifel-Bahn Betriebsgesellschaft
            return .regionalTrain
        } else if "LEO" == ucType { // Chiemgauer Lokalbahn
            return .regionalTrain
        } else if "VX" == ucType { // Vogtland Express
            return .regionalTrain
        } else if "MSB" == ucType { // Mainschleifenbahn
            return .regionalTrain
        } else if "P" == ucType { // Kasbachtalbahn
            return .regionalTrain
        } else if "ÖBA" == ucType { // Öchsle-Bahn Betriebsgesellschaft
            return .regionalTrain
        } else if "KTB" == ucType { // Kandertalbahn
            return .regionalTrain
        } else if "ERX" == ucType { // erixx
            return .regionalTrain
        } else if "ATZ" == ucType { // Autotunnelzug
            return .regionalTrain
        } else if "ATB" == ucType { // Autoschleuse Tauernbahn
            return .regionalTrain
        } else if "CAT" == ucType { // City Airport Train
            return .regionalTrain
        } else if "EXTRA" == ucType || "EXT" == ucType { // Extrazug
            return .regionalTrain
        } else if "KD" == ucType { // Koleje Dolnośląskie (Niederschlesische Eisenbahn)
            return .regionalTrain
        } else if "KM" == ucType { // Koleje Mazowieckie
            return .regionalTrain
        } else if "EX" == ucType { // Polen
            return .regionalTrain
        } else if "PCC" == ucType { // PCC Rail, Polen
            return .regionalTrain
        } else if "ZR" == ucType { // ZSR (Slovakian Republic Railways)
            return .regionalTrain
        } else if "RNV" == ucType { // Rhein-Neckar-Verkehr GmbH
            return .regionalTrain
        } else if "DWE" == ucType { // Dessau-Wörlitzer Eisenbahn
            return .regionalTrain
        } else if "BKB" == ucType { // Buckower Kleinbahn
            return .regionalTrain
        } else if "GEX" == ucType { // Glacier Express
            return .regionalTrain
        } else if "M" == ucType { // Meridian
            return .regionalTrain
        } else if "WBA" == ucType { // Waldbahn
            return .regionalTrain
        } else if "BEX" == ucType { // Bernina Express
            return .regionalTrain
        } else if "VAE" == ucType { // Voralpen-Express
            return .regionalTrain
        } else if "OPB" == ucType { // oberpfalzbahn
            return .regionalTrain
        } else if "OPX" == ucType { // oberpfalz-express
            return .regionalTrain
        } else if "TER" == ucType { // Transport express régional
            return .regionalTrain
        } else if "ENO" == ucType {
            return .regionalTrain
        } else if "THU" == ucType { // Thurbo AG
            return .regionalTrain
        } else if "GW" == ucType { // gwtr.cz
            return .regionalTrain
        } else if "SE" == ucType { // ABELLIO Rail Mitteldeutschland GmbH
            return .regionalTrain
        } else if "UEX" == ucType { // Slovenia
            return .regionalTrain
        } else if "KW" == ucType { // Koleje Wielkopolskie
            return .regionalTrain
        } else if "KS" == ucType { // Koleje Śląskie
            return .regionalTrain
        } else if "KML" == ucType { // Koleje Malopolskie
            return .regionalTrain
        }
        
        // Suburban Trains
        if ucType =~ "SN?\\d*" { // Generic (Night) S-Bahn
            return .suburbanTrain
        } else if "S-BAHN" == ucType {
            return .suburbanTrain
        } else if "BSB" == ucType { // Breisgau S-Bahn
            return .suburbanTrain
        } else if "SWE" == ucType { // Südwestdeutsche Verkehrs-AG, Ortenau-S-Bahn
            return .suburbanTrain
        } else if "RER" == ucType { // Réseau Express Régional, Frankreich
            return .suburbanTrain
        } else if "WKD" == ucType { // Warszawska Kolej Dojazdowa (Warsaw Suburban Railway)
            return .suburbanTrain
        } else if "SKM" == ucType { // Szybka Kolej Miejska Tricity
            return .suburbanTrain
        } else if "SKW" == ucType { // Szybka Kolej Miejska Warschau
            return .suburbanTrain
        } else if "LKA" == ucType { // Łódzka Kolej Aglomeracyjna
            return .suburbanTrain
        }
        
        // Subway
        if "U" == ucType || "U-BAHN" == ucType { // Generic U-Bahn
            return .subway
        } else if "MET" == ucType {
            return .subway
        } else if "METRO" == ucType {
            return .subway
        }
        
        // Tram
        if ucType =~ "STR\\w{0,5}" { // Generic Tram
            return .tram
        } else if "NFT" == ucType { // Niederflur-Tram
            return .tram
        } else if "TRAM" == ucType {
            return .tram
        } else if "TRA" == ucType {
            return .tram
        } else if "WLB" == ucType { // Wiener Lokalbahnen
            return .tram
        } else if "STRWLB" == ucType { // Wiener Lokalbahnen
            return .tram
        } else if "SCHW-B" == ucType { // Schwebebahn, gilt als "Straßenbahn besonderer Bauart"
            return .tram
        }
        
        // Bus
        if ucType =~ "BUS\\w{0,5}" { // Generic Bus
            return .bus
        } else if "NFB" == ucType { // Niederflur-Bus
            return .bus
        } else if "SEV" == ucType { // Schienen-Ersatz-Verkehr
            return .bus
        } else if "BUSSEV" == ucType { // Schienen-Ersatz-Verkehr
            return .bus
        } else if "BSV" == ucType { // Bus SEV
            return .bus
        } else if "FB" == ucType { // Fernbus? Luxemburg-Saarbrücken
            return .bus
        } else if "EXB" == ucType { // Expressbus München-Prag?
            return .bus
        } else if "ICB" == ucType { // ÖBB ICBus
            return .bus
        } else if "TRO" == ucType { // Trolleybus
            return .bus
        } else if "RFB" == ucType { // Rufbus
            return .bus
        } else if "RUF" == ucType { // Rufbus
            return .bus
        } else if ucType =~ "TAX\\w{0,5}" { // Generic Taxi
            return .bus
        } else if "RFT" == ucType { // Ruftaxi
            return .bus
        } else if "LT" == ucType { // Linien-Taxi
            return .bus
        } else if "NB" == ucType { // Nachtbus Zürich
            return .bus
        } else if "POSTBUS" == ucType {
            return .bus
        }
        
        // Phone
        if "RUFBUS" == ucType {
            return .onDemand
        } else if ucType.hasPrefix("AST") { // Anruf-Sammel-Taxi
            return .onDemand
        } else if ucType.hasPrefix("ALT") { // Anruf-Linien-Taxi
            return .onDemand
        } else if ucType.hasPrefix("BUXI") { // Bus-Taxi (Schweiz)
            return .onDemand
        } else if "TB" == ucType { // Taxi-Bus?
            return .onDemand
        }
        
        // Ferry
        if "SCHIFF" == ucType {
            return .ferry
        } else if "FÄHRE" == ucType {
            return .ferry
        } else if "FÄH" == ucType {
            return .ferry
        } else if "FAE" == ucType {
            return .ferry
        } else if "SCH" == ucType { // Schiff
            return .ferry
        } else if "AS" == ucType { // SyltShuttle
            return .ferry
        } else if "AZS" == ucType { // Autozug Sylt Shuttle
            return .ferry
        } else if "KAT" == ucType { // Katamaran, e.g. Friedrichshafen - Konstanz
            return .ferry
        } else if "BAT" == ucType { // Boots Anlege Terminal?
            return .ferry
        } else if "BAV" == ucType { // Boots Anlege?
            return .ferry
        }
        
        // Cable Car
        if "SEILBAHN" == ucType {
            return .cablecar
        } else if "SB" == ucType { // Seilbahn
            return .cablecar
        } else if "ZAHNR" == ucType { // Zahnradbahn, u.a. Zugspitzbahn
            return .cablecar
        } else if "GB" == ucType { // Gondelbahn
            return .cablecar
        } else if "LB" == ucType { // Luftseilbahn
            return .cablecar
        } else if "FUN" == ucType { // Funiculaire (Standseilbahn)
            return .cablecar
        } else if "SL" == ucType { // Sessel-Lift
            return .cablecar
        }
        
        // Unknown product
        return nil
    }
    
    func newLine(network: String?, product: Product?, normalizedName: String?, comment: String?, attrs: [Line.Attr]) -> Line {
        return Line(id: nil, network: network, product: product, label: normalizedName, name: nil, style: lineStyle(network: network, product: product, label: normalizedName), attr: attrs, message: comment)
    }
    
    let P_NORMALIZE_LINE_ADMINISTRATION = try! NSRegularExpression(pattern: "([^_]*)_*", options: .caseInsensitive)
    
    private func normalize(lineAdministration: String?) -> String? {
        guard let lineAdministration = lineAdministration else { return nil }
        if let match = P_NORMALIZE_LINE_ADMINISTRATION.firstMatch(in: lineAdministration, options: [], range: NSMakeRange(0, lineAdministration.count)) {
            let substring = (lineAdministration as NSString).substring(with: match.range(at: 1))
            return substring
        }
        return lineAdministration
    }
    
    let P_NORMALIZE_LINE_NAME_BUS = try! NSRegularExpression(pattern: "bus\\s+(.*)", options: .caseInsensitive)
    let P_NORMALIZE_LINE = try! NSRegularExpression(pattern: "([A-Za-zßÄÅäáàâåéèêíìîÖöóòôÜüúùûØ/]+)[\\s-]*([^#]*).*", options: .caseInsensitive)
    
    func normalize(lineName: String) -> String {
        if let match = P_NORMALIZE_LINE_NAME_BUS.firstMatch(in: lineName, options: [], range: NSMakeRange(0, lineName.count)) {
            let substring = (lineName as NSString).substring(with: match.range(at: 1))
            return substring
        }
        if let match = P_NORMALIZE_LINE.firstMatch(in: lineName, options: [], range: NSMakeRange(0, lineName.count)) {
            let substring1 = (lineName as NSString).substring(with: match.range(at: 1))
            let substring2 = (lineName as NSString).substring(with: match.range(at: 2))
            return substring1 + substring2
        }
        return lineName
    }
    
    public class QueryTripsBinaryContext: QueryTripsContext {
        
        public override class var supportsSecureCoding: Bool { return true }
        
        public override var canQueryEarlier: Bool { return canQueryMore }
        public override var canQueryLater: Bool { return canQueryMore }
        
        private var canQueryMore: Bool
        
        public var ident: String
        public var seqNr: String
        public var ld: String?
        
        init(ident: String, seqNr: String, ld: String?, canQueryMore: Bool) {
            self.ident = ident
            self.seqNr = seqNr
            self.ld = ld
            self.canQueryMore = canQueryMore
            
            super.init()
        }
        
        public required convenience init?(coder aDecoder: NSCoder) {
            guard
                let ident = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.ident) as String?,
                let seqNr = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.seqNr) as String?
                else {
                    return nil
            }
            let ld = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.ld) as String?
            let canQueryMore = aDecoder.decodeBool(forKey: PropertyKey.canQueryMore)
            self.init(ident: ident, seqNr: seqNr, ld: ld, canQueryMore: canQueryMore)
        }
        
        public override func encode(with aCoder: NSCoder) {
            aCoder.encode(ident, forKey: PropertyKey.ident)
            aCoder.encode(seqNr, forKey: PropertyKey.seqNr)
            aCoder.encode(ld, forKey: PropertyKey.ld)
            aCoder.encode(canQueryMore, forKey: PropertyKey.canQueryMore)
        }
        
        struct PropertyKey {
            static let ident = "ident"
            static let seqNr = "seqNr"
            static let ld = "ld"
            static let canQueryMore = "queryMore"
        }
        
    }
    
    // MARK: Binary data reader
    
    class Reader {
        
        let data: Data
        var pointer = 0
        
        init(data: Data) {
            self.data = data
        }
        
        func read() -> UInt8 {
            let result: UInt8 = data.scanValue(start: pointer, length: 1)[0]
            pointer += 1
            return result
        }
        
        func readShortReverse() -> Int {
            return Int(Int32(read()) &+ Int32(read()) &* 0x100)
        }
        
        func readIntReverse() -> Int {
            var result: Int32 = Int32(read())
            result = result &+ Int32(read()) &* Int32(0x100)
            result = result &+ Int32(read()) &* Int32(0x10000)
            result = result &+ Int32(read()) &* Int32(0x1000000)
            return Int(result)
        }
        
        func reset() {
            pointer = 0
        }
        
        func skipBytes(_ n: Int) {
            pointer += n
        }
        
    }
    
    class StringTable {
        
        var encoding = String.Encoding.ascii
        let bytes: [UInt8]
        
        init(reader: Reader, stringTablePtr: Int, length: Int) {
            bytes = [UInt8](reader.data.subdata(in: stringTablePtr..<stringTablePtr+length))
        }
        
        func read(reader: Reader) -> String? {
            var pointer = reader.readShortReverse()
            if pointer == 0 {
                return nil
            }
            
            var arr: [UInt8] = []
            
            while (true) {
                let c = bytes[pointer]
                pointer += 1
                if c == 0 {
                    break
                }
                arr.append(c)
            }
            
            return String(bytes: arr, encoding: encoding)?.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
    }
    
    class StationTable {
        
        let provider: AbstractHafasLegacyProvider
        let strings: StringTable
        let data: Data
        
        init(provider: AbstractHafasLegacyProvider, reader: Reader, stationTablePtr: Int, length: Int, strings: StringTable) {
            self.provider = provider
            self.strings = strings
            data = reader.data.subdata(in: stationTablePtr..<stationTablePtr+length)
        }
        
        func read(reader: Reader) throws -> Location? {
            let index = reader.readShortReverse()
            let ptr = index * 14
            if ptr >= data.count {
                throw ParseError(reason: "ptr \(ptr) cannot exceed stations table size \(data.count)")
            }
            let stationsReader = Reader(data: data.subdata(in: ptr..<ptr+14))
            let placeAndName = provider.split(stationName: strings.read(reader: stationsReader))
            let id = stationsReader.readIntReverse()
            let lon = stationsReader.readIntReverse()
            let lat = stationsReader.readIntReverse()
            
            return Location(type: .station, id: id != 0 ? "\(id)" : nil, coord: LocationPoint(lat: lat, lon: lon), place: placeAndName.0, name: placeAndName.1)
        }
        
    }
    
    class CommentTable {
        
        let strings: StringTable
        let data: Data
        
        init(reader: Reader, commentTablePtr: Int, length: Int, strings: StringTable) {
            self.strings = strings
            data = reader.data.subdata(in: commentTablePtr..<commentTablePtr+length)
        }
        
        func read(reader: Reader) throws -> [String] {
            let ptr = reader.readShortReverse()
            if ptr >= data.count {
                throw ParseError(reason: "ptr \(ptr) cannot exceed comment table size \(data.count)")
            }
            let commentReader = Reader(data: data.subdata(in: ptr..<data.count))
            let numComments = commentReader.readShortReverse()
            var comments: [String] = []
            for _ in 0..<numComments {
                comments.append(strings.read(reader: commentReader)!)
            }
            return comments
        }
        
    }
    
}

public class HafasLegacyJourneyContext: QueryJourneyDetailManuallyContext {}

public class HafasLegacyRefreshTripContext: RefreshTripContext {
    
    public override class var supportsSecureCoding: Bool { return true }
    
    let ident: String
    let seqNr: String
    let ld: String?
    let connectionId: String
    
    init(ident: String, seqNr: String, ld: String?, connectionId: String) {
        self.ident = ident
        self.seqNr = seqNr
        self.ld = ld
        self.connectionId = connectionId
        super.init()
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let ident = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.ident) as String?, let seqNr = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.seqNr) as String?, let connectionId = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.connectionId) as String? else { return nil }
        let ld = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.ld) as String?
        self.init(ident: ident, seqNr: seqNr, ld: ld, connectionId: connectionId)
    }
    
    public override func encode(with aCoder: NSCoder) {
        aCoder.encode(ident, forKey: PropertyKey.ident)
        aCoder.encode(seqNr, forKey: PropertyKey.seqNr)
        if let ld = ld {
            aCoder.encode(ld, forKey: PropertyKey.ld)
        }
        aCoder.encode(connectionId, forKey: PropertyKey.connectionId)
    }
    
    struct PropertyKey {
        
        static let ident = "ident"
        static let seqNr = "seqNr"
        static let ld = "ld"
        static let connectionId = "connectionId"
        
    }
    
}

extension Data {
    func scanValue(start: Int, length: Int) -> [UInt8] {
        return [UInt8](self.subdata(in: start..<start+length))
    }
}
