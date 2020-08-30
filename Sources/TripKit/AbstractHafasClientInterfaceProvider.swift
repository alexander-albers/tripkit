import Foundation
import os.log

public class AbstractHafasClientInterfaceProvider: AbstractHafasProvider {
    
    override public var supportedQueryTraits: Set<QueryTrait> { return [.maxChanges, .minChangeTime] }
    
    var mgateEndpoint: String
    var apiVersion: String?
    var apiAuthorization: Any?
    var apiClient: Any?
    var extVersion: String?
    var desktopQueryEndpoint: String?
    var desktopStboardEndpoint: String?
    var requestVerification: RequestVerification = .none
    var configJson: [String: Any] = [:]
    var userAgent: String?
    
    init(networkId: NetworkId, apiBase: String, productsMap: [Product?]) {
        self.mgateEndpoint = apiBase + "mgate.exe"
        self.desktopQueryEndpoint = apiBase + "query.exe/dn"
        self.desktopStboardEndpoint = apiBase + "stboard.exe/dn"
        super.init(networkId: networkId, productsMap: productsMap)
    }
    
    init(networkId: NetworkId, apiBase: String, desktopQueryEndpoint: String?, desktopStboardEndpoint: String?, productsMap: [Product?]) {
        self.mgateEndpoint = apiBase + "mgate.exe"
        self.desktopQueryEndpoint = desktopQueryEndpoint
        self.desktopStboardEndpoint = desktopStboardEndpoint
        super.init(networkId: networkId, productsMap: productsMap)
    }
    
    // MARK: NetworkProvider implementations – Requests
    
    override public func suggestLocations(constraint: String, types: [LocationType]?, maxLocations: Int, completion: @escaping (SuggestLocationsResult) -> Void) -> AsyncRequest {
        var type: String
        if let types = types, !types.isEmpty {
            if types.contains(.any) || [.station, .poi, .address].allSatisfy(types.contains) {
                type = "ALL"
            } else {
                type = ""
                types.forEach { t in
                    switch t {
                    case .station:
                        type += "S"
                    case .poi:
                        type += "P"
                    case .address:
                        type += "A"
                    default: break
                    }
                }
            }
        } else {
            type = "ALL"
        }
        let request = wrapJsonApiRequest(meth: "LocMatch", req: ["input": ["field": "S", "loc": ["name": constraint + "?", "type": type], "maxLoc": maxLocations > 0 ? maxLocations : 50]], formatted: true)
        let urlBuilder = UrlBuilder(path: mgateEndpoint, encoding: requestUrlEncoding)
        requestVerification.appendParameters(to: urlBuilder, requestString: request)
        
        return HttpClient.get(httpRequest: HttpRequest(urlBuilder: urlBuilder).setPostPayload(request).setUserAgent(userAgent)) { result in
            switch result {
            case .success((_, let data)):
                do {
                    try self.handleJsonLocMatch(response: try data.toJson(), completion: completion)
                } catch let err as ParseError {
                    os_log("suggestLocations parse error: %{public}@", log: .requestLogger, type: .error, err.reason)
                    completion(.failure(err))
                } catch let err {
                    os_log("suggestLocations handle response error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                    completion(.failure(err))
                }
            case .failure(let err):
                os_log("suggestLocations network error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                completion(.failure(err))
            }
        }
    }
    
    override public func queryNearbyLocations(location: Location, types: [LocationType]?, maxDistance: Int, maxLocations: Int, completion: @escaping (NearbyLocationsResult) -> Void) -> AsyncRequest {
        if let coord = location.coord {
            return jsonLocGeoPos(types: types, lat: coord.lat, lon: coord.lon, maxDistance: maxDistance, maxLocations: maxLocations, completion: completion)
        } else {
            completion(.invalidId) // TODO: nearby locations of station id
            return AsyncRequest(task: nil)
        }
    }
    
    func jsonLocGeoPos(types: [LocationType]?, lat: Int, lon: Int, maxDistance: Int, maxLocations: Int, completion: @escaping (NearbyLocationsResult) -> Void) -> AsyncRequest {
        // TODO: extract parameters to method
        var ring: [String: Any] = ["cCrd": ["x": lon, "y": lat]]
        if maxDistance > 0 {
            ring["maxDist"] = maxDistance
        } else {
            ring["maxDist"] = 5000
        }
        var req: [String: Any] = ["ring": ring, "getPOIs": types?.contains(.poi) ?? false, "getStops": types?.contains(.station) ?? true]
        if maxLocations > 0 {
            req["maxLoc"] = maxLocations
        } else {
            req["maxLoc"] = 50
        }
        let request = wrapJsonApiRequest(meth: "LocGeoPos", req: req, formatted: false)
        let urlBuilder = UrlBuilder(path: mgateEndpoint, encoding: requestUrlEncoding)
        requestVerification.appendParameters(to: urlBuilder, requestString: request)
        
        return HttpClient.get(httpRequest: HttpRequest(urlBuilder: urlBuilder).setPostPayload(request).setUserAgent(userAgent)) { result in
            switch result {
            case .success((_, let data)):
                do {
                    try self.handleJsonLocGeoPos(response: try data.toJson(), types: types, completion: completion)
                } catch let err as ParseError {
                    os_log("nearbyStations parse error: %{public}@", log: .requestLogger, type: .error, err.reason)
                    completion(.failure(err))
                } catch let err {
                    os_log("nearbyStations handle response error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                    completion(.failure(err))
                }
            case .failure(let err):
                os_log("nearbyStations network error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                completion(.failure(err))
            }
        }
    }
    
    override public func queryDepartures(stationId: String, departures: Bool, time: Date?, maxDepartures: Int, equivs: Bool, completion: @escaping (QueryDeparturesResult) -> Void) -> AsyncRequest {
        // TODO: extract parameters to method
        let jsonDate = self.jsonDate(from: time ?? Date())
        let jsonTime = self.jsonTime(from: time ?? Date())
        let normalizedStationId = normalize(stationId: stationId) ?? ""
        var req: [String: Any] = [
            "type": departures ? "DEP" : "ARR",
            "date": jsonDate,
            "time": jsonTime,
            "stbLoc": [
                "type": "S",
                "state": "F",
                normalizedStationId.hasSuffix("@") ? "lid" : "extId": normalizedStationId
            ],
            "maxJny": maxDepartures != 0 ? maxDepartures : 50
        ]
        if let apiVersion = apiVersion, apiVersion.compare("1.19", options: .numeric) == .orderedAscending {
            req["stbFltrEquiv"] = !equivs
            req["getPasslist"] = false
        }
        let request = wrapJsonApiRequest(meth: "StationBoard", req: req, formatted: false)
        let urlBuilder = UrlBuilder(path: mgateEndpoint, encoding: requestUrlEncoding)
        requestVerification.appendParameters(to: urlBuilder, requestString: request)
        
        let desktopUrl: URL?
        if let desktopStboardEndpoint = desktopStboardEndpoint {
            let desktopUrlBuilder = UrlBuilder(path: desktopStboardEndpoint, encoding: requestUrlEncoding)
            xmlStationBoardParameters(builder: desktopUrlBuilder, stationId: stationId, departures: departures, time: time, maxDepartures: maxDepartures, equivs: equivs, styleSheet: nil)
            desktopUrl = desktopUrlBuilder.build()
        } else {
            desktopUrl = nil
        }
        
        return HttpClient.get(httpRequest: HttpRequest(urlBuilder: urlBuilder).setPostPayload(request).setUserAgent(userAgent)) { result in
            switch result {
            case .success((_, let data)):
                do {
                    try self.handleJsonStationBoard(response: try data.toJson(), stationId: stationId, departures: departures, equivs: equivs, desktopUrl: desktopUrl, completion: completion)
                } catch let err as ParseError {
                    os_log("queryDepartures parse error: %{public}@", log: .requestLogger, type: .error, err.reason)
                    completion(.failure(err))
                } catch let err {
                    os_log("queryDepartures handle response error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                    completion(.failure(err))
                }
            case .failure(let err):
                os_log("queryDepartures network error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                completion(.failure(err))
            }
        }
    }
    
    public override func queryTrips(from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions, completion: @escaping (QueryTripsResult) -> Void) -> AsyncRequest {
        if from.id == nil && !from.hasLocation() {
            return jsonTripSearchIdentify(location: from) { (locations) in
                if locations.count > 1 {
                    completion(.ambiguous(ambiguousFrom: locations, ambiguousVia: [], ambiguousTo: []))
                } else if let location = locations.first {
                    let _ = self.queryTrips(from: location, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions, completion: completion)
                } else {
                    completion(.unknownFrom)
                }
            }
        } else if let via = via, via.id == nil && !via.hasLocation() {
            return jsonTripSearchIdentify(location: via) { (locations) in
                if locations.count > 1 {
                    completion(.ambiguous(ambiguousFrom: [], ambiguousVia: locations, ambiguousTo: []))
                } else if let location = locations.first {
                    let _ = self.queryTrips(from: from, via: location, to: to, date: date, departure: departure, tripOptions: tripOptions, completion: completion)
                } else {
                    completion(.unknownVia)
                }
            }
        } else if to.id == nil && !to.hasLocation() {
            return jsonTripSearchIdentify(location: to) { (locations) in
                if locations.count > 1 {
                    completion(.ambiguous(ambiguousFrom: [], ambiguousVia: [], ambiguousTo: locations))
                } else if let location = locations.first {
                    let _ = self.queryTrips(from: from, via: via, to: location, date: date, departure: departure, tripOptions: tripOptions, completion: completion)
                } else {
                    completion(.unknownTo)
                }
            }
        } else {
            return doJsonTripSearch(from: from, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions, previousContext: nil, later: false, completion: completion)
        }
    }
    
    func jsonTripSearchIdentify(location: Location, completion: @escaping ([Location]) -> Void) -> AsyncRequest {
        if let name = location.name {
            return suggestLocations(constraint: [location.place, name].compactMap({$0}).joined(separator: " "), types: [.station], maxLocations: 10) { (result: SuggestLocationsResult) in
                switch result {
                case .success(let locations):
                    completion(locations.map({$0.location}))
                case .failure(_):
                    completion([])
                }
            }
        } else if let coord = location.coord {
            return jsonLocGeoPos(types: LocationType.ALL, lat: coord.lat, lon: coord.lon, maxDistance: 0, maxLocations: 0) { (result: NearbyLocationsResult) in
                switch result {
                case .success(let locations):
                    completion(locations)
                case .invalidId, .failure(_):
                    completion([])
                }
            }
        } else {
            completion([])
            return AsyncRequest(task: nil)
        }
    }
    
    override public func queryMoreTrips(context: QueryTripsContext, later: Bool, completion: @escaping (QueryTripsResult) -> Void) -> AsyncRequest {
        guard let context = context as? Context else {
            completion(.sessionExpired)
            return AsyncRequest(task: nil)
        }
        return doJsonTripSearch(from: context.from, via: context.via, to: context.to, date: context.date, departure: context.departure, tripOptions: context.tripOptions, previousContext: context, later: later, completion: completion)
    }
    
    func doJsonTripSearch(from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions, previousContext: Context?, later: Bool, completion: @escaping (QueryTripsResult) -> Void) -> AsyncRequest {
        
        let request = wrapJsonApiRequest(meth: "TripSearch", req: jsonTripSearchRequest(from: from, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions, previousContext: previousContext, later: later), formatted: true)
        let urlBuilder = UrlBuilder(path: mgateEndpoint, encoding: requestUrlEncoding)
        requestVerification.appendParameters(to: urlBuilder, requestString: request)
        
        let desktopUrl: URL?
        if let context = previousContext {
            desktopUrl = context.desktopUrl
        } else if let desktopQueryEndpoint = desktopQueryEndpoint {
            let desktopUrlBuilder = UrlBuilder(path: desktopQueryEndpoint, encoding: requestUrlEncoding)
            queryTripsBinaryParameters(builder: desktopUrlBuilder, from: from, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions, desktop: true)
            desktopUrl = desktopUrlBuilder.build()
        } else {
            desktopUrl = nil
        }
        
        return HttpClient.get(httpRequest: HttpRequest(urlBuilder: urlBuilder).setPostPayload(request).setUserAgent(userAgent)) { result in
            switch result {
            case .success((_, let data)):
                do {
                    try self.handleJsonTripSearch(response: try data.toJson(), desktopUrl: desktopUrl, from: from, via: via, to: to, date: date, departure: departure, previousContext: previousContext, later: later, tripOptions: tripOptions, completion: completion)
                } catch let err as ParseError {
                    os_log("queryTrips parse error: %{public}@", log: .requestLogger, type: .error, err.reason)
                    completion(.failure(err))
                } catch let err {
                    os_log("queryTrips handle response error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                    completion(.failure(err))
                }
            case .failure(let err):
                os_log("queryTrips network error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                completion(.failure(err))
            }
        }
    }
    
    public override func refreshTrip(context: RefreshTripContext, completion: @escaping (QueryTripsResult) -> Void) -> AsyncRequest {
        guard let context = context as? HafasClientInterfaceRefreshTripContext else {
            completion(.sessionExpired)
            return AsyncRequest(task: nil)
        }
        let request = wrapJsonApiRequest(meth: "Reconstruction", req: ["ctxRecon": context.contextRecon,"trfReq": [ "jnyCl": 2, "cType": "PK", "tvlrProf": [[ "type": "E"]]],            "getPolyline": true, "getPasslist": true], formatted: true)
        let urlBuilder = UrlBuilder(path: mgateEndpoint, encoding: requestUrlEncoding)
        requestVerification.appendParameters(to: urlBuilder, requestString: request)
        
        return HttpClient.get(httpRequest: HttpRequest(urlBuilder: urlBuilder).setPostPayload(request).setUserAgent(userAgent)) { result in
            switch result {
            case .success((_, let data)):
                do {
                    try self.handleJsonTripSearch(response: try data.toJson(), desktopUrl: nil, from: context.from, via: nil, to: context.to, date: Date(), departure: true, previousContext: nil, later: false, tripOptions: TripOptions(), completion: completion)
                } catch let err as ParseError {
                    os_log("refreshTrip parse error: %{public}@", log: .requestLogger, type: .error, err.reason)
                    completion(.failure(err))
                } catch let err {
                    os_log("refreshTrip handle response error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                    completion(.failure(err))
                }
            case .failure(let err):
                os_log("refreshTrip network error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                completion(.failure(err))
            }
        }
    }
    
    public override func queryJourneyDetail(context: QueryJourneyDetailContext, completion: @escaping (QueryJourneyDetailResult) -> Void) -> AsyncRequest {
        guard let context = context as? HafasClientInterfaceJourneyContext else {
            completion(.invalidId)
            return AsyncRequest(task: nil)
        }
        let req: [String: Any] = [
            "jid": context.journeyId,
            "getPasslist": true,
            "getPolyline": true
        ]
        let request = wrapJsonApiRequest(meth: "JourneyDetails", req: req, formatted: false)
        let urlBuilder = UrlBuilder(path: mgateEndpoint, encoding: requestUrlEncoding)
        requestVerification.appendParameters(to: urlBuilder, requestString: request)
        
        return HttpClient.get(httpRequest: HttpRequest(urlBuilder: urlBuilder).setPostPayload(request).setUserAgent(userAgent)) { result in
            switch result {
            case .success((_, let data)):
                do {
                    try self.handleQueryJourneyDetail(response: try data.toJson(), completion: completion)
                } catch let err as ParseError {
                    os_log("queryJourneyDetail parse error: %{public}@", log: .requestLogger, type: .error, err.reason)
                    completion(.failure(err))
                } catch let err {
                    os_log("queryJourneyDetail handle response error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                    completion(.failure(err))
                }
            case .failure(let err):
                os_log("queryJourneyDetail network error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                completion(.failure(err))
            }
        }
    }
    
    // MARK: NetworkProvider responses
    
    func handleJsonLocMatch(response: Any?, completion: @escaping (SuggestLocationsResult) -> Void) throws {
        guard let json = response as? [String: Any], json["err"] == nil || json["err"] as? String == "OK", let svcResL = json["svcResL"] as? [Any], svcResL.count == 1, let svcRes = svcResL[0] as? [String: Any], let meth = svcRes["meth"] as? String, meth == "LocMatch", let error = svcRes["err"] as? String else {
            throw ParseError(reason: "could not parse json")
        }
        if error != "OK" {
            throw ParseError(reason: "\(error): \(svcRes["errTxt"] as? String ?? "")")
        }
        guard let res = svcRes["res"] as? [String: Any], let match = res["match"] as? [String: Any], let locList = match["locL"] as? [Any] else {
            throw ParseError(reason: "could not parse loc list")
        }
        let locations = try parseLocList(locList: locList)
        let suggestedLocations = locations.map({SuggestedLocation(location: $0, priority: 0)})
        
        completion(.success(locations: suggestedLocations))
    }
    
    func handleJsonLocGeoPos(response: Any?, types: [LocationType]?, completion: @escaping (NearbyLocationsResult) -> Void) throws {
        let types = types ?? [.station]
        guard let json = response as? [String: Any], json["err"] == nil || json["err"] as? String == "OK", let svcResL = json["svcResL"] as? [Any], svcResL.count == 1, let svcRes = svcResL[0] as? [String: Any], let meth = svcRes["meth"] as? String, meth == "LocGeoPos", let error = svcRes["err"] as? String else {
            throw ParseError(reason: "could not parse json")
        }
        if error != "OK" {
            throw ParseError(reason: "\(error): \(svcRes["errTxt"] as? String ?? "")")
        }
        guard let res = svcRes["res"] as? [String: Any] else {
            throw ParseError(reason: "could not parse loc list")
        }
        let locations: [Location]
        if let locList = res["locL"] as? [Any] {
            locations = try parseLocList(locList: locList).filter({types.contains($0.type)})
        } else {
            locations = []
        }
        
        completion(.success(locations: locations))
    }
    
    func handleJsonStationBoard(response: Any?, stationId: String, departures: Bool, equivs: Bool, desktopUrl: URL?, completion: @escaping (QueryDeparturesResult) -> Void) throws {
        guard let json = response as? [String: Any], json["err"] == nil || json["err"] as? String == "OK", let svcResL = json["svcResL"] as? [Any], svcResL.count == 1, let svcRes = svcResL[0] as? [String: Any], let meth = svcRes["meth"] as? String, meth == "StationBoard", let err = svcRes["err"] as? String else {
            throw ParseError(reason: "could not parse json")
        }
        if err != "OK" {
            let errTxt = svcRes["errTxt"] as? String ?? ""
            // TODO: handle more errors
            os_log("Received hafas error %{public}@: %{public}@", log: .requestLogger, type: .error, err, errTxt)
            if err == "LOCATION" {
                completion(.invalidStation)
            } else if err == "FAIL" && errTxt == "HCI Service: request failed" {
                throw ParseError(reason: "request failed")
            } else if err == "PROBLEMS" && errTxt == "HCI Service: problems during service execution" {
                throw ParseError(reason: "problems during service execution")
            } else if err == "CGI_READ_FAILED" {
                throw ParseError(reason: "cgi read failed")
            } else {
                throw ParseError(reason: "unknown hafas error \(err): \(errTxt)")
            }
            return
        } else if apiVersion == "1.10", let svcResJson = encodeJson(dict: svcRes), svcResJson.length == 170 {
            completion(.invalidStation)
            return
        }
        guard let res = svcRes["res"] as? [String: Any], let common = res["common"] as? [String: Any], let locList = common["locL"] as? [Any], let opList = common["opL"] as? [Any], let prodList = common["prodL"] as? [Any] else {
            throw ParseError(reason: "could not parse lists")
        }
        
        let locations = try parseLocList(locList: locList)
        let operators = try parseOpList(opList: opList)
        let lines = try parseProdList(prodList: prodList, operators: operators)
        let remList = common["remL"] as? [Any]
        let rems = try parseRemList(remList: remList)
        
        var result: [StationDepartures] = []
        for jny in res["jnyL"] as? [Any] ?? [] {
            guard let jny = jny as? [String: Any], let stbStop = jny["stbStop"] as? [String: Any], let dateString = jny["date"] as? String, let lineIndex = (departures ? stbStop["dProdX"] : stbStop["aProdX"]) as? Int, let jnyDirTxt = jny["dirTxt"] as? String else { throw ParseError(reason: "could not parse jny") }
            
            if let reachable = jny["isRchbl"] as? Bool, !reachable {
                continue
            }
            if let cancelled = jny["dCncl"] as? Bool, cancelled {
                continue
            }
            
            var dateComponents = DateComponents()
            dateComponents.timeZone = timeZone
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = timeZone
            parseIsoDate(from: dateString, dateComponents: &dateComponents)
            guard let baseDate = calendar.date(from: dateComponents) else { throw ParseError(reason: "could not parse base date") }
            
            let plannedTime = try parseJsonTime(baseDate: baseDate, dateString: (departures ? stbStop["dTimeS"] : stbStop["aTimeS"]) as? String)
            let predictedTime = try parseJsonTime(baseDate: baseDate, dateString: (departures ? stbStop["dTimeR"] : stbStop["aTimeR"]) as? String)
            
            let line = lines[lineIndex]
            
            let location: Location
            if equivs {
                guard let locationIndex = stbStop["locX"] as? Int else { throw ParseError(reason: "could not parse location index") }
                location = locations[locationIndex]
            } else {
                location = Location(type: .station, id: stationId)!
            }
            let position = parsePosition(position: (departures ? stbStop["dPlatfR"] : stbStop["aPlatfR"]) as? String)
            let plannedPosition = parsePosition(position: (departures ? stbStop["dPlatfS"] : stbStop["aPlatfS"]) as? String)
            
            let destination: Location?
            if let stopL = jny["stopL"] as? [Any] {
                guard let lastIndex = (stopL.last as? [String: Any])?["locX"] as? Int, let name = (locList[lastIndex] as? [String: Any])?["name"] as? String else { throw ParseError(reason: "could not parse stop destination list") }
                if jnyDirTxt == name {
                    destination = locations[lastIndex]
                } else {
                    let nameAndPlace = split(stationName: stripLineFromDestination(line: line, destinationName: jnyDirTxt))
                    destination = Location(type: .any, id: nil, coord: nil, place: nameAndPlace.0, name: nameAndPlace.1)
                }
            } else {
                let nameAndPlace = split(stationName: stripLineFromDestination(line: line, destinationName: jnyDirTxt))
                destination = Location(type: .any, id: nil, coord: nil, place: nameAndPlace.0, name: nameAndPlace.1)
            }
            var message = ""
            var departureCancelled = false
            for msg in jny["msgL"] as? [Any] ?? [] {
                guard let msg = msg as? [String: Any], let type = msg["type"] as? String, type == "REM", let remX = msg["remX"] as? Int, remX >= 0 && remX < rems?.count ?? 0, let rem = rems?[remX] else { continue }
                switch rem {
                case .cancelled(_):
                    departureCancelled = true
                    break
                case .stopCancelled(_):
                    departureCancelled = true
                    break
                case .unknown(let reason):
                    if let reason = reason {
                        if message != "" {
                            message += "\n"
                        }
                        message += reason.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !message.hasSuffix(".") && !message.hasSuffix("!") {
                            message += "."
                        }
                    }
                    break
                default:
                    break
                }
            }
            if departureCancelled {
                continue
            }
            
            let journeyContext: HafasClientInterfaceJourneyContext?
            if let id = jny["jid"] as? String {
                journeyContext = HafasClientInterfaceJourneyContext(journeyId: id)
            } else {
                journeyContext = nil
            }
            let wagonSequenceContext: URL?
            if line.label?.hasPrefix("ICE") ?? false, let number = line.number, let plannedTime = plannedTime {
                wagonSequenceContext = getWagonSequenceUrl(number: number, plannedTime: plannedTime)
            } else {
                wagonSequenceContext = nil
            }
            let departure = Departure(plannedTime: plannedTime, predictedTime: predictedTime, line: line, position: position, plannedPosition: plannedPosition, destination: destination, capacity: nil, message: !message.isEmpty ? message : nil, journeyContext: journeyContext, wagonSequenceContext: wagonSequenceContext)
            
            var stationDepartures = result.first(where: {$0.stopLocation.id == location.id})
            if stationDepartures == nil {
                stationDepartures = StationDepartures(stopLocation: location, departures: [], lines: [])
                result.append(stationDepartures!)
            }
            stationDepartures?.departures.append(departure)
        }
        for stationDeparture in result {
            stationDeparture.departures.sort(by: {$0.getTime() < $1.getTime()})
        }
        
        completion(.success(departures: result, desktopUrl: desktopUrl))
    }
    
    func handleJsonTripSearch(response: Any?, desktopUrl: URL?, from: Location, via: Location?, to: Location, date: Date, departure: Bool, previousContext: Context?, later: Bool, tripOptions: TripOptions, completion: @escaping (QueryTripsResult) -> Void) throws {
        guard let json = response as? [String: Any], json["err"] == nil || json["err"] as? String == "OK", let svcResL = json["svcResL"] as? [Any], svcResL.count == 1, let svcRes = svcResL[0] as? [String: Any], let meth = svcRes["meth"] as? String, meth == "TripSearch" || meth == "Reconstruction", let err = svcRes["err"] as? String else {
            throw ParseError(reason: "could not parse json")
        }
        if err != "OK" {
            let errTxt = svcRes["errTxt"] as? String ?? ""
            os_log("Hafas error %{public}@: %{public}@", log: .requestLogger, type: .error, err, errTxt)
            if err == "H890" { // No connections found.
                completion(.noTrips)
            } else if err == "H891" { // No route found (try entering an intermediate station).
                completion(.noTrips)
            } else if err == "H892" { // HAFAS Kernel: Request too complex (try entering less intermediate stations).
                completion(.noTrips)
            } else if err == "H895" { // Departure/Arrival are too near.
                completion(.tooClose)
            } else if err == "H9220" { // Nearby to the given address stations could not be found.
                completion(.noTrips)
            } else if err == "H886" { // HAFAS Kernel: No connections found within the requested time interval.
                throw ParseError(reason: "No connections found within the requested time interval.")
            } else if err == "H887" { // HAFAS Kernel: Kernel computation time limit reached.
                throw ParseError(reason: "Kernel computation time limit reached.")
            } else if err == "H9240" { // HAFAS Kernel: Internal error.
                throw ParseError(reason: "Internal error.")
            } else if err == "H9360" { // Date outside of the timetable period.
                completion(.invalidDate)
            } else if err == "H9380" { // Departure/Arrival/Intermediate or equivalent stations def'd more than once
                completion(.tooClose)
            } else if err == "FAIL" && errTxt == "HCI Service: request failed" {
                throw ParseError(reason: "request failed")
            } else if err == "LOCATION" && errTxt == "HCI Service: location missing or invalid" {
                completion(.ambiguous(ambiguousFrom: [], ambiguousVia: [], ambiguousTo: []))
            } else if err == "PROBLEMS" && errTxt == "HCI Service: problems during service execution" {
                throw ParseError(reason: "problems during service execution")
            } else if err == "CGI_READ_FAILED" {
                throw ParseError(reason: "cgi read failed")
            } else {
                throw ParseError(reason: "unknown hafas error \(err): \(errTxt)")
            }
            return
        }
        guard let res = svcRes["res"] as? [String: Any], let common = res["common"] as? [String: Any], let locList = common["locL"] as? [Any], let opList = common["opL"] as? [Any], let prodList = common["prodL"] as? [Any] else {
            throw ParseError(reason: "could not parse lists")
        }
        let remList = common["remL"] as? [Any]
        let himList = common["himL"] as? [Any]
        
        let locations = try parseLocList(locList: locList)
        let operators = try parseOpList(opList: opList)
        let lines = try parseProdList(prodList: prodList, operators: operators)
        let rems = try parseRemList(remList: remList)
        let messages = try parseMessageList(himList: himList)
        let outConL = res["outConL"] as? [Any] ?? []
        if outConL.isEmpty {
            completion(.noTrips)
            return
        }
        
        var trips: [Trip] = []
        for outCon in outConL {
            guard let outCon = outCon as? [String: Any], let depIndex = (outCon["dep"] as? [String: Any])?["locX"] as? Int, let arrIndex = (outCon["arr"] as? [String: Any])?["locX"] as? Int, let dateString = outCon["date"] as? String else { throw ParseError(reason: "could not parse outcon") }
            let from = locations[depIndex]
            let to = locations[arrIndex]
            
            var dateComponents = DateComponents()
            dateComponents.timeZone = timeZone
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = timeZone
            parseIsoDate(from: dateString, dateComponents: &dateComponents)
            guard let baseDate = calendar.date(from: dateComponents) else { throw ParseError(reason: "failed to parse outcon base date") }
            
            var legs: [Leg] = []
//            var tripCancelled: Bool = false
            for sec in outCon["secL"] as? [Any] ?? [] {
                guard let sec = sec as? [String: Any], let dep = sec["dep"] as? [String: Any], let arr = sec["arr"] as? [String: Any] else { throw ParseError(reason: "could not parse outcon sec") }
                
                let leg: Leg
                switch sec["type"] as? String ?? "" {
                case "JNY":
                    guard let jny = sec["jny"] as? [String: Any], let prodX = jny["prodX"] as? Int, let stopL = jny["stopL"] as? [Any] else { throw ParseError(reason: "failed to parse outcon jny") }
                    let attrs: [Line.Attr]?
                    var message = ""
                    if let remL = jny["remL"] as? [Any] ?? jny["msgL"] as? [Any] {
                        var result: [Line.Attr] = []
                        for rem in remL {
                            guard let rem = rem as? [String: Any] else { continue }
                            if let remX = rem["remX"] as? Int, jny["msgL"] != nil && rem["type"] as? String == "REM" {
                                if let attr = rems?[remX] {
                                    switch attr {
                                    case .bicycleCarriage:
                                        result.append(.bicycleCarriage)
                                        break
                                    case .wheelChairAccess:
                                        result.append(.wheelChairAccess)
                                        break
                                    case .boardRestaurant:
                                        result.append(.restaurant)
                                        break
                                    case .airConditioned:
                                        result.append(.airConditioned)
                                        break
                                    case .wifi:
                                        result.append(.wifiAvailable)
                                        break
                                    case .powerSockets:
                                        result.append(.powerSockets)
                                        break
                                    default:
                                        break
                                    }
                                }
                            } else if let himX = rem["himX"] as? Int, rem["type"] as? String == "HIM" {
                                guard let text = messages?[himX] else { continue }
                                if message != "" {
                                    message += "\n"
                                }
                                message += text.trimmingCharacters(in: .whitespacesAndNewlines)
                                if !message.hasSuffix(".") && !message.hasSuffix("!") {
                                    message += "."
                                }
                            }
                        }
                        attrs = result.isEmpty ? nil : result
                    } else {
                        attrs = nil
                    }
                    let l = lines[prodX]
                    let line = Line(id: l.id, network: l.network, product: l.product, label: l.label, name: l.name, number: l.number, style: l.style, attr: attrs, message: l.message)
                    let dirTxt = jny["dirTxt"] as? String
                    let nameAndPlace = split(stationName: stripLineFromDestination(line: line, destinationName: dirTxt))
                    let destination: Location? = dirTxt == nil ? nil : Location(type: .any, id: nil, coord: nil, place: nameAndPlace.0, name: nameAndPlace.1)
                    
                    guard let departureStop = try parseStop(dict: dep, locations: locations, rems: rems, baseDate: baseDate, line: line), let arrivalStop = try parseStop(dict: arr, locations: locations, rems: rems, baseDate: baseDate, line: line) else { throw ParseError(reason: "failed to parse departure/arrival stop") }
                    
                    var intermediateStops: [Stop] = []
                    for stop in stopL {
                        guard let stop = stop as? [String: Any] else { throw ParseError(reason: "failed to parse jny stop") }
                        if let border = stop["border"] as? Bool, border { continue } // hide borders from intermediate stops
                        guard let intermediateStop = try parseStop(dict: stop, locations: locations, rems: rems, baseDate: baseDate, line: line) else { continue }
                        intermediateStops.append(intermediateStop)
                    }
                    if intermediateStops.count >= 2 {
                        intermediateStops.removeFirst()
                        intermediateStops.removeLast()
                    }
                    
                    let path: [LocationPoint]
                    if let polyline = try? decodePolyline(from: (jny["poly"] as? [String: Any])?["crdEncYX"] as? String) {
                        path = polyline
                    } else {
                        path = []
                    }
                    
                    if let himL = jny["himL"] as? [Any] {
                        for him in himL {
                            guard let him = him as? [String: Any], let himX = him["himX"] as? Int else { throw ParseError(reason: "failed to parse him") }
                            guard let text = messages?[himX] else { continue }
                            if message != "" {
                                message += "\n"
                            }
                            message += text.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !message.hasSuffix(".") && !message.hasSuffix("!") {
                                message += "."
                            }
                        }
                    }
                    var cancelled = jny["isCncl"] as? Bool ?? false
                    for msg in jny["msgL"] as? [Any] ?? [] {
                        guard let msg = msg as? [String: Any], let type = msg["type"] as? String, type == "REM", let remX = msg["remX"] as? Int, remX >= 0 && remX < rems?.count ?? 0, let rem = rems?[remX] else { continue }
                        switch rem {
                        case .cancelled(let reason):
                            if let reason = reason {
                                if message != "" {
                                    message += "\n"
                                }
                                message += reason.trimmingCharacters(in: .whitespacesAndNewlines)
                                if !message.hasSuffix(".") && !message.hasSuffix("!") {
                                    message += "."
                                }
                            }
                            cancelled = true
                            break
                        case .unknown(let reason):
                            if let reason = reason {
                                if message != "" {
                                    message += "\n"
                                }
                                message += reason.trimmingCharacters(in: .whitespacesAndNewlines)
                                if !message.hasSuffix(".") && !message.hasSuffix("!") {
                                    message += "."
                                }
                            }
                            break
                        default:
                            break
                        }
                    }
                    if cancelled {
                        intermediateStops.forEach({$0.departureCancelled = true; $0.arrivalCancelled = true})
                    }
                    
                    let journeyContext: HafasClientInterfaceJourneyContext?
                    if let id = jny["jid"] as? String {
                        journeyContext = HafasClientInterfaceJourneyContext(journeyId: id)
                    } else {
                        journeyContext = nil
                    }
                    if let arrivalMessage = arrivalStop.message {
                        if message != "" {
                            message += "\n"
                        }
                        message += arrivalMessage
                    }
                    
                    leg = PublicLeg(line: line, destination: destination, departureStop: departureStop, arrivalStop: arrivalStop, intermediateStops: intermediateStops, message: !message.isEmpty ? message : nil, path: path, journeyContext: journeyContext)
                    break
                case "WALK", "TRSF":
                    guard let departureStop = try parseStop(dict: dep, locations: locations, rems: rems, baseDate: baseDate, line: nil), let arrivalStop = try parseStop(dict: arr, locations: locations, rems: rems, baseDate: baseDate, line: nil) else { throw ParseError(reason: "failed to parse departure/arrival stop") }
                    guard let gis = sec["gis"] as? [String: Any] else { throw ParseError(reason: "failed to parse outcon gis") }
                    let distance = gis["distance"] as? Int ?? 0
                    let addTime: TimeInterval = !legs.isEmpty ? max(0, -departureStop.getMinTime().timeIntervalSince(legs.last!.getMaxTime())) : 0
                    leg = IndividualLeg(type: .WALK, departureTime: departureStop.getMinTime().addingTimeInterval(addTime), departure: departureStop.location, arrival: arrivalStop.location, arrivalTime: arrivalStop.getMaxTime().addingTimeInterval(addTime), distance: distance, path: [])
                    break
                default:
                    throw ParseError(reason: "could not parse outcon sec type \(sec["type"] as? String ?? "")")
                }
                
                legs.append(leg)
            }
            
//            if tripCancelled {
            
//                continue
//            }
            
            var fares: [Fare] = []
            if let trfRes = outCon["trfRes"] as? [String: Any] {
                for fareSet in trfRes["fareSetL"] as? [Any] ?? [] {
                    guard let fareSet = fareSet as? [String: Any] else { throw ParseError(reason: "failed to parse fareset") }
                    let fareSetName = fareSet["name"] as? String
                    let fareSetDescription = fareSet["desc"] as? String
                    if fareSetName != nil || fareSetDescription != nil {
                        for fare in fareSet["fareL"] as? [Any] ?? [] {
                            guard let fare = fare as? [String: Any], let name = fare["name"] as? String else { throw ParseError(reason: "failed to parse fare") }
                            if let ticketList = fare["ticketL"] as? [Any] {
                                for ticket in ticketList {
                                    guard let ticket = ticket as? [String: Any], let ticketName = ticket["name"] as? String, let currency = ticket["cur"] as? String, let priceInt = ticket["prc"] as? Int else { throw ParseError(reason: "failed to parse fare arr") }
                                    let price = Float(priceInt) / 100.0
                                    if let fare = parseJsonTripFare(fareSetName: name, fareSetDescription: fareSetDescription ?? "", name: ticketName, currency: currency, price: price) {
                                        fares.append(fare)
                                    }
                                }
                            } else {
                                guard let currency = fare["cur"] as? String, let priceInt = fare["prc"] as? Int else { throw ParseError(reason: "failed to parse fare obj") }
                                let price = Float(priceInt) / 100.0
                                if let fare = parseJsonTripFare(fareSetName: fareSetName ?? "", fareSetDescription: fareSetDescription ?? "", name: name, currency: currency, price: price) {
                                    fares.append(fare)
                                }
                            }
                        }
                    } else if let fareL = fareSet["fareL"] as? [Any], let fare = fareL.first as? [String: Any], let priceInt = fare["prc"] as? Int, priceInt > 0 {
                        let price = Float(priceInt) / 100.0
                        let fare = Fare(network: "", type: .adult, currency: "EUR", fare: price, unitsName: nil, units: nil)
                        fares.append(fare)
                    }
                }
            }
            let context: HafasClientInterfaceRefreshTripContext?
            if let ctxRecon = outCon["ctxRecon"] as? String {
                context = HafasClientInterfaceRefreshTripContext(contextRecon: ctxRecon, from: from, to: to)
            } else {
                context = nil
            }
            
            let trip = Trip(id: "", from: from, to: to, legs: legs, fares: fares, refreshContext: context)
            trips.append(trip)
        }
        let context: Context
        if let previousContext = previousContext {
            context = Context(from: from, via: via, to: to, date: date, departure: departure, laterContext: later ? res["outCtxScrF"] as? String : previousContext.laterContext, earlierContext: !later ? res["outCtxScrB"] as? String : previousContext.earlierContext, desktopUrl: desktopUrl, tripOptions: tripOptions)
        } else {
            context = Context(from: from, via: via, to: to, date: date, departure: departure, laterContext: res["outCtxScrF"] as? String, earlierContext: res["outCtxScrB"] as? String, desktopUrl: desktopUrl, tripOptions: tripOptions)
        }
        completion(.success(context: context, from: from, via: via, to: to, trips: trips, messages: []))
    }
    
    func handleQueryJourneyDetail(response: Any?, completion: @escaping (QueryJourneyDetailResult) -> Void) throws {
        guard let json = response as? [String: Any], json["err"] == nil || json["err"] as? String == "OK", let svcResL = json["svcResL"] as? [Any], svcResL.count == 1, let svcRes = svcResL[0] as? [String: Any], let meth = svcRes["meth"] as? String, meth == "JourneyDetails", let error = svcRes["err"] as? String else {
            throw ParseError(reason: "could not parse json")
        }
        if error != "OK" {
            let errTxt = svcRes["errTxt"] as? String ?? ""
            print("Hafas error \(error) \(errTxt)")
            if error == "LOCATION" {
                completion(.invalidId)
            } else if error == "FAIL" || error == "CGI_READ_FAILED" {
                throw ParseError(reason: "cgi read failed")
            } else {
                throw ParseError(reason: "Unknown Hafas error \(error): \(errTxt)")
            }
            return
        } else if apiVersion == "1.10", let svcResJson = encodeJson(dict: svcRes), svcResJson.length == 170 {
            completion(.invalidId)
            return
        }
        guard let res = svcRes["res"] as? [String: Any], let common = res["common"] as? [String: Any], let locList = common["locL"] as? [Any], let opList = common["opL"] as? [Any], let prodList = common["prodL"] as? [Any] else {
            throw ParseError(reason: "could not parse lists")
        }
        
        let locations = try parseLocList(locList: locList)
        let operators = try parseOpList(opList: opList)
        let lines = try parseProdList(prodList: prodList, operators: operators)
        let remList = common["remL"] as? [Any]
        let rems = try parseRemList(remList: remList)
        
        guard let journey = res["journey"] as? [String: Any], let stopL = journey["stopL"] as? [Any], let baseDateString = journey["date"] as? String else {
            throw ParseError(reason: "could not parse journey stop list")
        }
        
        let path: [LocationPoint]
        if let polyline = try? decodePolyline(from: (journey["poly"] as? [String: Any])?["crdEncYX"] as? String) {
            path = polyline
        } else {
            path = []
        }
        
        var dateComponents = DateComponents()
        dateComponents.timeZone = timeZone
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        parseIsoDate(from: baseDateString, dateComponents: &dateComponents)
        guard let baseDate = calendar.date(from: dateComponents) else { throw ParseError(reason: "failed to parse base date") }
        
        guard let prodX = journey["prodX"] as? Int, prodX >= 0 && prodX < lines.count else { throw ParseError(reason: "failed to parse line") }
        let l = lines[prodX]
        
        var message = ""
        var attr: [Line.Attr] = []
        for msg in journey["msgL"] as? [Any] ?? [] {
            guard let msg = msg as? [String: Any], let type = msg["type"] as? String, type == "REM", let remX = msg["remX"] as? Int, remX >= 0 && remX < rems?.count ?? 0, let rem = rems?[remX] else { continue }
            switch rem {
            case .bicycleCarriage:
                attr.append(.bicycleCarriage)
                break
            case .wheelChairAccess:
                attr.append(.wheelChairAccess)
                break
            case .boardRestaurant:
                attr.append(.restaurant)
                break
            case .airConditioned:
                attr.append(.airConditioned)
                break
            case .wifi:
                attr.append(.wifiAvailable)
                break
            case .powerSockets:
                attr.append(.powerSockets)
                break
            case .unknown(let reason):
                if let reason = reason {
                    if message != "" {
                        message += "\n"
                    }
                    message += reason.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !message.hasSuffix(".") && !message.hasSuffix("!") {
                        message += "."
                    }
                }
                break
            default:
                break
            }
        }
        let line: Line
        if !attr.isEmpty {
            line = Line(id: l.id, network: l.network, product: l.product, label: l.label, name: l.name, style: l.style, attr: attr, message: l.message)
        } else {
            line = l
        }
        
        var intermediateStops: [Stop] = []
        for stop in stopL {
            guard let stop = stop as? [String: Any] else { throw ParseError(reason: "failed to parse stop") }
            if let border = stop["border"] as? Bool, border { continue } // hide borders from intermediate stops
            guard let s = try parseStop(dict: stop, locations: locations, rems: rems, baseDate: baseDate, line: line) else { throw ParseError(reason: "failed to parse stop") }
            intermediateStops.append(s)
        }
        
        guard intermediateStops.count >= 2 else { throw ParseError(reason: "failed to parse arr/dep stop") }
        let departure = intermediateStops.removeFirst()
        let arrival = intermediateStops.removeLast()
        if let arrivalMessage = arrival.message {
            if message != "" {
                message += "\n"
            }
            message += arrivalMessage
        }
        
        let destination: Location?
        if let dirTxt = journey["dirTxt"] as? String {
            let nameAndPlace = split(stationName: stripLineFromDestination(line: line, destinationName: dirTxt))
            destination = Location(type: .any, id: nil, coord: nil, place: nameAndPlace.0, name: nameAndPlace.1)
        } else {
            destination = arrival.location
        }
        
        let leg = PublicLeg(line: line, destination: destination, departureStop: departure, arrivalStop: arrival, intermediateStops: intermediateStops, message: !message.isEmpty ? message : nil, path: path, journeyContext: nil)
        let trip = Trip(id: "", from: departure.location, to: arrival.location, legs: [leg], fares: [])
        completion(.success(trip: trip, leg: leg))
    }
    
    // MARK: Request parameters
    
    func jsonTripSearchRequest(from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions, previousContext: Context?, later: Bool) -> [String: Any] {
        let outDate = jsonDate(from: date)
        let outTime = jsonTime(from: date)
        let outFrwdKey = apiVersion == "1.10" ? "frwd" : "outFrwd"
        let outFrwd = departure
        let jnyFltr = productsString(products: tripOptions.products ?? Product.allCases)
        let meta: String
        switch tripOptions.walkSpeed ?? .normal {
        case .slow:
            meta = "foot_speed_slow"
        case .fast:
            meta = "foot_speed_fast"
        case .normal:
            meta = "foot_speed_normal"
        }
        
        var req: [String: Any] = [
            "depLocL": [
                jsonLocation(from: from)
            ],
            "arrLocL": [
                jsonLocation(from: to)
            ],
            "outDate": outDate,
            "outTime": outTime,
            outFrwdKey: outFrwd,
            "gisFltrL": [
                [
                    "mode": "FB",
                    "profile": [
                        "type": "F",
                        "linDistRouting": false,
                        "maxdist": 2000
                    ],
                    "type": "M",
                    "meta": meta
                ]
            ],
            "getPolyline": true,
            "getPasslist": true,
            "extChgTime": -1,
            "trfReq": [
                "jnyCl": 2,
                "cType": "PK",
                "tvlrProf": [[
                    "type": "E"
                    ]]
            ]
        ]
        if let via = via {
            req["viaLocL"] = [["loc": jsonLocation(from: via)]]
        }
        if let previousContext = previousContext, let moreContext = later ? previousContext.laterContext : previousContext.earlierContext {
            req["ctxScr"] = moreContext
        }
        var filterList: [Any] = []
        filterList.append([
            "value": jnyFltr,
            "mode": "BIT",
            "type": "PROD"
            ])
        
        if id == .RMV { // Todo: remove hardcoded to rmv... problem: when removed, we get invalid legs with type Bike and Kiss. When added to other providers, we don't get any results at all...
            filterList.append([
                "type": "GROUP",
                "mode": "INC",
                "value": "GROUP_PT"
                ])
        }
        
        if let accessibility = tripOptions.accessibility, accessibility != .neutral {
            filterList.append([
                "type": "META",
                "mode": "INC",
                "meta": accessibility == .limited ? "limitedBarrierfree" : "completeBarrierfree"
                ])
        }
        if let options = tripOptions.options, options.contains(.bike) {
            filterList.append([
                "type": "BC",
                "mode": "INC"
                ])
        }
        req["jnyFltrL"] = filterList
        if let maxChanges = tripOptions.maxChanges {
            req["maxChg"] = maxChanges
        }
        if let minChangeTime = tripOptions.minChangeTime {
            req["minChgTime"] = minChangeTime
        }
        return req
    }
    
    func wrapJsonApiRequest(meth: String, req: [String: Any], formatted: Bool) -> String? {
        var dict = ["auth": apiAuthorization ?? "", "client": apiClient ?? "", "ver": apiVersion ?? "", "lang": "de", "svcReqL": [["cfg": configJson, "meth": meth, "req": req]], "formatted": formatted]
        if let extVersion = extVersion {
            dict["ext"] = extVersion
        }
        return encodeJson(dict: dict)
    }
    
    // MARK: Response parse methods
    
    func parseJsonTripFare(fareSetName: String, fareSetDescription: String, name: String, currency: String, price: Float) -> Fare? {
        if name.hasSuffix("- Jahreskarte") || name.hasSuffix("- Monatskarte") {
            return nil
        } else if name.hasPrefix("Vollpreis - ") {
            return Fare(network: fareSetName, type: .adult, currency: currency, fare: price, unitsName: name.substring(from: 12), units: nil)
        } else if name.hasPrefix("Kind - ") {
            return Fare(network: fareSetName, type: .child, currency: currency, fare: price, unitsName: name.substring(from: 7), units: nil)
        } else {
            return nil
        }
    }
    
    func parseStop(dict: [String: Any], locations: [Location], rems: [RemAttrib]?, baseDate: Date, line: Line?) throws -> Stop? {
        guard let locationIndex = dict["locX"] as? Int else { throw ParseError(reason: "failed to get stop index") }
        let location = locations[locationIndex]
        
        let arrivalCancelled = dict["isCncl"] as? Bool ?? dict["aCncl"] as? Bool ?? false
        let plannedArrivalTime = try parseJsonTime(baseDate: baseDate, dateString: dict["aTimeS"] as? String)
        let predictedArrivalTime = try parseJsonTime(baseDate: baseDate, dateString: dict["aTimeR"] as? String)
        let plannedArrivalPosition = normalize(position: dict["aPlatfS"] as? String)
        let predictedArrivalPosition = normalize(position: dict["aPlatfR"] as? String)
        
        let departureCancelled = dict["isCncl"] as? Bool ?? dict["dCncl"] as? Bool ?? false
        let plannedDepartureTime = try parseJsonTime(baseDate: baseDate, dateString: dict["dTimeS"] as? String)
        let predictedDepartureTime = try parseJsonTime(baseDate: baseDate, dateString: dict["dTimeR"] as? String)
        let plannedDeparturePosition = normalize(position: dict["dPlatfS"] as? String)
        let predictedDeparturePosition = normalize(position: dict["dPlatfR"] as? String)
        
        var message: String = ""
        for msg in dict["msgL"] as? [Any] ?? [] {
            guard let msg = msg as? [String: Any], let remX = msg["remX"] as? Int, remX >= 0 && remX < rems?.count ?? 0, let rem = rems?[remX] else { continue }
            switch rem {
            case .unknown(let reason):
                if let reason = reason {
                    if message != "" {
                        message += "\n"
                    }
                    message += reason.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !message.hasSuffix(".") && !message.hasSuffix("!") {
                        message += "."
                    }
                }
                break
            case .stopCancelled(let reason):
                if let reason = reason {
                    if message != "" {
                        message += "\n"
                    }
                    message += reason.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !message.hasSuffix(".") && !message.hasSuffix("!") {
                        message += "."
                    }
                }
                break
            default:
                break
            }
        }
        
        let wagonSequenceContext: URL?
        if line?.label?.hasPrefix("ICE") ?? false, let number = line?.number, let plannedArrivalTime = plannedArrivalTime {
            wagonSequenceContext = getWagonSequenceUrl(number: number, plannedTime: plannedArrivalTime)
        } else if line?.label?.hasPrefix("ICE") ?? false, let number = line?.number, let plannedDepartureTime = plannedDepartureTime {
            wagonSequenceContext = getWagonSequenceUrl(number: number, plannedTime: plannedDepartureTime)
        } else {
            wagonSequenceContext = nil
        }
        
        return Stop(location: location, plannedArrivalTime: plannedArrivalTime, predictedArrivalTime: predictedArrivalTime, plannedArrivalPlatform: plannedArrivalPosition, predictedArrivalPlatform: predictedArrivalPosition, arrivalCancelled: arrivalCancelled, plannedDepartureTime: plannedDepartureTime, predictedDepartureTime: predictedDepartureTime, plannedDeparturePlatform: plannedDeparturePosition, predictedDeparturePlatform: predictedDeparturePosition, departureCancelled: departureCancelled, message: !message.isEmpty ? message : nil, wagonSequenceContext: wagonSequenceContext)
    }
    
    func getWagonSequenceUrl(number: String, plannedTime: Date) -> URL? {
        return nil
    }
    
    let P_JSON_TIME = try! NSRegularExpression(pattern: "(\\d{2})?(\\d{2})(\\d{2})(\\d{2})")
    
    func parseJsonTime(baseDate: Date, dateString: String?) throws -> Date? {
        guard let dateString = dateString else { return nil }
        guard let match = dateString.match(pattern: P_JSON_TIME) else { throw ParseError(reason: "failed to parse json time") }
        var date = baseDate
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        if let day = Int(match[0] ?? "") {
            date = calendar.date(byAdding: .day, value: day, to: date) ?? date
        }
        if let hour = Int(match[1] ?? "") {
            date = calendar.date(bySetting: .hour, value: hour, of: date) ?? date
        }
        if let minute = Int(match[2] ?? "") {
            date = calendar.date(bySetting: .minute, value: minute, of: date) ?? date
        }
        if let second = Int(match[3] ?? "") {
            date = calendar.date(bySetting: .second, value: second, of: date) ?? date
        }
        
        return date
    }
    
    func jsonDate(from date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d%02d%02d", components.year!, components.month!, components.day!)
    }
    
    func jsonTime(from date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d%02d00", components.hour!, components.minute!)
    }
    
    func jsonLocation(from location: Location) -> [String: Any] {
        if location.type == .station, let id = location.id {
            if id.hasSuffix("@") {
                return ["type": "S", "lid": id]
            } else {
                return ["type": "S", "extId": id]
            }
        } else if location.type == .address, let id = location.id {
            return ["type": "A", "lid": id]
        } else if location.type == .poi, let id = location.id {
            return ["type": "P", "lid": id]
        } else if let coord = location.coord {
            var result: [String: Any] = ["type": "C", "crd": ["x": coord.lon, "y": coord.lat]]
            if location.name != nil {
                result["name"] = location.getUniqueLongName()
            }
            return result
        } else {
            return [:]
        }
    }
    
    let P_LOCATION_ID_COORDS = try! NSRegularExpression(pattern: ".*@X=(\\d+)@Y=(\\d+)@.*")
    
    func parseLocList(locList: [Any]) throws -> [Location] {
        var locations: [Location] = []
        
        for locElem in locList {
            guard let locElem = locElem as? [String: Any], let type = locElem["type"] as? String else { throw ParseError(reason: "could not parse loc elem") }
            
            let locationType: LocationType
            let id: String?
            let placeAndName: (String?, String?)
            let products: [Product]?
            switch type {
            case "S":
                locationType = .station
                if let lid = locElem["lid"] as? String, lid.hasSuffix("@") {
                    id = normalize(stationId: lid)
                } else {
                    id = normalize(stationId: locElem["extId"] as? String)
                }
                placeAndName = split(stationName: locElem["name"] as? String)
                let pCls = locElem["pCls"] as? Int ?? -1
                products = pCls == -1 ? nil : self.products(from: pCls)
                break
            case "P":
                locationType = .poi
                id = locElem["lid"] as? String
                placeAndName = split(poi: locElem["name"] as? String)
                products = nil
                break
            case "A":
                locationType = .address
                id = locElem["lid"] as? String
                placeAndName = split(address: locElem["name"] as? String)
                products = nil
                break
            default:
                throw ParseError(reason: "unknown loc type \(type)")
            }
            
            let location: Location?
            if let crd = locElem["crd"] as? [String: Any], let lat = crd["y"] as? Int, let lon = crd["x"] as? Int {
                location = Location(type: locationType, id: id, coord: LocationPoint(lat: lat, lon: lon), place: placeAndName.0, name: placeAndName.1, products: products)
            } else {
                if let lid = locElem["lid"] as? String, let match = lid.match(pattern: P_LOCATION_ID_COORDS), let x = Int(match[0] ?? ""), let y = Int(match[1] ?? "") {
                    location = Location(type: locationType, id: id, coord: LocationPoint(lat: y, lon: x), place: placeAndName.0, name: placeAndName.1, products: products)
                } else {
                    location = Location(type: locationType, id: id, coord: nil, place: placeAndName.0, name: placeAndName.1, products: products)
                }
            }
            if let location = location {
                locations.append(location)
            } else {
                throw ParseError(reason: "could not parse location")
            }
        }
        
        return locations
    }
    
    func parseOpList(opList: [Any]) throws -> [String] {
        var operators: [String] = []
        for op in opList {
            guard let op = op as? [String: Any], let name = op["name"] as? String else { throw ParseError(reason: "could not parse operator") }
            operators.append(name)
        }
        return operators
    }
    
    func parseProdList(prodList: [Any], operators: [String]) throws -> [Line] {
        var lines: [Line] = []
        for prod in prodList {
            guard let prod = prod as? [String: Any] else { throw ParseError(reason: "could not parse line") }
            let name = prod["addName"] as? String ?? prod["name"] as? String
            let nameS = prod["nameS"] as? String
            let oprIndex = prod["oprX"] as? Int ?? -1
            let op = oprIndex == -1 ? nil : operators[oprIndex]
            let cls = prod["cls"] as? Int ?? -1
            let product = cls == -1 ? nil : try intToProduct(productInt: cls)
            let number = prod["number"] as? String
            
            lines.append(newLine(network: op, product: product, name: name, shortName: nameS, number: number))
        }
        return lines
    }
    
    func parseRemList(remList: [Any]?) throws -> [RemAttrib]? {
        guard let remList = remList, !remList.isEmpty else { return nil }
        var result: [RemAttrib] = []
        for rem in remList {
            guard let rem = rem as? [String: Any] else {
                throw ParseError(reason: "could not parse rem")
            }
            let txt = String(htmlEncodedString: rem["txtN"] as? String)
            switch (rem["code"] as? String ?? "").lowercased() {
            case "bf":
                result.append(.wheelChairAccess)
                break
            case "rg":
                result.append(.wheelChairAccess)
                break
            case "eh":
                result.append(.wheelChairAccess)
                break
            case "fb":
                result.append(.bicycleCarriage)
                break
            case "bt":
                result.append(.boardRestaurant)
                break
            case "br":
                result.append(.boardRestaurant)
                break
            case "wv":
                result.append(.wifi)
                break
            case "wi":
                result.append(.wifi)
                break
            case "kl":
                result.append(.airConditioned)
                break
            case "ls":
                result.append(.powerSockets)
                break
            default:
                if let type = rem["type"] as? String {
                    if type == "U" {
                        result.append(.stopCancelled(reason: txt))
                    } else if type == "C" || type == "P" {
                        result.append(.cancelled(reason: txt))
                    } else if type == "A" || type == "I" {
                        result.append(.unknown(reason: txt))
                    } else {
                        result.append(.unknown(reason: txt))
                    }
                } else {
                    result.append(.unknown(reason: txt))
                }
                break
            }
        }
        return result
    }
    
    func parseMessageList(himList: [Any]?) throws -> [String]? {
        guard let himList = himList, !himList.isEmpty else { return nil }
        var result: [String] = []
        for him in himList {
            guard let him = him as? [String: Any], var head = him["head"] as? String ?? him["text"] as? String else {
                throw ParseError(reason: "could not parse him")
            }
            while head.hasPrefix(".") {
                head = String(head.dropFirst())
            }
            head = head.trimmingCharacters(in: .whitespacesAndNewlines)
            if !head.hasSuffix(".") && !head.hasSuffix("!") {
                head += "."
            }
            
            if let text = him["lead"] as? String, !text.isEmpty {
                head += "\n"
                head += text.trimmingCharacters(in: .whitespacesAndNewlines)
                if !head.hasSuffix(".") && !head.hasSuffix("!") {
                    head += "."
                }
            }
            result.append(head)
        }
        return result
    }
    
    func newLine(network: String?, product: Product?, name: String?, shortName: String?, number: String?) -> Line {
        let longName: String?
        if let name = name {
            longName = name + (number != nil && !name.hasSuffix(number!) ? "(\(number!))" : "")
        } else if let shortName = shortName {
            longName = shortName + (number != nil && !shortName.hasSuffix(number!) ? "(\(number!))" : "")
        } else {
            longName = number
        }
        
        if product == .bus || product == .tram {
            let label: String?
            if let shortName = shortName {
                label = shortName
            } else if let number = number, let name = name, name.hasSuffix(number) {
                label = number
            } else {
                label = name
            }
            return Line(id: nil, network: network, product: product, label: label, name: longName, number: number, style: lineStyle(network: network, product: product, label: label), attr: nil, message: nil)
        } else {
            var label = name ?? shortName ?? number
            if label?.contains("Zug-Nr.") ?? false, let shortName = shortName, name?.contains(shortName) ?? false {
                label = shortName
            }
            return Line(id: nil, network: network, product: product, label: label?.replacingOccurrences(of: " ", with: ""), name: longName, number: number, style: lineStyle(network: network, product: product, label: name), attr: nil, message: nil)
        }
    }
    
    func decodePolyline(from string: String?) throws -> [LocationPoint] {
        guard let string = string, !string.isEmpty else { return [] }
        var index = string.startIndex
        var lat = 0
        var lng = 0
        var path: [LocationPoint] = []
        
        while index < string.endIndex {
            var b: Int
            var shift = 0
            var result = 0
            repeat {
                b = Int(string[index].asciiValue!) - 63
                index = string.index(after: index)
                result |= (b & 0x1f) << shift
                shift += 5
            } while (b >= 0x20)
            let dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1))
            lat += dlat;
            
            shift = 0;
            result = 0;
            repeat {
                b = Int(string[index].asciiValue!) - 63
                index = string.index(after: index)
                result |= (b & 0x1f) << shift
                shift += 5
            } while (b >= 0x20)
            let dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1))
            lng += dlng
            
            path.append(LocationPoint(lat: lat * 10, lon: lng * 10))
        }
        return path
    }
    
    func encodeJson(dict: [String: Any]) -> String? {
        do {
            return String(data: try JSONSerialization.data(withJSONObject: dict, options: []), encoding: requestUrlEncoding)
        } catch {
            return nil
        }
    }
    
    public class Context: QueryTripsContext {
        
        public override var canQueryEarlier: Bool { return earlierContext != nil }
        public override var canQueryLater: Bool { return laterContext != nil }
        
        public let from: Location
        public let via: Location?
        public let to: Location
        public let date: Date
        public let departure: Bool
        public let laterContext: String?
        public let earlierContext: String?
        public let tripOptions: TripOptions
        
        init(from: Location, via: Location?, to: Location, date: Date, departure: Bool, laterContext: String?, earlierContext: String?, desktopUrl: URL?, tripOptions: TripOptions) {
            self.from = from
            self.via = via
            self.to = to
            self.date = date
            self.departure = departure
            self.laterContext = laterContext
            self.earlierContext = earlierContext
            self.tripOptions = tripOptions
            super.init()
            self.desktopUrl = desktopUrl
        }
        
        public required convenience init?(coder aDecoder: NSCoder) {
            guard
                let from = aDecoder.decodeObject(of: Location.self, forKey: PropertyKey.from),
                let to = aDecoder.decodeObject(of: Location.self, forKey: PropertyKey.to),
                let date = aDecoder.decodeObject(of: NSDate.self, forKey: PropertyKey.date) as Date?,
                let tripOptions = aDecoder.decodeObject(of: TripOptions.self, forKey: PropertyKey.tripOptions)
                else {
                    return nil
            }
            let departure = aDecoder.decodeBool(forKey: PropertyKey.departure)
            let via = aDecoder.decodeObject(of: Location.self, forKey: PropertyKey.via)
            let laterContext = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.laterContext) as String?
            let earlierContext = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.earlierContext) as String?
            
            let url = URL(string: aDecoder.decodeObject(of: NSString.self, forKey: QueryTripsContext.PropertyKey.desktopUrl) as String? ?? "")
            self.init(from: from, via: via, to: to, date: date, departure: departure, laterContext: laterContext, earlierContext: earlierContext, desktopUrl: url, tripOptions: tripOptions)
        }
        
        public override func encode(with aCoder: NSCoder) {
            aCoder.encode(from, forKey: PropertyKey.from)
            aCoder.encode(via, forKey: PropertyKey.via)
            aCoder.encode(to, forKey: PropertyKey.to)
            aCoder.encode(date, forKey: PropertyKey.date)
            aCoder.encode(departure, forKey: PropertyKey.departure)
            aCoder.encode(earlierContext, forKey: PropertyKey.earlierContext)
            aCoder.encode(laterContext, forKey: PropertyKey.laterContext)
            aCoder.encode(desktopUrl?.absoluteString, forKey: QueryTripsContext.PropertyKey.desktopUrl)
            aCoder.encode(tripOptions, forKey: PropertyKey.tripOptions)
        }
        
        struct PropertyKey {
            static let from = "from"
            static let via = "via"
            static let to = "to"
            static let date = "date"
            static let departure = "dep"
            static let laterContext = "laterContext"
            static let earlierContext = "earlierContext"
            static let tripOptions = "tripOptions"
        }
        
    }
    
    enum RemAttrib {
        case wheelChairAccess, bicycleCarriage, boardRestaurant, wifi, powerSockets, airConditioned
        case cancelled(reason: String?)
        case stopCancelled(reason: String?)
        case unknown(reason: String?)
    }
    
    public enum RequestVerification {
        
        case none
        case checksum(salt: String)
        case micMac(salt: String)
        case rnd
        
        func appendParameters(to urlBuilder: UrlBuilder, requestString: String?) {
            guard let requestString = requestString else { return }
            switch self {
            case .checksum(let salt):
                urlBuilder.addParameter(key: "checksum", value: (requestString + salt).md5)
            case .micMac(let salt):
                let requestHash = requestString.md5
                urlBuilder.addParameter(key: "mic", value: requestHash)
                urlBuilder.addParameter(key: "mac", value: (requestHash + salt).md5)
            case .rnd:
                urlBuilder.addParameter(key: "rnd", value: Int(Date().timeIntervalSince1970 * 1000))
            case .none:
                break
            }
        }
    }
    
}

public class HafasClientInterfaceJourneyContext: QueryJourneyDetailContext {
    
    public override class var supportsSecureCoding: Bool { return true }
    
    public let journeyId: String
    
    public init(journeyId: String) {
        self.journeyId = journeyId
        super.init()
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let journeyId = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.journeyId) as String? else { return nil }
        self.init(journeyId: journeyId)
    }
    
    public override func encode(with aCoder: NSCoder) {
        aCoder.encode(journeyId, forKey: PropertyKey.journeyId)
    }
    
    struct PropertyKey {
        
        static let journeyId = "journeyId"
        
    }
}

public class HafasClientInterfaceRefreshTripContext: RefreshTripContext {
    
    public override class var supportsSecureCoding: Bool { return true }
    
    let contextRecon: String
    let from: Location
    let to: Location
    
    init(contextRecon: String, from: Location, to: Location) {
        self.contextRecon = contextRecon
        self.from = from
        self.to = to
        super.init()
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let contextRecon = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.contextRecon) as String?, let from = aDecoder.decodeObject(of: Location.self, forKey: PropertyKey.from), let to = aDecoder.decodeObject(of: Location.self, forKey: PropertyKey.to) else { return nil }
        self.init(contextRecon: contextRecon, from: from, to: to)
    }
    
    public override func encode(with aCoder: NSCoder) {
        aCoder.encode(contextRecon, forKey: PropertyKey.contextRecon)
        aCoder.encode(from, forKey: PropertyKey.from)
        aCoder.encode(to, forKey: PropertyKey.to)
    }
    
    public override var description: String {
        return contextRecon
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? HafasClientInterfaceRefreshTripContext else { return false }
        if self === other { return true }
        return self.contextRecon == other.contextRecon
    }
    
    struct PropertyKey {
        
        static let contextRecon = "contextRecon"
        static let from = "from"
        static let to = "to"
        
    }
    
}

extension Character {
    var asciiValue: UInt32? {
        return unicodeScalars.first?.value
    }
}
