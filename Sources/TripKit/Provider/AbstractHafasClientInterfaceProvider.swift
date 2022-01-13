import Foundation
import os.log

public class AbstractHafasClientInterfaceProvider: AbstractHafasProvider {
    
    override public var supportedQueryTraits: Set<QueryTrait> { [.maxChanges, .minChangeTime, .maxFootpathDist] }
    
    var mgateEndpoint: String
    var apiVersion: String?
    var apiAuthorization: Any?
    var apiClient: Any?
    var extVersion: String?
    var jnyFilterIncludes: [[String: Any]]?
    var requestVerification: RequestVerification = .none
    var configJson: [String: Any] = [:]
    var userAgent: String?
    
    init(networkId: NetworkId, apiBase: String, productsMap: [Product?]) {
        self.mgateEndpoint = apiBase + "mgate.exe"
        super.init(networkId: networkId, productsMap: productsMap)
    }
    
    // MARK: NetworkProvider implementations – Requests
    
    override public func suggestLocations(constraint: String, types: [LocationType]?, maxLocations: Int, completion: @escaping (HttpRequest, SuggestLocationsResult) -> Void) -> AsyncRequest {
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
                        // GVH does not support POI type
                        if self.id != .GVH {
                            type += "P"
                        }
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
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder).setPostPayload(request).setUserAgent(userAgent)
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
    
    override public func queryNearbyLocations(location: Location, types: [LocationType]?, maxDistance: Int, maxLocations: Int, completion: @escaping (HttpRequest, NearbyLocationsResult) -> Void) -> AsyncRequest {
        if let coord = location.coord {
            return jsonLocGeoPos(types: types, lat: coord.lat, lon: coord.lon, maxDistance: maxDistance, maxLocations: maxLocations, completion: completion)
        } else {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .invalidId) // TODO: nearby locations of station id
            return AsyncRequest(task: nil)
        }
    }
    
    func jsonLocGeoPos(types: [LocationType]?, lat: Int, lon: Int, maxDistance: Int, maxLocations: Int, completion: @escaping (HttpRequest, NearbyLocationsResult) -> Void) -> AsyncRequest {
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
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder).setPostPayload(request).setUserAgent(userAgent)
        return HttpClient.get(httpRequest: httpRequest) { result in
            switch result {
            case .success((_, let data)):
                httpRequest.responseData = data
                do {
                    try self.queryNearbyLocationsByCoordinateParsing(request: httpRequest, location: Location(lat: lat, lon: lon), types: types, maxDistance: maxDistance, maxLocations: maxLocations, completion: completion)
                } catch let err as ParseError {
                    os_log("nearbyStations parse error: %{public}@", log: .requestLogger, type: .error, err.reason)
                    completion(httpRequest, .failure(err))
                } catch let err {
                    os_log("nearbyStations handle response error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                    completion(httpRequest, .failure(err))
                }
            case .failure(let err):
                os_log("nearbyStations network error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                completion(httpRequest, .failure(err))
            }
        }
    }
    
    override public func queryDepartures(stationId: String, departures: Bool, time: Date?, maxDepartures: Int, equivs: Bool, completion: @escaping (HttpRequest, QueryDeparturesResult) -> Void) -> AsyncRequest {
        // TODO: extract parameters to method
        let jsonDate = self.jsonDate(from: time ?? Date())
        let jsonTime = self.jsonTime(from: time ?? Date())
        var locJson = jsonLocation(from: Location(id: stationId))
        locJson["state"] = "F"
        var req: [String: Any] = [
            "type": departures ? "DEP" : "ARR",
            "date": jsonDate,
            "time": jsonTime,
            "stbLoc": locJson,
            "maxJny": maxDepartures != 0 ? maxDepartures : 50
        ]
        if let apiVersion = apiVersion, apiVersion.compare("1.19", options: .numeric) == .orderedAscending {
            req["stbFltrEquiv"] = !equivs
            req["getPasslist"] = false
        }
        let request = wrapJsonApiRequest(meth: "StationBoard", req: req, formatted: false)
        let urlBuilder = UrlBuilder(path: mgateEndpoint, encoding: requestUrlEncoding)
        requestVerification.appendParameters(to: urlBuilder, requestString: request)
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder).setPostPayload(request).setUserAgent(userAgent)
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
    
    public override func queryTrips(from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        if from.id == nil && !from.hasLocation() {
            return jsonTripSearchIdentify(location: from) { (request, locations) in
                if locations.count > 1 {
                    completion(request, .ambiguous(ambiguousFrom: locations, ambiguousVia: [], ambiguousTo: []))
                } else if let location = locations.first {
                    let _ = self.queryTrips(from: location, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions, completion: completion)
                } else {
                    completion(request, .unknownFrom)
                }
            }
        } else if let via = via, via.id == nil && !via.hasLocation() {
            return jsonTripSearchIdentify(location: via) { (request, locations) in
                if locations.count > 1 {
                    completion(request, .ambiguous(ambiguousFrom: [], ambiguousVia: locations, ambiguousTo: []))
                } else if let location = locations.first {
                    let _ = self.queryTrips(from: from, via: location, to: to, date: date, departure: departure, tripOptions: tripOptions, completion: completion)
                } else {
                    completion(request, .unknownVia)
                }
            }
        } else if to.id == nil && !to.hasLocation() {
            return jsonTripSearchIdentify(location: to) { (request, locations) in
                if locations.count > 1 {
                    completion(request, .ambiguous(ambiguousFrom: [], ambiguousVia: [], ambiguousTo: locations))
                } else if let location = locations.first {
                    let _ = self.queryTrips(from: from, via: via, to: location, date: date, departure: departure, tripOptions: tripOptions, completion: completion)
                } else {
                    completion(request, .unknownTo)
                }
            }
        } else {
            return doJsonTripSearch(from: from, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions, previousContext: nil, later: false, completion: completion)
        }
    }
    
    func jsonTripSearchIdentify(location: Location, completion: @escaping (HttpRequest, [Location]) -> Void) -> AsyncRequest {
        if let name = location.name {
            return suggestLocations(constraint: [location.place, name].compactMap({$0}).joined(separator: " "), types: [.station], maxLocations: 10) { (request, result) in
                switch result {
                case .success(let locations):
                    completion(request, locations.map({$0.location}))
                case .failure(_):
                    completion(request, [])
                }
            }
        } else if let coord = location.coord {
            return jsonLocGeoPos(types: LocationType.ALL, lat: coord.lat, lon: coord.lon, maxDistance: 0, maxLocations: 0) { (request, result) in
                switch result {
                case .success(let locations):
                    completion(request, locations)
                case .invalidId, .failure(_):
                    completion(request, [])
                }
            }
        } else {
            completion(HttpRequest(urlBuilder: UrlBuilder()), [])
            return AsyncRequest(task: nil)
        }
    }
    
    override public func queryMoreTrips(context: QueryTripsContext, later: Bool, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        guard let context = context as? Context else {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .sessionExpired)
            return AsyncRequest(task: nil)
        }
        return doJsonTripSearch(from: context.from, via: context.via, to: context.to, date: context.date, departure: context.departure, tripOptions: context.tripOptions, previousContext: context, later: later, completion: completion)
    }
    
    func doJsonTripSearch(from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions, previousContext: Context?, later: Bool, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        
        let request = wrapJsonApiRequest(meth: "TripSearch", req: jsonTripSearchRequest(from: from, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions, previousContext: previousContext, later: later), formatted: true)
        let urlBuilder = UrlBuilder(path: mgateEndpoint, encoding: requestUrlEncoding)
        requestVerification.appendParameters(to: urlBuilder, requestString: request)
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder).setPostPayload(request).setUserAgent(userAgent)
        return HttpClient.get(httpRequest: httpRequest) { result in
            switch result {
            case .success((_, let data)):
                httpRequest.responseData = data
                do {
                    try self.queryTripsParsing(request: httpRequest, from: from, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions, previousContext: previousContext, later: later, completion: completion)
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
    
    public override func refreshTrip(context: RefreshTripContext, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        guard let context = context as? HafasClientInterfaceRefreshTripContext else {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .sessionExpired)
            return AsyncRequest(task: nil)
        }
        var req: [String: Any] = ["trfReq": ["jnyCl": 2, "cType": "PK", "tvlrProf": [["type": "E"]]], "getPolyline": true, "getPasslist": true]
        if let apiVersion = apiVersion, apiVersion.compare("1.24", options: .numeric) == .orderedAscending {
            req["ctxRecon"] = context.contextRecon
        } else {
            req["outReconL"] = [["ctx": context.contextRecon]]
        }
        let request = wrapJsonApiRequest(meth: "Reconstruction", req: req, formatted: true)
        let urlBuilder = UrlBuilder(path: mgateEndpoint, encoding: requestUrlEncoding)
        requestVerification.appendParameters(to: urlBuilder, requestString: request)
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder).setPostPayload(request).setUserAgent(userAgent)
        return HttpClient.get(httpRequest: httpRequest) { result in
            switch result {
            case .success((_, let data)):
                httpRequest.responseData = data
                do {
                    try self.refreshTripParsing(request: httpRequest, context: context, completion: completion)
                } catch let err as ParseError {
                    os_log("refreshTrip parse error: %{public}@", log: .requestLogger, type: .error, err.reason)
                    completion(httpRequest, .failure(err))
                } catch let err {
                    os_log("refreshTrip handle response error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                    completion(httpRequest, .failure(err))
                }
            case .failure(let err):
                os_log("refreshTrip network error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                completion(httpRequest, .failure(err))
            }
        }
    }
    
    public override func queryJourneyDetail(context: QueryJourneyDetailContext, completion: @escaping (HttpRequest, QueryJourneyDetailResult) -> Void) -> AsyncRequest {
        guard let context = context as? HafasClientInterfaceJourneyContext else {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .invalidId)
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
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder).setPostPayload(request).setUserAgent(userAgent)
        return HttpClient.get(httpRequest: httpRequest) { result in
            switch result {
            case .success((_, let data)):
                httpRequest.responseData = data
                do {
                    try self.queryJourneyDetailParsing(request: httpRequest, context: context, completion: completion)
                } catch let err as ParseError {
                    os_log("queryJourneyDetail parse error: %{public}@", log: .requestLogger, type: .error, err.reason)
                    completion(httpRequest, .failure(err))
                } catch let err {
                    os_log("queryJourneyDetail handle response error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                    completion(httpRequest, .failure(err))
                }
            case .failure(let err):
                os_log("queryJourneyDetail network error: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                completion(httpRequest, .failure(err))
            }
        }
    }
    
    // MARK: NetworkProvider responses
    
    override func suggestLocationsParsing(request: HttpRequest, constraint: String, types: [LocationType]?, maxLocations: Int, completion: @escaping (HttpRequest, SuggestLocationsResult) -> Void) throws {
        guard let json = try request.responseData?.toJson() as? [String: Any], json["err"] == nil || json["err"] as? String == "OK", let svcResL = json["svcResL"] as? [Any], svcResL.count == 1, let svcRes = svcResL[0] as? [String: Any], let meth = svcRes["meth"] as? String, meth == "LocMatch", let error = svcRes["err"] as? String else {
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
        
        completion(request, .success(locations: suggestedLocations))
    }
    
    override func queryNearbyLocationsByCoordinateParsing(request: HttpRequest, location: Location, types: [LocationType]?, maxDistance: Int, maxLocations: Int, completion: @escaping (HttpRequest, NearbyLocationsResult) -> Void) throws {
        let types = types ?? [.station]
        guard let json = try request.responseData?.toJson() as? [String: Any], json["err"] == nil || json["err"] as? String == "OK", let svcResL = json["svcResL"] as? [Any], svcResL.count == 1, let svcRes = svcResL[0] as? [String: Any], let meth = svcRes["meth"] as? String, meth == "LocGeoPos", let error = svcRes["err"] as? String else {
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
        
        completion(request, .success(locations: locations))
    }
    
    override func queryDeparturesParsing(request: HttpRequest, stationId: String, departures: Bool, time: Date?, maxDepartures: Int, equivs: Bool, completion: @escaping (HttpRequest, QueryDeparturesResult) -> Void) throws {
        guard let json = try request.responseData?.toJson() as? [String: Any], json["err"] == nil || json["err"] as? String == "OK", let svcResL = json["svcResL"] as? [Any], svcResL.count == 1, let svcRes = svcResL[0] as? [String: Any], let meth = svcRes["meth"] as? String, meth == "StationBoard", let err = svcRes["err"] as? String else {
            throw ParseError(reason: "could not parse json")
        }
        if err != "OK" {
            let errTxt = svcRes["errTxt"] as? String ?? ""
            os_log("Received hafas error %{public}@: %{public}@", log: .requestLogger, type: .error, err, errTxt)
            if err == "LOCATION" {
                completion(request, .invalidStation)
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
        }
        guard let res = svcRes["res"] as? [String: Any], let common = res["common"] as? [String: Any], let locList = common["locL"] as? [Any], let opList = common["opL"] as? [Any], let prodList = common["prodL"] as? [Any] else {
            throw ParseError(reason: "could not parse lists")
        }
        if locList.isEmpty {
            // for example GVH: returns no locations when id is invalid
            completion(request, .invalidStation)
            return
        }
        
        let locations = try parseLocList(locList: locList)
        let operators = try parseOpList(opList: opList)
        let lines = try parseProdList(prodList: prodList, operators: operators)
        let remList = common["remL"] as? [Any]
        let rems = try parseRemList(remList: remList)
        let himList = common["himL"] as? [Any]
        let messages = try parseMessageList(himList: himList)
        
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
            
            guard let plannedTime = try parseJsonTime(baseDate: baseDate, dateString: (departures ? stbStop["dTimeS"] : stbStop["aTimeS"]) as? String) else { continue }
            let predictedTime = try parseJsonTime(baseDate: baseDate, dateString: (departures ? stbStop["dTimeR"] : stbStop["aTimeR"]) as? String)
            
            let line = lines[lineIndex]
            
            let location: Location
            if equivs {
                guard let locationIndex = stbStop["locX"] as? Int else { throw ParseError(reason: "could not parse location index") }
                location = locations[locationIndex]
            } else {
                location = Location(type: .station, id: stationId)!
            }
            
            let position = parsePosition(dict: stbStop, platfName: departures ? "dPlatfR" : "aPlatfR", pltfName: departures ? "dPltfR" : "aPltfR")
            let plannedPosition = parsePosition(dict: stbStop, platfName: departures ? "dPlatfS" : "aPlatfS", pltfName: departures ? "dPltfS" : "aPltfS")
            
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
            let (legMessages, _, departureCancelled) = parseLineAttributesAndMessages(jny: jny, rems: rems, messages: messages)
            let message = legMessages.joined(separator: "\n").emptyToNil
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
            if line.label?.hasPrefix("ICE") ?? false, let number = line.number {
                wagonSequenceContext = getWagonSequenceUrl(number: number, plannedTime: plannedTime)
            } else {
                wagonSequenceContext = nil
            }
            let departure = Departure(plannedTime: plannedTime, predictedTime: predictedTime, line: line, position: position, plannedPosition: plannedPosition, destination: destination, capacity: nil, message: message, journeyContext: journeyContext, wagonSequenceContext: wagonSequenceContext)
            
            var stationDepartures = result.first(where: {$0.stopLocation.id == location.id})
            if stationDepartures == nil {
                stationDepartures = StationDepartures(stopLocation: location, departures: [], lines: [])
                result.append(stationDepartures!)
            }
            stationDepartures?.departures.append(departure)
        }
        for stationDeparture in result {
            stationDeparture.departures.sort(by: {$0.time < $1.time})
        }
        
        completion(request, .success(departures: result))
    }
    
    override func queryTripsParsing(request: HttpRequest, from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions, previousContext: QueryTripsContext?, later: Bool, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) throws {
        guard let json = try request.responseData?.toJson() as? [String: Any], json["err"] == nil || json["err"] as? String == "OK", let svcResL = json["svcResL"] as? [Any], svcResL.count == 1, let svcRes = svcResL[0] as? [String: Any], let meth = svcRes["meth"] as? String, meth == "TripSearch" || meth == "Reconstruction", let err = svcRes["err"] as? String else {
            throw ParseError(reason: "could not parse json")
        }
        if err != "OK" {
            let errTxt = svcRes["errTxt"] as? String ?? ""
            os_log("Hafas error %{public}@: %{public}@", log: .requestLogger, type: .error, err, errTxt)
            if err == "H890" { // No connections found.
                completion(request, .noTrips)
            } else if err == "H891" { // No route found (try entering an intermediate station).
                completion(request, .noTrips)
            } else if err == "H892" { // HAFAS Kernel: Request too complex (try entering less intermediate stations).
                completion(request, .noTrips)
            } else if err == "H895" { // Departure/Arrival are too near.
                completion(request, .tooClose)
            } else if err == "H9220" { // Nearby to the given address stations could not be found.
                completion(request, .noTrips)
            } else if err == "H886" { // HAFAS Kernel: No connections found within the requested time interval.
                throw ParseError(reason: "No connections found within the requested time interval.")
            } else if err == "H887" { // HAFAS Kernel: Kernel computation time limit reached.
                throw ParseError(reason: "Kernel computation time limit reached.")
            } else if err == "H9240" { // HAFAS Kernel: Internal error.
                throw ParseError(reason: "Internal error.")
            } else if err == "H9360" { // Date outside of the timetable period.
                completion(request, .invalidDate)
            } else if err == "H9380" { // Departure/Arrival/Intermediate or equivalent stations def'd more than once
                completion(request, .tooClose)
            } else if err == "FAIL" && errTxt == "HCI Service: request failed" {
                throw ParseError(reason: "request failed")
            } else if err == "LOCATION" && errTxt == "HCI Service: location missing or invalid" {
                completion(request, .ambiguous(ambiguousFrom: [], ambiguousVia: [], ambiguousTo: []))
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
        let polyList = common["polyL"] as? [Any]
        let loadFactorList = common["tcocL"] as? [Any]
        
        let locations = try parseLocList(locList: locList)
        let operators = try parseOpList(opList: opList)
        let lines = try parseProdList(prodList: prodList, operators: operators)
        let rems = try parseRemList(remList: remList)
        let messages = try parseMessageList(himList: himList)
        let encodedPolyList = try parsePolyList(polyL: polyList)
        let loadFactors = try parseLoadFactorList(tcocL: loadFactorList)
        let outConL = res["outConL"] as? [Any] ?? []
        if outConL.isEmpty {
            completion(request, .noTrips)
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
                
                switch sec["type"] as? String ?? "" {
                case "JNY", "TETA":
                    guard let jny = sec["jny"] as? [String: Any], let prodX = jny["prodX"] as? Int else { throw ParseError(reason: "failed to parse outcon jny") }
                    let stopL = jny["stopL"] as? [Any]
                    var (legMessages, attrs, cancelled) = parseLineAttributesAndMessages(jny: jny, rems: rems, messages: messages)
                    
                    let l = lines[prodX]
                    let line = Line(id: l.id, network: l.network, product: l.product, label: l.label, name: l.name, number: l.number, vehicleNumber: l.vehicleNumber, style: l.style, attr: attrs, message: l.message)
                    let dirTxt = jny["dirTxt"] as? String
                    let nameAndPlace = split(stationName: stripLineFromDestination(line: line, destinationName: dirTxt))
                    let destination: Location? = dirTxt == nil ? nil : Location(type: .any, id: nil, coord: nil, place: nameAndPlace.0, name: nameAndPlace.1)
                    
                    guard
                        let departureStop = try parseStop(dict: dep, locations: locations, rems: rems, messages: messages, baseDate: baseDate, line: line)?.departure,
                        let arrivalStop = try parseStop(dict: arr, locations: locations, rems: rems, messages: messages, baseDate: baseDate, line: line)?.arrival
                    else {
                        throw ParseError(reason: "failed to parse departure/arrival stop")
                    }
                    if let departureMessage = departureStop.message {
                        legMessages.insert(departureMessage, at: 0)
                    }
                    if let arrivalMessage = arrivalStop.message {
                        legMessages.append(arrivalMessage)
                    }
                    
                    var intermediateStops: [Stop] = []
                    for stop in stopL ?? [] {
                        guard let stop = stop as? [String: Any] else { throw ParseError(reason: "failed to parse jny stop") }
                        if let border = stop["border"] as? Bool, border { continue } // hide borders from intermediate stops
                        guard let intermediateStop = try parseStop(dict: stop, locations: locations, rems: rems, messages: messages, baseDate: baseDate, line: line) else { continue }
                        intermediateStops.append(intermediateStop)
                    }
                    if intermediateStops.count >= 2 {
                        intermediateStops.removeFirst()
                        intermediateStops.removeLast()
                    }
                    
                    let path = parsePath(encodedPolyList: encodedPolyList, jny: jny)
                    
                    if cancelled {
                        intermediateStops.forEach({$0.departure?.cancelled = true; $0.arrival?.cancelled = true})
                    }
                    
                    let journeyContext: HafasClientInterfaceJourneyContext?
                    if let id = jny["jid"] as? String {
                        journeyContext = HafasClientInterfaceJourneyContext(journeyId: id)
                    } else {
                        journeyContext = nil
                    }
                    
                    let loadFactor: LoadFactor?
                    if let dTrnCmpSX = jny["dTrnCmpSX"] as? [String: Any], let tcocXL = dTrnCmpSX["tcocX"] as? [Int] {
                        // TODO: support first class
                        loadFactor = tcocXL.compactMap({ loadFactors?[$0] }).first(where: { $0.cls == "SECOND" })?.loadFactor
                    } else {
                        loadFactor = parseLoadFactorFromRems(jny: jny, rems: rems)
                    }
                    
                    let message = legMessages.joined(separator: "\n").emptyToNil
                    legs.append(PublicLeg(line: line, destination: destination, departure: departureStop, arrival: arrivalStop, intermediateStops: intermediateStops, message: message, path: path, journeyContext: journeyContext, loadFactor: loadFactor))
                case "WALK", "TRSF", "DEVI":
                    guard
                        let departureStop = try parseStop(dict: dep, locations: locations, rems: rems, messages: messages, baseDate: baseDate, line: nil)?.departure,
                        let arrivalStop = try parseStop(dict: arr, locations: locations, rems: rems, messages: messages, baseDate: baseDate, line: nil)?.arrival
                    else {
                        throw ParseError(reason: "failed to parse departure/arrival stop")
                    }
                    let gis = sec["gis"] as? [String: Any]
                    let distance = gis?["distance"] as? Int ?? 0
                    let path = parsePath(encodedPolyList: encodedPolyList, jny: gis)
                    processIndividualLeg(legs: &legs, type: .WALK, departureStop: departureStop, arrivalStop: arrivalStop, distance: distance, path: path)
                case "KISS":
                    guard
                        let departureStop = try parseStop(dict: dep, locations: locations, rems: rems, messages: messages, baseDate: baseDate, line: nil)?.departure,
                        let arrivalStop = try parseStop(dict: arr, locations: locations, rems: rems, messages: messages, baseDate: baseDate, line: nil)?.arrival
                    else {
                        throw ParseError(reason: "failed to parse departure/arrival stop")
                    }
                    let gis = sec["gis"] as? [String: Any]
                    let path = parsePath(encodedPolyList: encodedPolyList, jny: gis)
                    let distance = gis?["distance"] as? Int ?? 0
                    if let mcp = dep["mcp"] as? [String: Any], let mcpData = mcp["mcpData"] as? [String: Any], let provider = mcpData["provider"] as? String, let providerName = mcpData["providerName"] as? String, provider == "berlkoenig" {
                        let line = Line(id: nil, network: nil, product: .onDemand, label: providerName, name: providerName, number: nil, vehicleNumber: nil, style: lineStyle(network: nil, product: .onDemand, label: providerName), attr: nil, message: nil, direction: nil)
                        legs.append(PublicLeg(line: line, destination: arrivalStop.location, departure: departureStop, arrival: arrivalStop, intermediateStops: [], message: nil, path: path, journeyContext: nil, loadFactor: nil))
                    } else {
                        processIndividualLeg(legs: &legs, type: .WALK, departureStop: departureStop, arrivalStop: arrivalStop, distance: distance, path: path)
                    }
                default:
                    throw ParseError(reason: "could not parse outcon sec type \(sec["type"] as? String ?? "")")
                }
            }
            
            let fares = try parseFares(outCon: outCon)
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
        if let previousContext = previousContext as? Context {
            context = Context(from: from, via: via, to: to, date: date, departure: departure, laterContext: later ? res["outCtxScrF"] as? String : previousContext.laterContext, earlierContext: !later ? res["outCtxScrB"] as? String : previousContext.earlierContext, tripOptions: tripOptions)
        } else {
            context = Context(from: from, via: via, to: to, date: date, departure: departure, laterContext: res["outCtxScrF"] as? String, earlierContext: res["outCtxScrB"] as? String, tripOptions: tripOptions)
        }
        completion(request, .success(context: context, from: from, via: via, to: to, trips: trips, messages: []))
    }
    
    override func refreshTripParsing(request: HttpRequest, context: RefreshTripContext, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) throws {
        guard let context = context as? HafasClientInterfaceRefreshTripContext else {
            throw ParseError(reason: "invalid context")
        }
        try self.queryTripsParsing(request: request, from: context.from, via: nil, to: context.to, date: Date(), departure: true, tripOptions: TripOptions(), previousContext: nil, later: false, completion: completion)
    }
    
    override func queryJourneyDetailParsing(request: HttpRequest, context: QueryJourneyDetailContext, completion: @escaping (HttpRequest, QueryJourneyDetailResult) -> Void) throws {
        guard let json = try request.responseData?.toJson() as? [String: Any], json["err"] == nil || json["err"] as? String == "OK", let svcResL = json["svcResL"] as? [Any], svcResL.count == 1, let svcRes = svcResL[0] as? [String: Any], let meth = svcRes["meth"] as? String, meth == "JourneyDetails", let error = svcRes["err"] as? String else {
            throw ParseError(reason: "could not parse json")
        }
        if error != "OK" {
            let errTxt = svcRes["errTxt"] as? String ?? ""
            os_log("Hafas error %{public}@: %{public}@", log: .requestLogger, type: .error, error, errTxt)
            if error == "LOCATION" {
                completion(request, .invalidId)
            } else if error == "FAIL" || error == "CGI_READ_FAILED" {
                throw ParseError(reason: "cgi read failed")
            } else {
                throw ParseError(reason: "Unknown Hafas error \(error): \(errTxt)")
            }
            return
        } else if apiVersion == "1.10", let svcResJson = encodeJson(dict: svcRes), svcResJson.length == 170 {
            completion(request, .invalidId)
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
        let himList = common["himL"] as? [Any]
        let messages = try parseMessageList(himList: himList)
        let polyList = common["polyL"] as? [Any]
        let encodedPolyList = try parsePolyList(polyL: polyList)
        let loadFactorList = common["tcocL"] as? [Any]
        let loadFactors = try parseLoadFactorList(tcocL: loadFactorList)
        
        guard let journey = res["journey"] as? [String: Any], let baseDateString = journey["date"] as? String else {
            throw ParseError(reason: "could not parse journey stop list")
        }
        let stopL = journey["stopL"] as? [Any]
        
        let path = parsePath(encodedPolyList: encodedPolyList, jny: journey)
        
        var dateComponents = DateComponents()
        dateComponents.timeZone = timeZone
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        parseIsoDate(from: baseDateString, dateComponents: &dateComponents)
        guard let baseDate = calendar.date(from: dateComponents) else { throw ParseError(reason: "failed to parse base date") }
        
        guard let prodX = journey["prodX"] as? Int, prodX >= 0 && prodX < lines.count else { throw ParseError(reason: "failed to parse line") }
        let l = lines[prodX]
        
        var (legMessages, attrs, cancelled) = parseLineAttributesAndMessages(jny: journey, rems: rems, messages: messages)
        
        let line = Line(id: l.id, network: l.network, product: l.product, label: l.label, name: l.name, vehicleNumber: l.vehicleNumber, style: l.style, attr: attrs, message: l.message)
        
        var intermediateStops: [Stop] = []
        for stop in stopL ?? [] {
            guard let stop = stop as? [String: Any] else { throw ParseError(reason: "failed to parse stop") }
            if let border = stop["border"] as? Bool, border { continue } // hide borders from intermediate stops
            guard let s = try parseStop(dict: stop, locations: locations, rems: rems, messages: messages, baseDate: baseDate, line: line) else { throw ParseError(reason: "failed to parse stop") }
            intermediateStops.append(s)
        }
        
        guard intermediateStops.count >= 2 else { throw ParseError(reason: "failed to parse arr/dep stop") }
        guard let departure = intermediateStops.removeFirst().departure else { throw ParseError(reason: "failed to parse dep stop") }
        guard let arrival = intermediateStops.removeLast().arrival else { throw ParseError(reason: "failed to parse dep stop") }
        if let departureMessage = departure.message {
            legMessages.insert(departureMessage, at: 0)
        }
        if let arrivalMessage = arrival.message {
            legMessages.append(arrivalMessage)
        }
        
        if cancelled {
            intermediateStops.forEach({$0.departure?.cancelled = true; $0.arrival?.cancelled = true})
        }
        
        let destination: Location?
        if let dirTxt = journey["dirTxt"] as? String {
            let nameAndPlace = split(stationName: stripLineFromDestination(line: line, destinationName: dirTxt))
            destination = Location(type: .any, id: nil, coord: nil, place: nameAndPlace.0, name: nameAndPlace.1)
        } else {
            destination = arrival.location
        }
        
        let loadFactor: LoadFactor?
        if let dTrnCmpSX = journey["dTrnCmpSX"] as? [String: Any], let tcocXL = dTrnCmpSX["tcocX"] as? [Int] {
            // TODO: support first class
            loadFactor = tcocXL.compactMap({ loadFactors?[$0] }).first(where: { $0.cls == "SECOND" })?.loadFactor
        } else {
            loadFactor = parseLoadFactorFromRems(jny: journey, rems: rems)
        }
        
        let message = legMessages.joined(separator: "\n").emptyToNil
        let leg = PublicLeg(line: line, destination: destination, departure: departure, arrival: arrival, intermediateStops: intermediateStops, message: message, path: path, journeyContext: nil, loadFactor: loadFactor)
        let trip = Trip(id: "", from: departure.location, to: arrival.location, legs: [leg], fares: [])
        completion(request, .success(trip: trip, leg: leg))
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
                        "maxdist": tripOptions.maxFootpathDist ?? 2000
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
        var filterList: [[String: Any]] = [["value": jnyFltr, "mode": "BIT", "type": "PROD"]]
        if let jnyFilterIncludes = jnyFilterIncludes {
            filterList.append(contentsOf: jnyFilterIncludes)
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
    
    private func processIndividualLeg(legs: inout [Leg], type: IndividualLeg.`Type`, departureStop: StopEvent, arrivalStop: StopEvent, distance: Int, path: [LocationPoint]) {
        var path = path
        let departureTime = departureStop.predictedTime ?? departureStop.plannedTime
        let arrivalTime = arrivalStop.predictedTime ?? arrivalStop.plannedTime
        let addTime: TimeInterval = !legs.isEmpty ? max(0, -departureTime.timeIntervalSince(legs.last!.maxTime)) : 0
        if let lastLeg = legs.last as? IndividualLeg, lastLeg.type == type {
            legs.removeLast()
            path.insert(contentsOf: lastLeg.path, at: 0)
            legs.append(IndividualLeg(type: lastLeg.type, departureTime: lastLeg.departureTime, departure: lastLeg.departure, arrival: arrivalStop.location, arrivalTime: arrivalTime.addingTimeInterval(addTime), distance: 0, path: path))
        } else {
            legs.append(IndividualLeg(type: type, departureTime: departureTime.addingTimeInterval(addTime), departure: departureStop.location, arrival: arrivalStop.location, arrivalTime: arrivalTime.addingTimeInterval(addTime), distance: distance, path: path))
        }
    }
    
    func parsePosition(dict: [String: Any], platfName: String, pltfName: String) -> String? {
        if let pltfDic = dict[pltfName] as? [String: Any], let pltf = pltfDic["txt"] as? String, !pltf.isEmpty {
            return pltf
        } else if let platf = dict[platfName] as? String, !platf.isEmpty {
            return normalize(position: platf)
        } else {
            return nil
        }
    }
    
    func parseStop(dict: [String: Any], locations: [Location], rems: [RemAttrib]?, messages: [String]?, baseDate: Date, line: Line?) throws -> Stop? {
        guard let locationIndex = dict["locX"] as? Int else { throw ParseError(reason: "failed to get stop index") }
        let location = locations[locationIndex]
        
        let arrivalCancelled = dict["isCncl"] as? Bool ?? dict["aCncl"] as? Bool ?? false
        let plannedArrivalTime = try parseJsonTime(baseDate: baseDate, dateString: dict["aTimeS"] as? String)
        let predictedArrivalTime = try parseJsonTime(baseDate: baseDate, dateString: dict["aTimeR"] as? String)
        let plannedArrivalPosition = parsePosition(dict: dict, platfName: "aPlatfS", pltfName: "aPltfS")
        let predictedArrivalPosition = parsePosition(dict: dict, platfName: "aPlatfR", pltfName: "aPltfR")
        
        let departureCancelled = dict["isCncl"] as? Bool ?? dict["dCncl"] as? Bool ?? false
        let plannedDepartureTime = try parseJsonTime(baseDate: baseDate, dateString: dict["dTimeS"] as? String)
        let predictedDepartureTime = try parseJsonTime(baseDate: baseDate, dateString: dict["dTimeR"] as? String)
        let plannedDeparturePosition = parsePosition(dict: dict, platfName: "dPlatfS", pltfName: "dPltfS")
        let predictedDeparturePosition = parsePosition(dict: dict, platfName: "dPlatfR", pltfName: "dPltfR")
        
        let (legMessages, _, _) = parseLineAttributesAndMessages(jny: dict, rems: rems, messages: messages)
        let message = legMessages.joined(separator: "\n").emptyToNil
        
        let wagonSequenceContext: URL?
        if line?.label?.hasPrefix("ICE") ?? false, let number = line?.number, let plannedArrivalTime = plannedArrivalTime {
            wagonSequenceContext = getWagonSequenceUrl(number: number, plannedTime: plannedArrivalTime)
        } else if line?.label?.hasPrefix("ICE") ?? false, let number = line?.number, let plannedDepartureTime = plannedDepartureTime {
            wagonSequenceContext = getWagonSequenceUrl(number: number, plannedTime: plannedDepartureTime)
        } else {
            wagonSequenceContext = nil
        }
        
        let departure: StopEvent?
        if let plannedDepartureTime = plannedDepartureTime {
            departure = StopEvent(location: location, plannedTime: plannedDepartureTime, predictedTime: predictedDepartureTime, plannedPlatform: plannedDeparturePosition, predictedPlatform: predictedDeparturePosition, cancelled: departureCancelled)
        } else {
            departure = nil
        }
        
        let arrival: StopEvent?
        if let plannedArrivalTime = plannedArrivalTime {
            arrival = StopEvent(location: location, plannedTime: plannedArrivalTime, predictedTime: predictedArrivalTime, plannedPlatform: plannedArrivalPosition, predictedPlatform: predictedArrivalPosition, cancelled: arrivalCancelled)
        } else {
            arrival = nil
        }
        
        return Stop(location: location, departure: departure, arrival: arrival, message: message, wagonSequenceContext: wagonSequenceContext)
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
            guard let locElem = locElem as? [String: Any] else { throw ParseError(reason: "could not parse loc elem") }
            // currently, DB receives some illegal locations without any associated type
            // ignore these locations instead of throwing an error
            guard let type = locElem["type"] as? String else { continue }
            
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
            case "C":
                locationType = .coord
                id = nil
                placeAndName = (nil, nil)
                products = nil
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

            let prodCtx = prod["prodCtx"] as? [String: Any]
            var vehicleNumber = prodCtx?["num"] as? String
            if number != nil && vehicleNumber == number {
                vehicleNumber = nil;
            }

            lines.append(newLine(network: op, product: product, name: name, shortName: nameS, number: number, vehicleNumber: vehicleNumber))
        }
        return lines
    }
    
    func parseRemList(remList: [Any]?) throws -> [RemAttrib]? {
        guard let remList = remList, !remList.isEmpty else { return nil }
        var result: [RemAttrib] = []
        for rem in remList {
            let rem = rem as? [String: Any]
            let type = rem?["type"] as? String
            let code = rem?["code"] as? String
            let txtN = rem?["txtN"] as? String
            result.append(RemAttrib(type: type, code: code, txtN: txtN))
        }
        return result
    }
    
    private func parseLineAttributesAndMessages(jny: [String: Any], rems: [RemAttrib]?, messages: [String]?) -> (legMessages: [String], lineAttrs: [Line.Attr]?, cancelled: Bool) {
        var attrs: [Line.Attr]?
        var legMessages: [String] = []
        var cancelled = jny["isCncl"] as? Bool ?? false
        if let remL = jny["remL"] as? [Any] ?? jny["msgL"] as? [Any] {
            var result = Set<Line.Attr>()
            for jsonRem in remL {
                guard let jsonRem = jsonRem as? [String: Any] else { continue }
                if jsonRem["type"] as? String == "REM", let remX = jsonRem["remX"] as? Int, let rem = rems?[remX] {
                    switch (rem.code ?? "").lowercased() {
                    case "bf", "rg", "eh", "bg", "op", "be", "re":
                        result.insert(.wheelChairAccess)
                    case "fb", "fk", "g ":
                        result.insert(.bicycleCarriage)
                    case "bt", "br":
                        result.insert(.restaurant)
                    case "wv", "wi":
                        result.insert(.wifiAvailable)
                    case "kl", "rc":
                        result.insert(.airConditioned)
                    case "ls", "ri":
                        result.insert(.powerSockets)
                    case "ck": // Komfort Check-in
                        break
                    case "pf", "pb": // Maskenpflicht
                        break
                    case "3g", "co": // 3G-Regel
                        break
                    case "operator", "df", "ay", "nw", "kc", "al", "cy": // line operator
                        break
                    case "hm": // RB 20: die euregiobahn
                        break
                    case "journeynumber", "pname": // line number
                        break
                    case _ where (rem.code ?? "").lowercased().hasPrefix("text.occup"): // load factor
                        break
                    case "text.realtime.journey.missed.connection", "text.realtime.connection.brokentrip":
                        break
                    case "bb": // station information
                        break
                    case "ao": // no alcoholic drinks allowed
                        break
                    default:
                        guard let txt = rem.txtN?.stripHTMLTags() else { continue }
                        switch rem.type ?? "" {
                        case "U", "C", "P":
                            legMessages.append(txt)
                            cancelled = true
                        case "A", "I":
                            switch txt.lowercased() {
                            case "bordrestaurant":
                                result.insert(.restaurant)
                            case "fahrradmitnahme begrenzt möglich", "fahrradmitnahme möglich", "fahrradmitnahme reservierungspflichtig":
                                result.insert(.bicycleCarriage)
                            case "fahrzeuggebundene einstiegshilfe", "zugang für rollstuhlfahrer", "niederflurbus mit rampe", "behindertengerechtes fahrzeug":
                                result.insert(.wheelChairAccess)
                            case _ where txt.lowercased().contains("rollstuhlstellplatz"):
                                result.insert(.wheelChairAccess)
                            case _ where txt.lowercased().contains("niederflurfahrzeug"):
                                result.insert(.wheelChairAccess)
                            case "wlan verfügbar":
                                result.insert(.wifiAvailable)
                            default:
                                legMessages.append(txt)
                            }
                        default:
                            legMessages.append(txt)
                        }
                    }
                } else if jsonRem["type"] as? String == "HIM", let himX = jsonRem["himX"] as? Int {
                    guard himX >= 0 && himX < messages?.count ?? 0, let text = messages?[himX] else { continue }
                    legMessages.append(text)
                }
            }
            attrs = result.isEmpty ? nil : Array(result)
        } else {
            attrs = nil
        }
        if let himL = jny["himL"] as? [Any] {
            for him in himL {
                guard let him = him as? [String: Any], let himX = him["himX"] as? Int else { continue }
                guard let text = messages?[himX] else { continue }
                legMessages.append(text)
            }
        }
        // please, please continue to wear a mask, even if the app doesn't nag you about it anymore
        legMessages = legMessages.filter({!$0.lowercased().contains("ffp") && !$0.lowercased().contains("maskenpflicht") && !$0.lowercased().contains("\"3g-pflicht\"") && !$0.lowercased().contains("corona-präventionsmaßnahme")})
        legMessages = legMessages.map({ $0.ensurePunctuation })
        return (legMessages.uniqued(), attrs, cancelled)
    }
    
    func parseLoadFactorFromRems(jny: [String: Any], rems: [RemAttrib]?) -> LoadFactor? {
        if let remL = jny["remL"] as? [Any] ?? jny["msgL"] as? [Any] {
            for jsonRem in remL {
                guard let jsonRem = jsonRem as? [String: Any] else { continue }
                if jsonRem["type"] as? String == "REM", let remX = jsonRem["remX"] as? Int, let rem = rems?[remX] {
                    switch (rem.code ?? "").lowercased() {
                    case "text.occup.jny.2nd.11":
                        return .low
                    case "text.occup.jny.2nd.12":
                        return .medium
                    case "text.occup.jny.2nd.13":
                        return .high
                    default:
                        break
                    }
                }
            }
        }
        return nil
    }
    
    func parseMessageList(himList: [Any]?) throws -> [String]? {
        guard let himList = himList, !himList.isEmpty else { return nil }
        var result: [String] = []
        for him in himList {
            guard let him = him as? [String: Any], var head = him["head"] as? String ?? him["text"] as? String else {
                result.append("")
                continue
            }
            while head.hasPrefix(".") {
                head = String(head.dropFirst())
            }
            head = head.ensurePunctuation
            
            if let text = him["lead"] as? String, !text.isEmpty {
                if !head.isEmpty {
                    head += "\n"
                }
                head += text.ensurePunctuation
            }
            result.append(head)
        }
        return result
    }
    
    private func parsePolyList(polyL: [Any]?) throws -> [String]? {
        guard let polyL = polyL as? [[String: Any]] else { return nil }
        var result: [String] = []
        for poly in polyL {
            guard let coords = poly["crdEncYX"] as? String else { throw ParseError(reason: "failed to parse poly list") }
            result.append(coords)
        }
        return result
    }
    
    private func parseLoadFactorList(tcocL: [Any]?) throws -> [(cls: String, loadFactor: LoadFactor?)]? {
        guard let tcocL = tcocL as? [[String: Any]] else {
            return nil
        }
        var result: [(String, LoadFactor?)] = []
        for tcoc in tcocL {
            guard let cls = tcoc["c"] as? String else { throw ParseError(reason: "failed to parse load factor") }
            let loadFactor = LoadFactor(rawValue: tcoc["r"] as? Int ?? 0)
            result.append((cls, loadFactor))
        }
        return result
    }
    
    private func parsePath(encodedPolyList: [String]?, jny: [String: Any]?) -> [LocationPoint] {
        let path: [LocationPoint]
        if let coords = (jny?["poly"] as? [String: Any])?["crdEncYX"] as? String, let polyline = try? decodePolyline(from: coords) {
            path = polyline
        } else if let polyG = jny?["polyG"] as? [String: Any], let polyXL = polyG["polyXL"] as? [Int], let polyX = polyXL.first, let polyline = try? decodePolyline(from: encodedPolyList?[polyX]) {
            path = polyline
        } else {
            path = []
        }
        return path
    }
    
    private func parseFares(outCon: [String: Any]) throws -> [Fare] {
        var fares: [Fare] = []
        
        guard let trfRes = outCon["trfRes"] as? [String: Any], let fareSetList = trfRes["fareSetL"] as? [[String: Any]] else { return fares }
        
        let ovwTrfRefList = outCon["ovwTrfRefL"] as? [[String: Any]] ?? []
        // iterate over all fare sets, fares and tickets
        // if ovwTrfRefList is not empty, only try add fares from this list, else add all fares
        for (fareSetX, jsonFareSet) in fareSetList.enumerated() {
            guard ovwTrfRefList.isEmpty || ovwTrfRefList.contains(where: { ovwTrfRef in
                return (ovwTrfRef["fareSetX"] == nil || ovwTrfRef["fareSetX"] as? Int == fareSetX)
            }) else { continue }
            
            guard let fareList = jsonFareSet["fareL"] as? [[String: Any]] else { continue }
            for (fareX, jsonFare) in fareList.enumerated() {
                guard ovwTrfRefList.isEmpty || ovwTrfRefList.contains(where: { ovwTrfRef in
                    return (ovwTrfRef["fareSetX"] == nil || ovwTrfRef["fareSetX"] as? Int == fareSetX)
                        && (ovwTrfRef["fareX"] == nil || ovwTrfRef["fareX"] as? Int == fareX)
                }) else { continue }
                
                let fareName = jsonFare["name"] as? String ?? jsonFare["desc"] as? String
                
                if let ticketList = jsonFare["ticketL"] as? [[String: Any]] {
                    for (ticketX, jsonTicket) in ticketList.enumerated() {
                        guard ovwTrfRefList.isEmpty || ovwTrfRefList.contains(where: { ovwTrfRef in
                            return (ovwTrfRef["fareSetX"] == nil || ovwTrfRef["fareSetX"] as? Int == fareSetX)
                                && (ovwTrfRef["fareX"] == nil || ovwTrfRef["fareX"] as? Int == fareX)
                                && (ovwTrfRef["ticketX"] == nil || ovwTrfRef["ticketX"] as? Int == ticketX)
                        }) else { continue }
                        
                        if let fare = parseTicket(fareName: fareName, jsonTicket: jsonTicket), !hideFare(fare) {
                            fares.append(fare)
                        }
                    }
                } else {
                    if let fare = parseFare(jsonFare: jsonFare), !hideFare(fare) {
                        fares.append(fare)
                    }
                }
            }
        }
        
        return fares
    }
    
    private func parseFare(jsonFare: [String: Any]) -> Fare? {
        guard
            let price = jsonFare["prc"] as? Int, price > 0
        else {
            return nil
        }
        let desc = jsonFare["desc"] as? String
        let fareName = jsonFare["name"] as? String ?? desc
        let currency = jsonFare["cur"] as? String ?? "EUR"
        let name = parse(fareName: fareName, ticketName: nil)
        let fareType = normalize(fareType: fareName ?? "") ?? normalize(fareType: desc ?? "") ?? .adult
        return Fare(name: name.emptyToNil, type: fareType, currency: currency, fare: Float(price) / Float(100), unitsName: nil, units: nil)
    }
    
    private func parseTicket(fareName: String?, jsonTicket: [String: Any]) -> Fare? {
        guard
            let price = jsonTicket["prc"] as? Int, price > 0
        else {
            return nil
        }
        let ticketName = jsonTicket["name"] as? String
        let currency = jsonTicket["cur"] as? String ?? "EUR"
        let name = parse(fareName: fareName, ticketName: ticketName)
        let fareType = normalize(fareType: fareName ?? "") ?? normalize(fareType: ticketName ?? "") ?? normalize(fareType: jsonTicket["desc"] as? String ?? "") ?? .adult
        return Fare(name: name.emptyToNil, type: fareType, currency: currency, fare: Float(price) / Float(100), unitsName: nil, units: nil)
    }
    
    func normalize(fareType: String) -> Fare.FareType? {
        let fareNameLc = fareType.lowercased()
        switch fareNameLc {
        case let name where name.contains("erwachsene"): return .adult
        case let name where name.contains("adult"): return .adult
        case let name where name.contains("kind"): return .child
        case let name where name.contains("child"): return .child
        case let name where name.contains("kids"): return .child
        case let name where name.contains("ermäßigung"): return .child
        case let name where name.contains("schüler"): return .student
        case let name where name.contains("azubi"): return .student
        case let name where name.contains("fahrrad"): return .bike
        default: return nil
        }
    }

    func parse(fareName: String?, ticketName: String?) -> String {
        return [fareName, ticketName].compactMap { str in
            str?.replacingOccurrences(of: "\n", with: " ")
        }.joined(separator: " ")
    }

    func hideFare(_ fare: Fare) -> Bool {
        let fareNameLc = fare.name?.lowercased() ?? ""
        switch fareNameLc {
        case let name where name.contains("tageskarte"): return true
        case let name where name.contains("tagesticket"): return true
        case let name where name.contains("monatskarte"): return true
        case let name where name.contains("monatsticket"): return true
        case let name where name.contains("jahreskarte"): return true
        case let name where name.contains("jahresticket"): return true
        case let name where name.contains("netzkarte"): return true
        case let name where name.contains("abo"): return true
        case let name where name.contains("2er"): return true
        case let name where name.contains("3er"): return true
        case let name where name.contains("4er"): return true
        case let name where name.contains("5er"): return true
        case let name where name.contains("6er"): return true
        case let name where name.contains("2 personen"): return true
        case let name where name.contains("3 personen"): return true
        case let name where name.contains("4 personen"): return true
        case let name where name.contains("5 personen"): return true
        case let name where name.contains("6 personen"): return true
        case let name where name.contains("2 adults"): return true
        case let name where name.contains("3 adults"): return true
        case let name where name.contains("4 adults"): return true
        case let name where name.contains("5 adults"): return true
        case let name where name.contains("6 adults"): return true
        default: return false
        }
    }
    
    func newLine(network: String?, product: Product?, name: String?, shortName: String?, number: String?, vehicleNumber: String?) -> Line {
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
            return Line(id: nil, network: network, product: product, label: label?.replacingOccurrences(of: " ", with: ""), name: longName, number: number, vehicleNumber: vehicleNumber, style: lineStyle(network: network, product: product, label: name), attr: nil, message: nil)
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
        
        init(from: Location, via: Location?, to: Location, date: Date, departure: Bool, laterContext: String?, earlierContext: String?, tripOptions: TripOptions) {
            self.from = from
            self.via = via
            self.to = to
            self.date = date
            self.departure = departure
            self.laterContext = laterContext
            self.earlierContext = earlierContext
            self.tripOptions = tripOptions
            super.init()
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
            
            self.init(from: from, via: via, to: to, date: date, departure: departure, laterContext: laterContext, earlierContext: earlierContext, tripOptions: tripOptions)
        }
        
        public override func encode(with aCoder: NSCoder) {
            aCoder.encode(from, forKey: PropertyKey.from)
            aCoder.encode(via, forKey: PropertyKey.via)
            aCoder.encode(to, forKey: PropertyKey.to)
            aCoder.encode(date, forKey: PropertyKey.date)
            aCoder.encode(departure, forKey: PropertyKey.departure)
            aCoder.encode(earlierContext, forKey: PropertyKey.earlierContext)
            aCoder.encode(laterContext, forKey: PropertyKey.laterContext)
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
    
    struct RemAttrib {
        let type: String?
        let code: String?
        let txtN: String?
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
                urlBuilder.addParameter(key: "rnd", value: Date().timeIntervalSince1970)
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
