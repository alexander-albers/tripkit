import Foundation
import os.log

public class VrsProvider: AbstractNetworkProvider {
    
    static let API_BASE = "http://android.vrsinfo.de/index.php"
    static let NAME_WITH_POSITION_PATTERNS: [NSRegularExpression] = [
        try! NSRegularExpression(pattern: "(.*) - (.*)"),
        try! NSRegularExpression(pattern: "(.*) Gleis (.*)"),
        try! NSRegularExpression(pattern: "(.*) \\(Bahnsteig ([^)]*)\\)"),
        try! NSRegularExpression(pattern: "(.*) \\(Bussteig ([^)]*)\\)"),
        try! NSRegularExpression(pattern: "(?:(.*) )?\\(Gleis ([^)]*)\\)"),
        try! NSRegularExpression(pattern: "(.*) \\(H\\.(\\d+).*\\)"),
        try! NSRegularExpression(pattern: "(.*) Bussteig (.*)")
    ]
    static let P_NRW_TARIF = try! NSRegularExpression(pattern: "([\\d]+,\\d\\d)")
    
    public init() {
        super.init(networkId: .VRS)
        
        styles = [
            // Stadtbahn Köln-Bonn
            "T1": LineStyle(backgroundColor: LineStyle.parseColor("#ed1c24"), foregroundColor: LineStyle.white),
            "T3": LineStyle(backgroundColor: LineStyle.parseColor("#f680c5"), foregroundColor: LineStyle.white),
            "T4": LineStyle(backgroundColor: LineStyle.parseColor("#f24dae"), foregroundColor: LineStyle.white),
            "T5": LineStyle(backgroundColor: LineStyle.parseColor("#9c8dce"), foregroundColor: LineStyle.white),
            "T7": LineStyle(backgroundColor: LineStyle.parseColor("#f57947"), foregroundColor: LineStyle.white),
            "T9": LineStyle(backgroundColor: LineStyle.parseColor("#f5777b"), foregroundColor: LineStyle.white),
            "T12": LineStyle(backgroundColor: LineStyle.parseColor("#80cc28"), foregroundColor: LineStyle.white),
            "T13": LineStyle(backgroundColor: LineStyle.parseColor("#9e7b65"), foregroundColor: LineStyle.white),
            "T15": LineStyle(backgroundColor: LineStyle.parseColor("#4dbd38"), foregroundColor: LineStyle.white),
            "T16": LineStyle(backgroundColor: LineStyle.parseColor("#33baab"), foregroundColor: LineStyle.white),
            "T18": LineStyle(backgroundColor: LineStyle.parseColor("#05a1e6"), foregroundColor: LineStyle.white),
            "T61": LineStyle(backgroundColor: LineStyle.parseColor("#80cc28"), foregroundColor: LineStyle.white),
            "T62": LineStyle(backgroundColor: LineStyle.parseColor("#4dbd38"), foregroundColor: LineStyle.white),
            "T63": LineStyle(backgroundColor: LineStyle.parseColor("#73d2f6"), foregroundColor: LineStyle.white),
            "T65": LineStyle(backgroundColor: LineStyle.parseColor("#b3db18"), foregroundColor: LineStyle.white),
            "T66": LineStyle(backgroundColor: LineStyle.parseColor("#ec008c"), foregroundColor: LineStyle.white),
            "T67": LineStyle(backgroundColor: LineStyle.parseColor("#f680c5"), foregroundColor: LineStyle.white),
            "T68": LineStyle(backgroundColor: LineStyle.parseColor("#ca93d0"), foregroundColor: LineStyle.white),
            
            // Busse Köln
            "BSB40": LineStyle(backgroundColor: LineStyle.parseColor("#FF0000"), foregroundColor: LineStyle.white),
            "B106": LineStyle(backgroundColor: LineStyle.parseColor("#0994dd"), foregroundColor: LineStyle.white),
            "B120": LineStyle(backgroundColor: LineStyle.parseColor("#24C6E8"), foregroundColor: LineStyle.white),
            "B121": LineStyle(backgroundColor: LineStyle.parseColor("#89E82D"), foregroundColor: LineStyle.white),
            "B122": LineStyle(backgroundColor: LineStyle.parseColor("#4D44FF"), foregroundColor: LineStyle.white),
            "B125": LineStyle(backgroundColor: LineStyle.parseColor("#FF9A2E"), foregroundColor: LineStyle.white),
            "B126": LineStyle(backgroundColor: LineStyle.parseColor("#FF8EE5"), foregroundColor: LineStyle.white),
            "B127": LineStyle(backgroundColor: LineStyle.parseColor("#D164A4"), foregroundColor: LineStyle.white),
            "B130": LineStyle(backgroundColor: LineStyle.parseColor("#5AC0E8"), foregroundColor: LineStyle.white),
            "B131": LineStyle(backgroundColor: LineStyle.parseColor("#8cd024"), foregroundColor: LineStyle.white),
            "B132": LineStyle(backgroundColor: LineStyle.parseColor("#E8840C"), foregroundColor: LineStyle.white),
            "B133": LineStyle(backgroundColor: LineStyle.parseColor("#FF9EEE"), foregroundColor: LineStyle.white),
            "B135": LineStyle(backgroundColor: LineStyle.parseColor("#f24caf"), foregroundColor: LineStyle.white),
            "B136": LineStyle(backgroundColor: LineStyle.parseColor("#C96C44"), foregroundColor: LineStyle.white),
            "B138": LineStyle(backgroundColor: LineStyle.parseColor("#ef269d"), foregroundColor: LineStyle.white),
            "B139": LineStyle(backgroundColor: LineStyle.parseColor("#D13D1E"), foregroundColor: LineStyle.white),
            "B140": LineStyle(backgroundColor: LineStyle.parseColor("#FFD239"), foregroundColor: LineStyle.white),
            "B141": LineStyle(backgroundColor: LineStyle.parseColor("#2CE8D0"), foregroundColor: LineStyle.white),
            "B142": LineStyle(backgroundColor: LineStyle.parseColor("#9E54FF"), foregroundColor: LineStyle.white),
            "B143": LineStyle(backgroundColor: LineStyle.parseColor("#82E827"), foregroundColor: LineStyle.white),
            "B144": LineStyle(backgroundColor: LineStyle.parseColor("#FF8930"), foregroundColor: LineStyle.white),
            "B145": LineStyle(backgroundColor: LineStyle.parseColor("#24C6E8"), foregroundColor: LineStyle.white),
            "B146": LineStyle(backgroundColor: LineStyle.parseColor("#F25006"), foregroundColor: LineStyle.white),
            "B147": LineStyle(backgroundColor: LineStyle.parseColor("#FF8EE5"), foregroundColor: LineStyle.white),
            "B149": LineStyle(backgroundColor: LineStyle.parseColor("#176fc1"), foregroundColor: LineStyle.white),
            "B150": LineStyle(backgroundColor: LineStyle.parseColor("#f68712"), foregroundColor: LineStyle.white),
            "B151": LineStyle(backgroundColor: LineStyle.parseColor("#ECB43A"), foregroundColor: LineStyle.white),
            "B152": LineStyle(backgroundColor: LineStyle.parseColor("#FFDE44"), foregroundColor: LineStyle.white),
            "B153": LineStyle(backgroundColor: LineStyle.parseColor("#C069FF"), foregroundColor: LineStyle.white),
            "B154": LineStyle(backgroundColor: LineStyle.parseColor("#E85D25"), foregroundColor: LineStyle.white),
            "B155": LineStyle(backgroundColor: LineStyle.parseColor("#0994dd"), foregroundColor: LineStyle.white),
            "B156": LineStyle(backgroundColor: LineStyle.parseColor("#4B69EC"), foregroundColor: LineStyle.white),
            "B157": LineStyle(backgroundColor: LineStyle.parseColor("#5CC3F9"), foregroundColor: LineStyle.white),
            "B158": LineStyle(backgroundColor: LineStyle.parseColor("#66c530"), foregroundColor: LineStyle.white),
            "B159": LineStyle(backgroundColor: LineStyle.parseColor("#FF00CC"), foregroundColor: LineStyle.white),
            "B160": LineStyle(backgroundColor: LineStyle.parseColor("#66c530"), foregroundColor: LineStyle.white),
            "B161": LineStyle(backgroundColor: LineStyle.parseColor("#33bef3"), foregroundColor: LineStyle.white),
            "B162": LineStyle(backgroundColor: LineStyle.parseColor("#f033a3"), foregroundColor: LineStyle.white),
            "B163": LineStyle(backgroundColor: LineStyle.parseColor("#00adef"), foregroundColor: LineStyle.white),
            "B163/550": LineStyle(backgroundColor: LineStyle.parseColor("#00adef"), foregroundColor: LineStyle.white),
            "B164": LineStyle(backgroundColor: LineStyle.parseColor("#885bb4"), foregroundColor: LineStyle.white),
            "B164/501": LineStyle(backgroundColor: LineStyle.parseColor("#885bb4"), foregroundColor: LineStyle.white),
            "B165": LineStyle(backgroundColor: LineStyle.parseColor("#7b7979"), foregroundColor: LineStyle.white),
            "B166": LineStyle(backgroundColor: LineStyle.parseColor("#7b7979"), foregroundColor: LineStyle.white),
            "B167": LineStyle(backgroundColor: LineStyle.parseColor("#7b7979"), foregroundColor: LineStyle.white),
            "B180": LineStyle(backgroundColor: LineStyle.parseColor("#918f90"), foregroundColor: LineStyle.white),
            "B181": LineStyle(backgroundColor: LineStyle.parseColor("#918f90"), foregroundColor: LineStyle.white),
            "B182": LineStyle(backgroundColor: LineStyle.parseColor("#918f90"), foregroundColor: LineStyle.white),
            "B183": LineStyle(backgroundColor: LineStyle.parseColor("#918f90"), foregroundColor: LineStyle.white),
            "B184": LineStyle(backgroundColor: LineStyle.parseColor("#918f90"), foregroundColor: LineStyle.white),
            "B185": LineStyle(backgroundColor: LineStyle.parseColor("#D3D2D2"), foregroundColor: LineStyle.white),
            "B186": LineStyle(backgroundColor: LineStyle.parseColor("#D3D2D2"), foregroundColor: LineStyle.white),
            "B187": LineStyle(backgroundColor: LineStyle.parseColor("#D3D2D2"), foregroundColor: LineStyle.white),
            "B188": LineStyle(backgroundColor: LineStyle.parseColor("#918f90"), foregroundColor: LineStyle.white),
            "B190": LineStyle(backgroundColor: LineStyle.parseColor("#4D44FF"), foregroundColor: LineStyle.white),
            "B191": LineStyle(backgroundColor: LineStyle.parseColor("#00a998"), foregroundColor: LineStyle.white),
            
            // Busse Bonn
            "B16": LineStyle(backgroundColor: LineStyle.parseColor("#33baab"), foregroundColor: LineStyle.white),
            "B18": LineStyle(backgroundColor: LineStyle.parseColor("#05a1e6"), foregroundColor: LineStyle.white),
            "B61": LineStyle(backgroundColor: LineStyle.parseColor("#80cc28"), foregroundColor: LineStyle.white),
            "B62": LineStyle(backgroundColor: LineStyle.parseColor("#4dbd38"), foregroundColor: LineStyle.white),
            "B63": LineStyle(backgroundColor: LineStyle.parseColor("#73d2f6"), foregroundColor: LineStyle.white),
            "B65": LineStyle(backgroundColor: LineStyle.parseColor("#b3db18"), foregroundColor: LineStyle.white),
            "B66": LineStyle(backgroundColor: LineStyle.parseColor("#ec008c"), foregroundColor: LineStyle.white),
            "B67": LineStyle(backgroundColor: LineStyle.parseColor("#f680c5"), foregroundColor: LineStyle.white),
            "B68": LineStyle(backgroundColor: LineStyle.parseColor("#ca93d0"), foregroundColor: LineStyle.white),
            "BSB55": LineStyle(backgroundColor: LineStyle.parseColor("#00919e"), foregroundColor: LineStyle.white),
            "BSB60": LineStyle(backgroundColor: LineStyle.parseColor("#8f9867"), foregroundColor: LineStyle.white),
            "BSB69": LineStyle(backgroundColor: LineStyle.parseColor("#db5f1f"), foregroundColor: LineStyle.white),
            "B529": LineStyle(backgroundColor: LineStyle.parseColor("#2e2383"), foregroundColor: LineStyle.white),
            "B537": LineStyle(backgroundColor: LineStyle.parseColor("#2e2383"), foregroundColor: LineStyle.white),
            "B541": LineStyle(backgroundColor: LineStyle.parseColor("#2e2383"), foregroundColor: LineStyle.white),
            "B551": LineStyle(backgroundColor: LineStyle.parseColor("#2e2383"), foregroundColor: LineStyle.white),
            "B600": LineStyle(backgroundColor: LineStyle.parseColor("#817db7"), foregroundColor: LineStyle.white),
            "B601": LineStyle(backgroundColor: LineStyle.parseColor("#831b82"), foregroundColor: LineStyle.white),
            "B602": LineStyle(backgroundColor: LineStyle.parseColor("#dd6ba6"), foregroundColor: LineStyle.white),
            "B603": LineStyle(backgroundColor: LineStyle.parseColor("#e6007d"), foregroundColor: LineStyle.white),
            "B604": LineStyle(backgroundColor: LineStyle.parseColor("#009f5d"), foregroundColor: LineStyle.white),
            "B605": LineStyle(backgroundColor: LineStyle.parseColor("#007b3b"), foregroundColor: LineStyle.white),
            "B606": LineStyle(backgroundColor: LineStyle.parseColor("#9cbf11"), foregroundColor: LineStyle.white),
            "B607": LineStyle(backgroundColor: LineStyle.parseColor("#60ad2a"), foregroundColor: LineStyle.white),
            "B608": LineStyle(backgroundColor: LineStyle.parseColor("#f8a600"), foregroundColor: LineStyle.white),
            "B609": LineStyle(backgroundColor: LineStyle.parseColor("#ef7100"), foregroundColor: LineStyle.white),
            "B610": LineStyle(backgroundColor: LineStyle.parseColor("#3ec1f1"), foregroundColor: LineStyle.white),
            "B611": LineStyle(backgroundColor: LineStyle.parseColor("#0099db"), foregroundColor: LineStyle.white),
            "B612": LineStyle(backgroundColor: LineStyle.parseColor("#ce9d53"), foregroundColor: LineStyle.white),
            "B613": LineStyle(backgroundColor: LineStyle.parseColor("#7b3600"), foregroundColor: LineStyle.white),
            "B614": LineStyle(backgroundColor: LineStyle.parseColor("#806839"), foregroundColor: LineStyle.white),
            "B615": LineStyle(backgroundColor: LineStyle.parseColor("#532700"), foregroundColor: LineStyle.white),
            "B630": LineStyle(backgroundColor: LineStyle.parseColor("#c41950"), foregroundColor: LineStyle.white),
            "B631": LineStyle(backgroundColor: LineStyle.parseColor("#9b1c44"), foregroundColor: LineStyle.white),
            "B633": LineStyle(backgroundColor: LineStyle.parseColor("#88cdc7"), foregroundColor: LineStyle.white),
            "B635": LineStyle(backgroundColor: LineStyle.parseColor("#cec800"), foregroundColor: LineStyle.white),
            "B636": LineStyle(backgroundColor: LineStyle.parseColor("#af0223"), foregroundColor: LineStyle.white),
            "B637": LineStyle(backgroundColor: LineStyle.parseColor("#e3572a"), foregroundColor: LineStyle.white),
            "B638": LineStyle(backgroundColor: LineStyle.parseColor("#af5836"), foregroundColor: LineStyle.white),
            "B640": LineStyle(backgroundColor: LineStyle.parseColor("#004f81"), foregroundColor: LineStyle.white),
            "BT650": LineStyle(backgroundColor: LineStyle.parseColor("#54baa2"), foregroundColor: LineStyle.white),
            "BT651": LineStyle(backgroundColor: LineStyle.parseColor("#005738"), foregroundColor: LineStyle.white),
            "BT680": LineStyle(backgroundColor: LineStyle.parseColor("#4e6578"), foregroundColor: LineStyle.white),
            "B800": LineStyle(backgroundColor: LineStyle.parseColor("#4e6578"), foregroundColor: LineStyle.white),
            "B812": LineStyle(backgroundColor: LineStyle.parseColor("#4e6578"), foregroundColor: LineStyle.white),
            "B843": LineStyle(backgroundColor: LineStyle.parseColor("#4e6578"), foregroundColor: LineStyle.white),
            "B845": LineStyle(backgroundColor: LineStyle.parseColor("#4e6578"), foregroundColor: LineStyle.white),
            "B852": LineStyle(backgroundColor: LineStyle.parseColor("#4e6578"), foregroundColor: LineStyle.white),
            "B855": LineStyle(backgroundColor: LineStyle.parseColor("#4e6578"), foregroundColor: LineStyle.white),
            "B856": LineStyle(backgroundColor: LineStyle.parseColor("#4e6578"), foregroundColor: LineStyle.white),
            "B857": LineStyle(backgroundColor: LineStyle.parseColor("#4e6578"), foregroundColor: LineStyle.white),
            
            // andere Busse
            "B250": LineStyle(backgroundColor: LineStyle.parseColor("#8FE84B"), foregroundColor: LineStyle.white),
            "B260": LineStyle(backgroundColor: LineStyle.parseColor("#FF8365"), foregroundColor: LineStyle.white),
            "B423": LineStyle(backgroundColor: LineStyle.parseColor("#D3D2D2"), foregroundColor: LineStyle.white),
            "B434": LineStyle(backgroundColor: LineStyle.parseColor("#14E80B"), foregroundColor: LineStyle.white),
            "B436": LineStyle(backgroundColor: LineStyle.parseColor("#BEEC49"), foregroundColor: LineStyle.white),
            "B481": LineStyle(backgroundColor: LineStyle.parseColor("#D3D2D2"), foregroundColor: LineStyle.white),
            "B504": LineStyle(backgroundColor: LineStyle.parseColor("#8cd024"), foregroundColor: LineStyle.white),
            "B505": LineStyle(backgroundColor: LineStyle.parseColor("#0994dd"), foregroundColor: LineStyle.white),
            "B885": LineStyle(backgroundColor: LineStyle.parseColor("#40bb6a"), foregroundColor: LineStyle.white),
            "B935": LineStyle(backgroundColor: LineStyle.parseColor("#bf7e71"), foregroundColor: LineStyle.white),
            "B961": LineStyle(backgroundColor: LineStyle.parseColor("#f140a9"), foregroundColor: LineStyle.white),
            "B962": LineStyle(backgroundColor: LineStyle.parseColor("#9c83c9"), foregroundColor: LineStyle.white),
            "B963": LineStyle(backgroundColor: LineStyle.parseColor("#f46c68"), foregroundColor: LineStyle.white),
            "B965": LineStyle(backgroundColor: LineStyle.parseColor("#FF0000"), foregroundColor: LineStyle.white),
            "B970": LineStyle(backgroundColor: LineStyle.parseColor("#f68712"), foregroundColor: LineStyle.white),
            "B980": LineStyle(backgroundColor: LineStyle.parseColor("#c38bcc"), foregroundColor: LineStyle.white),
            
            "BN": LineStyle(backgroundColor: LineStyle.parseColor("#000000"), foregroundColor: LineStyle.white),
            "BNE1": LineStyle(backgroundColor: LineStyle.parseColor("#993399"), foregroundColor: LineStyle.white), // default
            
            "S": LineStyle(backgroundColor: LineStyle.parseColor("#f18e00"), foregroundColor: LineStyle.white),
            "R": LineStyle(backgroundColor: LineStyle.parseColor("#009d81"), foregroundColor: LineStyle.white),
        ]
    }
    
    override public func queryNearbyLocations(location: Location, types: [LocationType]?, maxDistance: Int, maxLocations: Int, completion: @escaping (HttpRequest, NearbyLocationsResult) -> Void) -> AsyncRequest {
        let urlBuilder = UrlBuilder(path: VrsProvider.API_BASE, encoding: .utf8)
        
        urlBuilder.addParameter(key: "eID", value: "tx_vrsinfo_ass2_timetable")
        if let coord = location.coord {
            urlBuilder.addParameter(key: "r", value: String(format: "%.6f,%.6f", Double(coord.lat) / 1e6, Double(coord.lon) / 1e6))
        } else if location.type == .station, let id = location.id {
            urlBuilder.addParameter(key: "i", value: id)
        } else {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .invalidId)
            return AsyncRequest(task: nil)
        }
        urlBuilder.addParameter(key: "c", value: "1")
        if maxLocations > 0 {
            urlBuilder.addParameter(key: "s", value: "\(maxLocations)")
        }
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder)
        return HttpClient.get(httpRequest: httpRequest) { result in
            switch result {
            case .success((_, let data)):
                httpRequest.responseData = data
                do {
                    try self.queryNearbyLocationsByCoordinateParsing(request: httpRequest, location: location, types: types, maxDistance: maxDistance, maxLocations: maxLocations, completion: completion)
                } catch let err as ParseError {
                    os_log("nearbyLocations parse error: %{public}@", log: .requestLogger, type: .error, err.reason)
                    completion(httpRequest, .failure(err))
                } catch let err {
                    os_log("nearbyLocations handle response error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                    completion(httpRequest, .failure(err))
                }
            case .failure(let err):
                os_log("nearbyLocations network error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                completion(httpRequest, .failure(err))
            }
        }
    }
    
    override func queryNearbyLocationsByCoordinateParsing(request: HttpRequest, location: Location, types: [LocationType]?, maxDistance: Int, maxLocations: Int, completion: @escaping (HttpRequest, NearbyLocationsResult) -> Void) throws {
        let types = types ?? [.station]
        guard let json = try request.responseData?.toJson() as? [String: Any] else {
            throw ParseError(reason: "failed to get data")
        }
        if let error = (json["error"] as? String)?.trimmingCharacters(in: .whitespaces) {
            if error == "Leere Koordinate." || error == "Leere ASS-ID und leere Koordinate" {
                completion(request, .invalidId)
            } else if error == "ASS2-Server lieferte leere Antwort." {
                throw ParseError(reason: "empty response")
            } else {
                throw ParseError(reason: "unknown error \(error)")
            }
            return
        }
        
        var locations: [Location] = []
        for entry in json["timetable"] as? [Any] ?? [] {
            guard let entry = entry as? [String: Any], let stop = entry["stop"] as? [String: Any] else { throw ParseError(reason: "failed to parse timetable entry") }
            let location = try parseLocationAndPosition(from: stop).location
            let distance = stop["distance"] as? Int
            if let distance = distance, maxDistance > 0, distance > maxDistance {
                break
            }
            if types.contains(location.type) || types.contains(.any) {
                locations.append(location)
            }
        }
        
        completion(request, .success(locations: locations))
    }
    
    override public func queryDepartures(stationId: String, departures: Bool, time: Date?, maxDepartures: Int, equivs: Bool, completion: @escaping (HttpRequest, QueryDeparturesResult) -> Void) -> AsyncRequest {
        let urlBuilder = UrlBuilder(path: VrsProvider.API_BASE, encoding: .utf8)

        urlBuilder.addParameter(key: "eID", value: "tx_vrsinfo_ass2_timetable")
        urlBuilder.addParameter(key: "i", value: stationId)
        urlBuilder.addParameter(key: "c", value: maxDepartures)
        if let time = time {
            urlBuilder.addParameter(key: "t", value: formatDate(from: time))
        }
        // TODO: support for arrivals (possible?)
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder)
        return HttpClient.get(httpRequest: httpRequest) { result in
            switch result {
            case .success((_, let data)):
                httpRequest.responseData = data
                do {
                    try self.queryDeparturesParsing(request: httpRequest, stationId: stationId, departures: departures, time: time, maxDepartures: maxDepartures, equivs: equivs, completion: completion)
                } catch let err as ParseError {
                    os_log("queryDepartures parse error: %{public}@", log: .requestLogger, type: .error, err.reason)
                    completion(httpRequest, .failure(err))
                } catch let err {
                    os_log("queryDepartures handle response error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                    completion(httpRequest, .failure(err))
                }
            case .failure(let err):
                os_log("queryDepartures network error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                completion(httpRequest, .failure(err))
            }
        }
    }
    
    override func queryDeparturesParsing(request: HttpRequest, stationId: String, departures: Bool, time: Date?, maxDepartures: Int, equivs: Bool, completion: @escaping (HttpRequest, QueryDeparturesResult) -> Void) throws {
        guard let json = try request.responseData?.toJson() as? [String: Any] else {
            throw ParseError(reason: "failed to get data")
        }
        if let error = (json["error"] as? String)?.trimmingCharacters(in: .whitespaces) {
            if error == "ASS2-Server lieferte leere Antwort." {
                throw ParseError(reason: "empty response")
            } else if error == "Leere ASS-ID und leere Koordinate" {
                completion(request, .invalidStation)
            } else if error == "Keine Abfahrten gefunden." {
                completion(request, .invalidStation)
            } else {
                throw ParseError(reason: "unknown error \(error)")
            }
            return
        }
        guard let timeTable = json["timetable"] as? [Any] else { throw ParseError(reason: "failed to parse timetable") }
        if timeTable.count == 0 {
            completion(request, .success(departures: []))
            return
        }
        var result: [StationDepartures] = []
        for station in timeTable {
            guard let station = station as? [String: Any], let stop = station["stop"] as? [String: Any], let events = station["events"] as? [Any] else { throw ParseError(reason: "failed to parse station") }
            let location = try parseLocationAndPosition(from: stop).location
            var departures: [Departure] = []
            var lines: [ServingLine] = []
            for event in events {
                guard let event = event as? [String: Any] else { throw ParseError(reason: "failed to parse event") }
                var plannedTime: Date? = nil
                var predictedTime: Date? = nil
                if let departureScheduled = event["departureScheduled"] as? String {
                    plannedTime = parseDateTime(from: departureScheduled)
                    if let departure = event["departure"] as? String {
                        predictedTime = parseDateTime(from: departure)
                    }
                } else if let departure = event["departure"] as? String {
                    plannedTime = parseDateTime(from: departure)
                }
                
                guard let lineObject = event["line"] as? [String: Any] else { throw ParseError(reason: "failed to parse line") }
                let line = try parseLine(from: lineObject)
                var position: String? = nil
                if let post = event["post"] as? [String: Any], let name = post["name"] as? String {
                    for pattern in VrsProvider.NAME_WITH_POSITION_PATTERNS {
                        if let match = name.match(pattern: pattern), let group = match[1] {
                            position = group
                            break
                        }
                    }
                }
                
                let destination = Location(type: .station, id: nil, coord: nil, place: nil, name: lineObject["direction"] as? String)
                let lineDestination = ServingLine(line: line, destination: destination)
                if !lines.contains(lineDestination) {
                    lines.append(lineDestination)
                }
                let journeyContext: VrsJourneyContext?
                if let destination = destination {
                    journeyContext = VrsJourneyContext(from: location, to: destination, time: predictedTime ?? plannedTime ?? Date(), plannedTime: plannedTime ?? predictedTime ?? Date(), product: line.product, line: line)
                } else {
                    journeyContext = nil
                }
                let departure = Departure(plannedTime: plannedTime, predictedTime: predictedTime, line: line, position: position, plannedPosition: position, destination: destination, journeyContext: journeyContext)
                departures.append(departure)
            }
            
            result.append(StationDepartures(stopLocation: location, departures: departures, lines: lines))
        }
        completion(request, .success(departures: result))
        //resolveLines(result: result, remainingIds: result.departures, completion: completion)
    }
    
    func resolveLines(request: HttpRequest, result: QueryDeparturesResult, remainingIds: [StationDepartures], completion: @escaping (HttpRequest, QueryDeparturesResult) -> Void) {
        var remainingIds = remainingIds
        if !remainingIds.isEmpty {
            let first = remainingIds.removeFirst()
            if let id = first.stopLocation.id {
                queryLines(for: id, completion: { (servingLines) in
                    for servingLine in servingLines {
                        if !first.lines.contains(servingLine) {
                            first.lines.append(servingLine)
                        }
                    }
                    self.resolveLines(request: request, result: result, remainingIds: remainingIds, completion: completion)
                })
            } else {
                resolveLines(request: request, result: result, remainingIds: remainingIds, completion: completion)
            }
        } else {
            completion(request, result)
        }
    }
    
    func queryLines(for stationId: String, completion: @escaping ([ServingLine]) -> Void) {
        let urlBuilder = UrlBuilder(path: VrsProvider.API_BASE, encoding: .utf8)

        urlBuilder.addParameter(key: "eID", value: "tx_vrsinfo_his_info")
        urlBuilder.addParameter(key: "i", value: stationId)
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder)
        let _ = HttpClient.get(httpRequest: httpRequest) { result in
            switch result {
            case .success((_, let data)):
                do {
                    try self.handleQueryLinesResponse(response: data, completion: completion)
                } catch let err as ParseError {
                    os_log("resolveLines parse error: %{public}@", log: .requestLogger, type: .error, err.reason)
                    completion([])
                } catch let err {
                    os_log("resolveLines handle response error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                    completion([])
                }
            case .failure(let err):
                os_log("resolveLines network error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                completion([])
            }
        }
    }
    
    func handleQueryLinesResponse(response: Data?, completion: @escaping ([ServingLine]) -> Void) throws {
        guard let json = try response?.toJson() as? [String: Any] else {
            throw ParseError(reason: "failed to parse json head")
        }
        
        var lineDestinations: [ServingLine] = []
        if let his = json["his"] as? [String: Any] {
            for line in his["lines"] as? [Any] ?? [] {
                guard let line = line as? [String: Any], let number = line["number"] as? String else { throw ParseError(reason: "failed to parse line") }
                let lineNumber = processLineNumber(number: number)
                let product = self.product(from: lineNumber)
                
                if let postings = line["postings"] as? [Any] {
                    for posting in postings {
                        guard let posting = posting as? [String: Any] else { throw ParseError(reason: "failed to parse posting") }
                        lineDestinations.append(ServingLine(line: Line(id: nil, network: "VRS", product: product, label: number, name: nil, style: lineStyle(network: "vrs", product: product, label: number), attr: nil, message: nil), destination: Location(type: .station, id: nil, coord: nil, place: nil, name: posting["direction"] as? String)))
                    }
                } else {
                    lineDestinations.append(ServingLine(line: Line(id: nil, network: "VRS", product: product, label: number, name: nil, style: lineStyle(network: "vrs", product: product, label: number), attr: nil, message: nil), destination: nil))
                }
            }
        }
        
        completion(lineDestinations)
    }
    
    override public func suggestLocations(constraint: String, types: [LocationType]?, maxLocations: Int, completion: @escaping (HttpRequest, SuggestLocationsResult) -> Void) -> AsyncRequest {
        let urlBuilder = UrlBuilder(path: VrsProvider.API_BASE, encoding: .utf8)

        urlBuilder.addParameter(key: "eID", value: "tx_vrsinfo_ass2_objects")
        urlBuilder.addParameter(key: "sc", value: maxLocations > 0 ? maxLocations : 10) // station count
        urlBuilder.addParameter(key: "ac", value: "5") // address count
        urlBuilder.addParameter(key: "pc", value: "5") // points of interest count
        urlBuilder.addParameter(key: "t", value: "sap")// (stops and/or addresses and/or pois)
        urlBuilder.addParameter(key: "q", value: constraint) // points of interest count
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder)
        return HttpClient.get(httpRequest: httpRequest) { result in
            switch result {
            case .success((_, let data)):
                httpRequest.responseData = data
                do {
                    try self.suggestLocationsParsing(request: httpRequest, constraint: constraint, types: types, maxLocations: maxLocations, completion: completion)
                } catch let err as ParseError {
                    os_log("suggestLocations parse error: %{public}@", log: .requestLogger, type: .error, err.reason)
                    completion(httpRequest, .failure(err))
                } catch let err {
                    os_log("suggestLocations handle response error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                    completion(httpRequest, .failure(err))
                }
            case .failure(let err):
                os_log("suggestLocations network error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                completion(httpRequest, .failure(err))
            }
        }
    }
    
    override func suggestLocationsParsing(request: HttpRequest, constraint: String, types: [LocationType]?, maxLocations: Int, completion: @escaping (HttpRequest, SuggestLocationsResult) -> Void) throws {
        guard let json = try request.responseData?.toJson() as? [String: Any] else {
            throw ParseError(reason: "failed to get data")
        }
        if let error = (json["error"] as? String)?.trimmingCharacters(in: .whitespaces) {
            if error == "ASS2-Server lieferte leere Antwort." {
                throw ParseError(reason: "empty response")
            } else if error == "Leere Suche" {
                completion(request, .success(locations: []))
            } else {
                throw ParseError(reason: "unknown error \(error)")
            }
            return
        }
        
        var locations: [SuggestedLocation] = []
        
        for (index, stop) in (json["stops"] as? [Any] ?? []).enumerated() {
            guard let stop = stop as? [String: Any] else { throw ParseError(reason: "failed to parse stop") }
            let location = try parseLocationAndPosition(from: stop).location
            locations.append(SuggestedLocation(location: location, priority: 20 - index))
        }
        
        for (index, address) in (json["addresses"] as? [Any] ?? []).enumerated() {
            guard let address = address as? [String: Any] else { throw ParseError(reason: "failed to parse address") }
            let location = try parseLocationAndPosition(from: address).location
            locations.append(SuggestedLocation(location: location, priority: 10 - index))
        }
        
        for (index, poi) in (json["pois"] as? [Any] ?? []).enumerated() {
            guard let poi = poi as? [String: Any] else { throw ParseError(reason: "failed to parse poi") }
            let location = try parseLocationAndPosition(from: poi).location
            locations.append(SuggestedLocation(location: location, priority: 5 - index))
        }
        
        completion(request, .success(locations: locations))
    }
    
    override public func queryTrips(from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        return queryTrips(from: from, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions, ambiguousFrom: nil, ambiguousVia: nil, ambiguousTo: nil, context: nil, completion: completion)
    }
    
    private func queryTrips(from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions, ambiguousFrom: [Location]?, ambiguousVia: [Location]?, ambiguousTo: [Location]?, context: Context?, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        let fromString = generateLocation(location: from)
        if fromString == nil, ambiguousFrom == nil {
            return suggestLocations(constraint: from.name ?? "", types: [.station], maxLocations: 1) { (request, result) in
                switch result {
                case .success(let locations):
                    if let first = locations.first?.location, locations.count == 1 {
                        // TODO: make request cancelable (AsyncTask.setTask())
                        let _ = self.queryTrips(from: first, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions, ambiguousFrom: ambiguousFrom, ambiguousVia: ambiguousVia, ambiguousTo: ambiguousTo, context: context, completion: completion)
                    } else {
                        let _ = self.queryTrips(from: from, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions, ambiguousFrom: locations.map({$0.location}), ambiguousVia: ambiguousVia, ambiguousTo: ambiguousTo, context: context, completion: completion)
                    }
                case .failure(_):
                    completion(request, .unknownFrom)
                }
            }
        }
        let viaString: String? = generateLocation(location: via)
        if let via = via, viaString == nil, ambiguousVia == nil {
            return suggestLocations(constraint: via.name ?? "", types: [.station], maxLocations: 1) { (request, result) in
                switch result {
                case .success(let locations):
                    if let first = locations.first?.location, locations.count == 1 {
                        let _ = self.queryTrips(from: from, via: first, to: to, date: date, departure: departure, tripOptions: tripOptions, ambiguousFrom: ambiguousFrom, ambiguousVia: ambiguousVia, ambiguousTo: ambiguousTo, context: context, completion: completion)
                    } else {
                        let _ = self.queryTrips(from: from, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions, ambiguousFrom: ambiguousFrom, ambiguousVia: locations.map({$0.location}), ambiguousTo: ambiguousTo, context: context, completion: completion)
                    }
                case .failure(_):
                    completion(request, .unknownVia)
                }
            }
        }
        let toString = generateLocation(location: to)
        if toString == nil, ambiguousTo == nil {
            return suggestLocations(constraint: to.name ?? "", types: [.station], maxLocations: 1) { (request, result) in
                switch result {
                case .success(let locations):
                    if let first = locations.first?.location, locations.count == 1 {
                        let _ = self.queryTrips(from: from, via: via, to: first, date: date, departure: departure, tripOptions: tripOptions, ambiguousFrom: ambiguousFrom, ambiguousVia: ambiguousVia, ambiguousTo: ambiguousTo, context: context, completion: completion)
                    } else {
                        let _ = self.queryTrips(from: from, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions, ambiguousFrom: ambiguousFrom, ambiguousVia: ambiguousVia, ambiguousTo: locations.map({$0.location}), context: context, completion: completion)
                    }
                case .failure(_):
                    completion(request, .unknownTo)
                }
            }
        }
        
        // TODO: implement the same for hafasclientinterface
        if ambiguousFrom?.count ?? 0 != 0 || ambiguousVia?.count ?? 0 != 0 || ambiguousTo?.count ?? 0 != 0 {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .ambiguous(ambiguousFrom: ambiguousFrom ?? [], ambiguousVia: ambiguousVia ?? [], ambiguousTo: ambiguousTo ?? []))
            return AsyncRequest(task: nil)
        }
    
        if fromString == nil {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .unknownFrom)
            return AsyncRequest(task: nil)
        }
        if via != nil && viaString == nil {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .unknownVia)
            return AsyncRequest(task: nil)
        }
        if toString == nil {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .unknownTo)
            return AsyncRequest(task: nil)
        }
        
        return doQueryTrips(from: from, via: via, to: to, fromString: fromString!, viaString: viaString, toString: toString!, date: date, departure: departure, tripOptions: tripOptions, context: context, completion: completion)
    }
    
    private func doQueryTrips(from: Location, via: Location?, to: Location, fromString: String, viaString: String?, toString: String, date: Date, departure: Bool, tripOptions: TripOptions, context: Context?, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        let urlBuilder = UrlBuilder(path: VrsProvider.API_BASE, encoding: .utf8)

        urlBuilder.addParameter(key: "eID", value: "tx_vrsinfo_ass2_router")
        urlBuilder.addParameter(key: "f", value: fromString)
        urlBuilder.addParameter(key: "t", value: toString)
        if let viaString = viaString {
            urlBuilder.addParameter(key: "v", value: viaString)
        }
        urlBuilder.addParameter(key: departure ? "d" : "a", value: formatDate(from: date))
        urlBuilder.addParameter(key: "s", value: "t")
        if tripOptions.products ?? [] != Product.allCases, let productString = generateProducts(from: tripOptions.products) {
            urlBuilder.addParameter(key: "p", value: productString)
        }
        urlBuilder.addParameter(key: "o", value: "vp")
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder)
        return HttpClient.get(httpRequest: httpRequest) { result in
            switch result {
            case .success((_, let data)):
                httpRequest.responseData = data
                do {
                    try self.queryTripsParsing(request: httpRequest, from: from, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions, previousContext: nil, later: false, completion: completion)
                } catch is SessionExpiredError {
                    completion(httpRequest, .sessionExpired)
                } catch let err as ParseError {
                    os_log("queryTrips parse error: %{public}@", log: .requestLogger, type: .error, err.reason)
                    completion(httpRequest, .failure(err))
                } catch let err {
                    os_log("queryTrips handle response error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                    completion(httpRequest, .failure(err))
                }
            case .failure(let err):
                os_log("queryTrips network error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                completion(httpRequest, .failure(err))
            }
        }
    }
    
    override func queryTripsParsing(request: HttpRequest, from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions, previousContext: QueryTripsContext?, later: Bool, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) throws {
        guard let json = try request.responseData?.toJson() as? [String: Any] else {
            throw ParseError(reason: "failed to get data")
        }
        if let error = (json["error"] as? String)?.trimmingCharacters(in: .whitespaces) {
            if error == "ASS2-Server lieferte leere Antwort." {
                throw ParseError(reason: "empty response")
            } else if error == "Zeitüberschreitung bei der Verbindung zum ASS2-Server" {
                throw ParseError(reason: "timeout")
            } else if error == "Server Error" {
                throw ParseError(reason: "server error")
            } else if error == "Keine Verbindungen gefunden." {
                completion(request, .noTrips)
            } else if error.hasPrefix("Keine Verbindung gefunden.") || error.hasPrefix("Keine Verbindungen gefunden.") {
                completion(request, .noTrips)
            } else if error == "Origin invalid." {
                completion(request, .unknownFrom)
            } else if error == "Via invalid." {
                completion(request, .unknownVia)
            } else if error == "Destination invalid." {
                completion(request, .unknownTo)
            } else if error == "Fehlerhafter Start" {
                completion(request, .unknownFrom)
            } else if error == "Fehlerhaftes Ziel" {
                completion(request, .unknownTo)
            } else if error == "Produkt ungültig." {
                completion(request, .noTrips)
            } else if error == "Keine Route." {
                completion(request, .noTrips)
            } else {
                throw ParseError(reason: "unknown error \(error)")
            }
            return
        }
        
        guard let routes = json["routes"] as? [Any] else {
            completion(request, .noTrips)
            return
        }
        
        let context = Context()
        context.arrival(date: (previousContext as? Context)?.firstArrival)
        context.departure(date: (previousContext as? Context)?.lastDeparture)
        var trips: [Trip] = []
        for route in routes {
            guard let route = route as? [String: Any], let segments = route["segments"] as? [Any] else { throw ParseError(reason: "failed to parse route") }
            
            var legs: [Leg] = []
            var tripOrigin: Location? = nil
            var tripDestination: Location? = nil
            for (index, segment) in segments.enumerated() {
                guard let segment = segment as? [String: Any], let type = segment["type"] as? String else { throw ParseError(reason: "failed to parse segment") }
                
                guard let origin = segment["origin"] as? [String: Any] else { throw ParseError(reason: "failed to parse segment origin") }
                let segmentOriginLocationWithPosition = try parseLocationAndPosition(from: origin)
                var segmentOrigin = segmentOriginLocationWithPosition.location
                let segmentOriginPosition = segmentOriginLocationWithPosition.position
                if index == 0 {
                    if from.type == .address {
                        segmentOrigin = from
                    }
                    tripOrigin = segmentOrigin
                }
                guard let destination = segment["destination"] as? [String: Any] else { throw ParseError(reason: "failed to parse segment destination") }
                let segmentDestinationLocationWithPosition = try parseLocationAndPosition(from: destination)
                var segmentDestination = segmentDestinationLocationWithPosition.location
                let segmentDestinationPosition = segmentDestinationLocationWithPosition.position
                if index == segments.count - 1 {
                    if to.type == .address {
                        segmentDestination = to
                    }
                    tripDestination = segmentDestination
                }
                
                var intermediateStops: [Stop] = []
                for via in segment["vias"] as? [Any] ?? [] {
                    guard let via = via as? [String: Any] else { throw ParseError(reason: "failed to parse via") }
                    let viaLocationWithPosition = try parseLocationAndPosition(from: via)
                    let viaLocation = viaLocationWithPosition.location
                    let viaPosition = viaLocationWithPosition.position
                    
                    var plannedArrival: Date? = nil
                    var predictedArrival: Date? = nil
                    if let arrivalScheduled = via["arrivalScheduled"] as? String {
                        plannedArrival = parseDateTime(from: arrivalScheduled)
                        if let arrival = via["arrival"] as? String {
                            predictedArrival = parseDateTime(from: arrival)
                        }
                    } else if let arrival = via["arrival"] as? String {
                        plannedArrival = parseDateTime(from: arrival)
                    }
                    let stop = Stop(location: viaLocation, plannedArrivalTime: plannedArrival, predictedArrivalTime: predictedArrival, plannedArrivalPlatform: viaPosition, predictedArrivalPlatform: nil, arrivalCancelled: false, plannedDepartureTime: plannedArrival, predictedDepartureTime: predictedArrival, plannedDeparturePlatform: viaPosition, predictedDeparturePlatform: nil, departureCancelled: false)
                    intermediateStops.append(stop)
                }
                var departurePlanned: Date? = nil
                var departurePredicted: Date? = nil
                if let departureScheduled = segment["departureScheduled"] as? String {
                    departurePlanned = parseDateTime(from: departureScheduled)
                    if let departure = segment["departure"] as? String {
                        departurePredicted = parseDateTime(from: departure)
                    }
                    if index == 0 {
                        context.departure(date: departurePredicted ?? departurePlanned)
                    }
                } else if let departure = segment["departure"] as? String {
                    departurePlanned = parseDateTime(from: departure)
                    if index == 0 {
                        context.departure(date: departurePlanned)
                    }
                }
                
                var arrivalPlanned: Date? = nil
                var arrivalPredicted: Date? = nil
                if let arrivalScheduled = segment["arrivalScheduled"] as? String {
                    arrivalPlanned = parseDateTime(from: arrivalScheduled)
                    if let arrival = segment["arrival"] as? String {
                        arrivalPredicted = parseDateTime(from: arrival)
                    }
                    if index == segments.count - 1 {
                        context.arrival(date: arrivalPredicted ?? arrivalPlanned)
                    }
                } else if let arrival = segment["arrival"] as? String {
                    arrivalPlanned = parseDateTime(from: arrival)
                    if index == segments.count - 1 {
                        context.arrival(date: arrivalPlanned)
                    }
                }
                
                let travelTime = segment["traveltime"] as? Int ?? 0
                let distance = segment["distance"] as? Int ?? 0
                var line: Line? = nil
                var direction: String? = nil
                if let lineObject = segment["line"] as? [String: Any] {
                    line = try parseLine(from: lineObject)
                    direction = lineObject["direction"] as? String
                }
                var message = ""
                for info in segment["info"] as? [Any] ?? [] {
                    guard let info = info as? [String: Any], let text = info["text"] as? String else { throw ParseError(reason: "failed to parse segment info") }
                    if message.length > 0 {
                        message += ", "
                    }
                    message += text
                }
                
                var points: [LocationPoint] = []
                if let coord = segmentOrigin.coord {
                    points.append(coord)
                }
                if let polygon = segment["polygon"] as? String, polygon != "" {
                    parsePolygon(polygon: polygon, points: &points)
                } else {
                    for intermediateStop in intermediateStops {
                        guard let coord = intermediateStop.location.coord else { continue }
                        points.append(coord)
                    }
                }
                if let coord = segmentDestination.coord {
                    points.append(coord)
                }
                
                if type == "walk" {
                    if departurePlanned == nil {
                        departurePlanned = legs.last?.getArrivalTime()
                    }
                    if arrivalPlanned == nil {
                        arrivalPlanned = departurePlanned?.addingTimeInterval(Double(travelTime))
                    }
                    let addTime: TimeInterval = !legs.isEmpty ? max(0, -departurePlanned!.timeIntervalSince(legs.last!.getMaxTime())) : 0
                    legs.append(IndividualLeg(type: .WALK, departureTime: departurePlanned!.addingTimeInterval(addTime), departure: segmentOrigin, arrival: segmentDestination, arrivalTime: arrivalPlanned!.addingTimeInterval(addTime), distance: distance, path: points))
                } else if type == "publicTransport" {
                    let directionLoc: Location?
                    if let direction = direction {
                        directionLoc = Location(type: .station, id: nil, coord: nil, place: nil, name: direction)
                    } else {
                        directionLoc = nil
                    }
                    let departureStop = Stop(location: segmentOrigin, plannedArrivalTime: nil, predictedArrivalTime: nil, plannedArrivalPlatform: nil, predictedArrivalPlatform: nil, arrivalCancelled: false, plannedDepartureTime: departurePlanned, predictedDepartureTime: departurePredicted, plannedDeparturePlatform: segmentOriginPosition, predictedDeparturePlatform: nil, departureCancelled: false)
                    let arrivalStop = Stop(location: segmentDestination, plannedArrivalTime: arrivalPlanned, predictedArrivalTime: arrivalPredicted, plannedArrivalPlatform: segmentDestinationPosition, predictedArrivalPlatform: nil, arrivalCancelled: false, plannedDepartureTime: nil, predictedDepartureTime: nil, plannedDeparturePlatform: nil, predictedDeparturePlatform: nil, departureCancelled: false)
                    let journeyContext: VrsJourneyContext?
                    if let destination = directionLoc {
                        journeyContext = VrsJourneyContext(from: departureStop.location, to: destination, time: departureStop.predictedDepartureTime ?? departureStop.plannedDepartureTime ?? Date(), plannedTime: departureStop.plannedDepartureTime ?? departureStop.predictedDepartureTime ?? Date(), product: line?.product, line: line)
                    } else {
                        journeyContext = nil
                    }
                    legs.append(PublicLeg(line: line!, destination: directionLoc, departureStop: departureStop, arrivalStop: arrivalStop, intermediateStops: intermediateStops, message: message.emptyToNil, path: points, journeyContext: journeyContext))
                } else {
                    throw ParseError(reason: "illegal segment type \(type)")
                }
            }
            let fares = parseFare(costs: route["costs"] as? [String: Any])
            
            if let tripOrigin = tripOrigin, let tripDestination = tripDestination {
                trips.append(Trip(id: "", from: tripOrigin, to: tripDestination, legs: legs, fares: fares))
            } else {
                throw ParseError(reason: "failed to parse trip origin/destination")
            }
        }
        
        context.from = from
        context.via = via
        context.to = to
        context.products = tripOptions.products
        if trips.count == 1 {
            if departure {
                context.queryLater = false
            } else {
                context.queryEarlier = false
            }
        }
        
        completion(request, .success(context: context, from: from, via: via, to: to, trips: trips, messages: []))
    }
    
    override public func queryMoreTrips(context: QueryTripsContext, later: Bool, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        guard let context = context as? Context else {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .sessionExpired)
            return AsyncRequest(task: nil)
        }
        return queryTrips(from: context.from, via: context.via, to: context.to, date: (later ? context.lastDeparture : context.firstArrival) ?? Date(), departure: later, tripOptions: TripOptions(products: context.products), ambiguousFrom: nil, ambiguousVia: nil, ambiguousTo: nil, context: context, completion: completion)
    }
    
    public override func refreshTrip(context: RefreshTripContext, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        completion(HttpRequest(urlBuilder: UrlBuilder()), .sessionExpired)
        return AsyncRequest(task: nil)
    }
    
    override func refreshTripParsing(request: HttpRequest, context: RefreshTripContext, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) throws {
        // does not apply
    }
    
    public override func queryJourneyDetail(context: QueryJourneyDetailContext, completion: @escaping (HttpRequest, QueryJourneyDetailResult) -> Void) -> AsyncRequest {
        guard let context = context as? VrsJourneyContext else {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .invalidId)
            return AsyncRequest(task: nil)
        }
        return queryTrips(from: context.from, via: nil, to: context.to, date: context.time, departure: true, products: context.product != nil ? [context.product!] : Product.allCases, optimize: nil, walkSpeed: nil, accessibility: nil, options: nil, completion: { (request, result) in
            switch result {
            case .success(_, _, _, _, let trips, _):
                let trip = trips.first(where: { (trip) -> Bool in
                    guard trip.legs.filter({$0 is PublicLeg}).count == 1 else { return false }
                    guard let leg = trip.legs.filter({$0 is PublicLeg}).first as? PublicLeg else { return false }
                    guard leg.departureStop.plannedDepartureTime == context.plannedTime || leg.departureStop.predictedDepartureTime == context.time else { return false }
                    guard leg.line == context.line else { return false }
                    return true
                })
                let leg = trip?.legs.first(where: {$0 is PublicLeg})
                if let trip = trip, let leg = leg as? PublicLeg {
                    completion(request, .success(trip: trip, leg: leg))
                } else {
                    completion(request, .invalidId)
                }
            case .ambiguous(_, _, let ambiguousTo):
                if let destination = ambiguousTo.first {
                    _ = self.queryTrips(from: context.from, via: nil, to: destination, date: context.time, departure: true, products: context.product != nil ? [context.product!] : Product.allCases, optimize: nil, walkSpeed: nil, accessibility: nil, options: nil, completion: { (request2, result2) in
                        switch result2 {
                        case .success(_, _, _, _, let trips, _):
                            let trip = trips.first(where: { (trip) -> Bool in
                                guard trip.legs.filter({$0 is PublicLeg}).count == 1 else { return false }
                                guard let leg = trip.legs.filter({$0 is PublicLeg}).first as? PublicLeg else { return false }
                                guard leg.departureStop.plannedDepartureTime == context.plannedTime || leg.departureStop.predictedDepartureTime == context.time else { return false }
                                guard leg.line == context.line else { return false }
                                return true
                            })
                            let leg = trip?.legs.first(where: {$0 is PublicLeg})
                            if let trip = trip, let leg = leg as? PublicLeg {
                                completion(request2, .success(trip: trip, leg: leg))
                            } else {
                                completion(request2, .invalidId)
                            }
                        default:
                            completion(request2, .invalidId)
                        }
                    })
                } else {
                    completion(request, .invalidId)
                }
            case .failure(let err):
                completion(request, .failure(err))
            default:
                completion(request, .invalidId)
            }
        })
    }
    
    override func queryJourneyDetailParsing(request: HttpRequest, context: QueryJourneyDetailContext, completion: @escaping (HttpRequest, QueryJourneyDetailResult) -> Void) throws {
        // does not apply
    }
    
    override func lineStyle(network: String?, product: Product?, label: String?) -> LineStyle {
        if product == .bus, let label = label, label.hasPrefix("SB") {
            return super.lineStyle(network: network, product: product, label: "SB")
        } else {
            return super.lineStyle(network: network, product: product, label: label)
        }
    }
    
    func generateLocation(location: Location?) -> String? {
        guard let location = location else { return nil }
        if location.id != nil {
            return location.id
        } else if let coord = location.coord {
            return String(format: "%f,%f", Double(coord.lat) / 1e6, Double(coord.lon) / 1e6)
        } else {
            return nil
        }
    }
    
    func formatDate(from date: Date) -> String {
        let dateFormatter = ISO8601DateFormatter()
        return dateFormatter.string(from: date)
    }
    
    func generateProducts(from products: [Product]?) -> String? {
        guard let products = products else { return nil }
        var result = ""
        for product in products {
            guard let productStr = generateProduct(from: product) else { continue }
            if result.length > 0 {
                result += ","
            }
            result += productStr
        }
        return result
    }
    
    func generateProduct(from product: Product) -> String? {
        switch product {
        case .bus:
            return "Bus,CommunityBus"
        case .cablecar:
            return nil
        case .ferry:
            return "Boat"
        case .highSpeedTrain:
            return "LongDistanceTrains"
        case .onDemand:
            return "OnDemandServices"
        case .regionalTrain:
            return "RegionalTrains"
        case .suburbanTrain:
            return "SuburbanTrains"
        case .subway:
            return "LightRail,Underground"
        case .tram:
            return "LightRail"
        }
    }
    
    func product(from number: String) -> Product {
        if number.hasPrefix("I") || number.hasPrefix("E") {
            return .highSpeedTrain
        } else if number.hasPrefix("R") || number.hasPrefix("MRB") || number.hasPrefix("DPN") {
            return .regionalTrain
        } else if number.hasPrefix("S") && !number.hasPrefix("SB") && !number.hasPrefix("SEV") {
            return .suburbanTrain
        } else if number.hasPrefix("U") {
            return .subway
        } else if number.length <= 2 && !number.hasPrefix("N") {
            return .tram
        } else {
            return .bus
        }
    }
    
    func parseDateTime(from dateTimeString: String) -> Date? {
        let dateFormat = ISO8601DateFormatter()
        guard let date = dateFormat.date(from: dateTimeString) else { return nil }
        let timeInterval = floor(date.timeIntervalSinceReferenceDate / 60.0) * 60.0
        return Date(timeIntervalSinceReferenceDate: timeInterval)
    }
    
    func parsePolygon(polygon: String, points: inout [LocationPoint]) {
        for point in polygon.components(separatedBy: " ") {
            let latlon = point.components(separatedBy: ",")
            let lat = Int(round((Double(latlon[0]) ?? 0) * 1e6))
            let lon = Int(round((Double(latlon[1]) ?? 0) * 1e6))
            points.append(LocationPoint(lat: lat, lon: lon))
        }
    }
    
    func parseLine(from line: [String: Any]) throws -> Line {
        guard let number = line["number"] as? String, let product = line["product"] as? String else { throw ParseError(reason: "failed to parse line") }
        let lineNumber = processLineNumber(number: number)
        let lineProduct = try parseProduct(product: product, number: lineNumber)
        let style = lineStyle(network: "vrs", product: lineProduct, label: lineNumber)
        return Line(id: nil, network: "VRS", product: lineProduct, label: lineNumber, name: nil, style: style, attr: nil, message: nil)
    }
    
    func processLineNumber(number: String) -> String {
        if number.hasPrefix("AST ") || number.hasPrefix("VRM ") || number.hasPrefix("VRR ") {
            return number.substring(from: 4)
        } else if number.hasPrefix("AST") || number.hasPrefix("VRM") || number.hasPrefix("VRR") {
            return number.substring(from: 3)
        } else if number.hasPrefix("TaxiBus ") {
            return number.substring(from: 8)
        } else if number.hasPrefix("TaxiBus") {
            return number.substring(from: 7)
        } else if number == "Schienen-Ersatz-Verkehr (SEV)" {
            return "SEV"
        } else {
            return number
        }
    }
    
    func parseProduct(product: String, number: String) throws -> Product? {
        switch product {
        case "LongDistanceTrains":
            return .highSpeedTrain
        case "RegionalTrains":
            return .regionalTrain
        case "SuburbanTrains":
            return .suburbanTrain
        case "Underground", 
             "LightRail" where number.hasPrefix("U"):
            return .subway
        case "LightRail":
            // note that also the Skytrain (Flughafen Düsseldorf Bahnhof - Flughafen Düsseldorf Terminan
            // and Schwebebahn Wuppertal (line 60) are both returned as product "LightRail".
            return .tram
        case "Bus", "CommunityBus", "RailReplacementServices":
            return .bus
        case "Boat":
            return .ferry
        case "OnDemandServices":
            return .onDemand
        default:
            return nil
        }
    }
    
    func parseFare(costs: [String: Any]?) -> [Fare] {
        guard let costs = costs else { return [] }
        var fares: [Fare] = []
        
        let name = costs["name"] as? String
        let text = costs["text"] as? String
        let price = costs["price"] as? Double ?? 0
        let level: String?
        if let levelString = costs["level"] as? String {
            level = "Preisstufe " + levelString
        } else {
            level = nil
        }
        
        if let name = name, price != 0, let level = level {
            fares.append(Fare(network: name, type: .adult, currency: "EUR", fare: Float(price), unitsName: level, units: nil))
        } else if let name = name, name == "NRW-Tarif", let text = text, let match = text.match(pattern: VrsProvider.P_NRW_TARIF), let group = match[0], let price = Float(group) {
            fares.append(Fare(network: name, type: .adult, currency: "EUR", fare: price, unitsName: nil, units: nil))
        }
        
        return fares
    }
    
    func parseLocationAndPosition(from location: [String: Any]) throws -> LocationWithPosition {
        let locationType: LocationType
        var id: String? = nil
        var name: String? = nil
        var position: String? = nil
        if let stationId = location["id"] as? Int {
            locationType = .station
            id = "\(stationId)"
            name = location["name"] as? String
            for pattern in VrsProvider.NAME_WITH_POSITION_PATTERNS {
                guard let match = name?.match(pattern: pattern) else { continue }
                name = match[0]
                position = match[1]
                break
            }
        } else if let street = location["street"] as? String, let number = location["number"] as? String {
            locationType = .address
            name = ("\(street) \(number)").trimmingCharacters(in: .whitespaces)
        } else if let poiName = location["name"] as? String {
            locationType = .poi
            if let tmpId = location["tempId"] as? Int {
                id = "\(tmpId)"
            }
            name = poiName
        } else if location["x"] != nil && location["y"] != nil {
            locationType = .any
        } else {
            throw ParseError(reason: "failed to parse location type")
        }
        
        let place: String?
        if let p = location["city"] as? String {
            if let district = location["district"] as? String, district != "" {
                place = "\(p)-\(district)"
            } else {
                place = p
            }
        } else {
            place = nil
        }
        
        let lat = Int(round((location["x"] as? Double ?? 0) * 1e6))
        let lon = Int(round((location["y"] as? Double ?? 0) * 1e6))
        
        guard let location = Location(type: locationType, id: id, coord: LocationPoint(lat: lat, lon: lon), place: place, name: name) else {
            throw ParseError(reason: "failed to parse location")
        }
        
        return LocationWithPosition(location: location, position: position)
    }
    
    public class Context: QueryTripsContext {
        
        public override var canQueryLater: Bool { return queryLater }
        public override var canQueryEarlier: Bool { return queryEarlier }
        
        var queryLater = true, queryEarlier = true
        
        public var lastDeparture: Date?
        public var firstArrival: Date?
        public var from: Location!
        public var via: Location?
        public var to: Location!
        public var products: [Product]?
        
        public override init() {
            super.init()
        }
        
        public required init?(coder aDecoder: NSCoder) {
            guard
                let from = aDecoder.decodeObject(of: Location.self, forKey: PropertyKey.from),
                let to = aDecoder.decodeObject(of: Location.self, forKey: PropertyKey.to)
                else {
                    return nil
            }
            let lastDeparture = aDecoder.decodeObject(of: NSDate.self, forKey: PropertyKey.lastDeparture) as Date?
            let firstArrival = aDecoder.decodeObject(of: NSDate.self, forKey: PropertyKey.firstArrival) as Date?
            let via = aDecoder.decodeObject(of: Location.self, forKey: PropertyKey.via)
            let productsString = aDecoder.decodeObject(of: [NSArray.self, NSString.self], forKey: PropertyKey.products) as? [String]
            let products = productsString?.compactMap { Product(rawValue: $0) }
            let queryLater = aDecoder.decodeBool(forKey: PropertyKey.queryLater)
            let queryEarlier = aDecoder.decodeBool(forKey: PropertyKey.queryEarlier)
            super.init()
            self.lastDeparture = lastDeparture
            self.firstArrival = firstArrival
            self.from = from
            self.via = via
            self.to = to
            self.products = products
            self.queryLater = queryLater
            self.queryEarlier = queryEarlier
        }
        
        public override func encode(with aCoder: NSCoder) {
            aCoder.encode(lastDeparture, forKey: PropertyKey.lastDeparture)
            aCoder.encode(firstArrival, forKey: PropertyKey.firstArrival)
            aCoder.encode(from, forKey: PropertyKey.from)
            aCoder.encode(via, forKey: PropertyKey.via)
            aCoder.encode(to, forKey: PropertyKey.to)
            aCoder.encode(products?.map { $0.rawValue }, forKey: PropertyKey.products)
        }
        
        func departure(date: Date?) {
            guard let date = date else { return }
            if lastDeparture == nil || lastDeparture! < date {
                lastDeparture = date
            }
        }
        
        func arrival(date: Date?) {
            guard let date = date else { return }
            if firstArrival == nil || firstArrival! > date {
                firstArrival = date
            }
        }
        
        struct PropertyKey {
            static let lastDeparture = "lastDeparture"
            static let firstArrival = "firstArrival"
            static let from = "from"
            static let via = "via"
            static let to = "to"
            static let products = "products"
            static let queryLater = "queryLater"
            static let queryEarlier = "queryEarlier"
        }
        
    }
    
    struct LocationWithPosition {
        
        let location: Location
        let position: String?
        
    }
    
}

public class VrsJourneyContext: QueryJourneyDetailContext {
    
    public override class var supportsSecureCoding: Bool { return true }
    
    let from: Location
    let to: Location
    let time: Date
    let plannedTime: Date
    let product: Product?
    let line: Line?
    
    init(from: Location, to: Location, time: Date, plannedTime: Date, product: Product?, line: Line?) {
        self.from = from
        self.to = to
        self.time = time
        self.plannedTime = plannedTime
        self.product = product
        self.line = line
        super.init()
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let from = aDecoder.decodeObject(of: Location.self, forKey: PropertyKey.from), let to = aDecoder.decodeObject(of: Location.self, forKey: PropertyKey.to), let time = aDecoder.decodeObject(of: NSDate.self, forKey: PropertyKey.time) as Date?, let plannedTime = aDecoder.decodeObject(of: NSDate.self, forKey: PropertyKey.plannedTime) as Date? else { return nil }
        let product = Product(rawValue: aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.product) as String? ?? "")
        let line = aDecoder.decodeObject(of: Line.self, forKey: PropertyKey.line)
        
        self.init(from: from, to: to, time: time, plannedTime: plannedTime, product: product, line: line)
    }
    
    public override func encode(with aCoder: NSCoder) {
        aCoder.encode(from, forKey: PropertyKey.from)
        aCoder.encode(to, forKey: PropertyKey.to)
        aCoder.encode(time, forKey: PropertyKey.time)
        aCoder.encode(plannedTime, forKey: PropertyKey.plannedTime)
        if let product = product {
            aCoder.encode(product.rawValue, forKey: PropertyKey.product)
        }
        if let line = line {
            aCoder.encode(line, forKey: PropertyKey.line)
        }
    }
    
    struct PropertyKey {
        
        static let from = "from"
        static let to = "to"
        static let time = "time"
        static let plannedTime = "plannedTime"
        static let product = "product"
        static let line = "line"
        
    }
    
}
