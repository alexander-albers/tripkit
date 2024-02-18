import Foundation
import os.log
import SwiftyJSON

public class AbstractHafasClientInterfaceProvider: AbstractHafasProvider {
    
    public override var supportedQueryTraits: Set<QueryTrait> { [.maxChanges, .minChangeTime, .maxFootpathDist, .tariffClass] }
    
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
        // TODO: extract parameters to method
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
        let request = wrapJsonApiRequest(
            meth: "LocMatch",
            req: [
                "input": [
                    "field": "S",
                    "loc": ["name": constraint + "?", "type": type],
                    "maxLoc": maxLocations > 0 ? maxLocations : 50
                ] as [String : Any]
            ],
            formatted: true
        )
        let urlBuilder = UrlBuilder(path: mgateEndpoint, encoding: requestUrlEncoding)
        requestVerification.appendParameters(to: urlBuilder, requestString: request)
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder).setPostPayload(request).setUserAgent(userAgent)
        return makeRequest(httpRequest) {
            try self.suggestLocationsParsing(request: httpRequest, constraint: constraint, types: types, maxLocations: maxLocations, completion: completion)
        } errorHandler: { err in
            completion(httpRequest, .failure(err))
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
        var req: [String: Any] = ["ring": ring]
        if let types = types, types.contains(.poi) || types.contains(.any) {
            req["getPOIs"] = true
        } else {
            req["getPOIs"] = false
        }
        if let types = types {
            req["getStops"] = types.contains(.station) || types.contains(.any)
        } else {
            req["getStops"] = true
        }
        if maxLocations > 0 {
            req["maxLoc"] = maxLocations
        } else {
            req["maxLoc"] = 50
        }
        let request = wrapJsonApiRequest(meth: "LocGeoPos", req: req, formatted: false)
        let urlBuilder = UrlBuilder(path: mgateEndpoint, encoding: requestUrlEncoding)
        requestVerification.appendParameters(to: urlBuilder, requestString: request)
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder).setPostPayload(request).setUserAgent(userAgent)
        return makeRequest(httpRequest) {
            try self.queryNearbyLocationsByCoordinateParsing(request: httpRequest, location: Location(lat: lat, lon: lon), types: types, maxDistance: maxDistance, maxLocations: maxLocations, completion: completion)
        } errorHandler: { err in
            completion(httpRequest, .failure(err))
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
        if let apiVersion = apiVersion, apiVersion.isSmallerVersionThan("1.19") {
            req["stbFltrEquiv"] = !equivs
            req["getPasslist"] = false
        }
        let request = wrapJsonApiRequest(meth: "StationBoard", req: req, formatted: false)
        let urlBuilder = UrlBuilder(path: mgateEndpoint, encoding: requestUrlEncoding)
        requestVerification.appendParameters(to: urlBuilder, requestString: request)
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder).setPostPayload(request).setUserAgent(userAgent)
        return makeRequest(httpRequest) {
            try self.queryDeparturesParsing(request: httpRequest, stationId: stationId, departures: departures, time: time, maxDepartures: maxDepartures, equivs: equivs, completion: completion)
        } errorHandler: { err in
            completion(httpRequest, .failure(err))
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
            return suggestLocations(constraint: [location.place, name].compactMap({$0}).joined(separator: " "), types: [.any], maxLocations: 10) { (request, result) in
                switch result {
                case .success(let locations):
                    completion(request, locations.map({$0.location}))
                case .failure(_):
                    completion(request, [])
                }
            }
        } else if let coord = location.coord {
            return jsonLocGeoPos(types: [.any], lat: coord.lat, lon: coord.lon, maxDistance: 0, maxLocations: 0) { (request, result) in
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
        return makeRequest(httpRequest) {
            try self.queryTripsParsing(request: httpRequest, from: from, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions, previousContext: previousContext, later: later, completion: completion)
        } errorHandler: { err in
            completion(httpRequest, .failure(err))
        }
    }
    
    public override func refreshTrip(context: RefreshTripContext, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        guard let context = context as? HafasClientInterfaceRefreshTripContext else {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .sessionExpired)
            return AsyncRequest(task: nil)
        }
        var req: [String: Any] = [
            "trfReq": [
                "jnyCl": 2,
                "cType": "PK",
                "tvlrProf": [["type": "E"]]
            ] as [String : Any],
            "getPolyline": true,
            "getPasslist": true
        ]
        if let apiVersion = apiVersion, apiVersion.isSmallerVersionThan("1.24") {
            req["ctxRecon"] = context.contextRecon
        } else {
            req["outReconL"] = [["ctx": context.contextRecon]]
        }
        let request = wrapJsonApiRequest(meth: "Reconstruction", req: req, formatted: true)
        let urlBuilder = UrlBuilder(path: mgateEndpoint, encoding: requestUrlEncoding)
        requestVerification.appendParameters(to: urlBuilder, requestString: request)
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder).setPostPayload(request).setUserAgent(userAgent)
        return makeRequest(httpRequest) {
            try self.refreshTripParsing(request: httpRequest, context: context, completion: completion)
        } errorHandler: { err in
            completion(httpRequest, .failure(err))
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
        return makeRequest(httpRequest) {
            try self.queryJourneyDetailParsing(request: httpRequest, context: context, completion: completion)
        } errorHandler: { err in
            completion(httpRequest, .failure(err))
        }
    }
    
    // MARK: NetworkProvider responses
    
    override func suggestLocationsParsing(request: HttpRequest, constraint: String, types: [LocationType]?, maxLocations: Int, completion: @escaping (HttpRequest, SuggestLocationsResult) -> Void) throws {
        let svcRes = try validateResponse(with: request.responseData, requiredMethod: "LocMatch")
        if let error = svcRes["err"].string, error != "OK" {
            throw ParseError(reason: svcRes["errTxt"].string ?? error)
        }
        
        let locList = svcRes["res", "match", "locL"]
        let locations = try parseLocList(locList: locList, throwErrors: false)
        let suggestedLocations = locations.map({SuggestedLocation(location: $0, priority: 0)})
        
        completion(request, .success(locations: suggestedLocations))
    }
    
    override func queryNearbyLocationsByCoordinateParsing(request: HttpRequest, location: Location, types: [LocationType]?, maxDistance: Int, maxLocations: Int, completion: @escaping (HttpRequest, NearbyLocationsResult) -> Void) throws {
        let types = types ?? [.station]
        let svcRes = try validateResponse(with: request.responseData, requiredMethod: "LocGeoPos")
        if let error = svcRes["err"].string, error != "OK" {
            throw ParseError(reason: svcRes["errTxt"].string ?? error)
        }
        
        let locList = svcRes["res", "locL"]
        let locations = try parseLocList(locList: locList, throwErrors: false).filter({types.contains($0.type)})
        
        completion(request, .success(locations: locations))
    }
    
    override func queryDeparturesParsing(request: HttpRequest, stationId: String, departures: Bool, time: Date?, maxDepartures: Int, equivs: Bool, completion: @escaping (HttpRequest, QueryDeparturesResult) -> Void) throws {
        let svcRes = try validateResponse(with: request.responseData, requiredMethod: "StationBoard")
        if let error = svcRes["err"].string, error != "OK" {
            if error == "LOCATION" {
                completion(request, .invalidStation)
                return
            } else {
                throw ParseError(reason: svcRes["errTxt"].string ?? error)
            }
        }
        
        let common = svcRes["res", "common"]
        let locList = common["locL"]
        let prodList = common["prodL"]
        let opList = common["opL"]
        let remList = common["remL"]
        let himList = common["himL"]
        if locList.arrayValue.isEmpty {
            // for example GVH: returns no locations when id is invalid
            completion(request, .invalidStation)
            return
        }
        
        let locations = try parseLocList(locList: locList)
        let operators = try parseOpList(opList: opList)
        let lines = try parseProdList(prodList: prodList, operators: operators)
        let rems = try parseRemList(remList: remList)
        let messages = try parseMessageList(himList: himList)
        
        var result: [StationDepartures] = []
        for jny in svcRes["res", "jnyL"].arrayValue {
            let stbStop = jny["stbStop"]
            let cancelled = jny["dCncl"].boolValue || !(jny["isRchbl"].bool ?? true)
            
            // Parse platform
            let position = parsePosition(json: stbStop, platfName: departures ? "dPlatfR" : "aPlatfR", pltfName: departures ? "dPltfR" : "aPltfR")
            let plannedPosition = parsePosition(json: stbStop, platfName: departures ? "dPlatfS" : "aPlatfS", pltfName: departures ? "dPltfS" : "aPltfS")
            
            // Parse departure/arrival times
            let baseDate = try parseBaseDate(from: jny["date"].stringValue)
            guard let plannedTime = try parseJsonTime(baseDate: baseDate, dateString: (departures ? stbStop["dTimeS"] : stbStop["aTimeS"]).string) else { continue }
            let predictedTime = try parseJsonTime(baseDate: baseDate, dateString: (departures ? stbStop["dTimeR"] : stbStop["aTimeR"]).string)
            
            // Parse line
            guard var line = lines[safe: (departures ? stbStop["dProdX"] : stbStop["aProdX"]).int] else {
                throw ParseError(reason: "could not parse line")
            }
            
            // Line direction
            let direction: Line.Direction?
            switch jny["dirFlg"].stringValue {
            case "1": direction = .return
            case "2": direction = .outward
            default: direction = nil
            }
            line = Line(id: line.id, network: line.network, product: line.product, label: line.label, name: line.name, number: line.number, vehicleNumber: line.vehicleNumber, style: line.style, attr: line.attr, message: line.message, direction: direction)
            
            // Parse location
            guard let location = locations[safe: stbStop["locX"].int], location.type == .station else {
                throw ParseError(reason: "could not parse location")
            }
            
            // Parse destination
            let jnyDirTxt = jny["dirTxt"].string
            let destination: Location?
            if let stopL = jny["stopL"].array {
                guard let lastIndex = stopL.last?["locX"].int, let name = locList[lastIndex, "name"].string else {
                    throw ParseError(reason: "could not parse stop destination list")
                }
                if jnyDirTxt == name, let dest = locations[safe: lastIndex] {
                    destination = dest
                } else {
                    let nameAndPlace = split(stationName: stripLineFromDestination(line: line, destinationName: jnyDirTxt))
                    destination = Location(type: .any, id: nil, coord: nil, place: nameAndPlace.0, name: nameAndPlace.1)
                }
            } else if let jnyDirTxt = jny["dirTxt"].string {
                let nameAndPlace = split(stationName: stripLineFromDestination(line: line, destinationName: jnyDirTxt))
                destination = Location(type: .any, id: nil, coord: nil, place: nameAndPlace.0, name: nameAndPlace.1)
            } else {
                destination = nil
            }
            
            // Parse remarks
            let (legMessages, _, departureCancelled) = parseLineAttributesAndMessages(jny: jny, rems: rems, messages: messages)
            let message = legMessages.joined(separator: "\n").emptyToNil
            
            // Parse journey and wagon sequence context
            let journeyContext: HafasClientInterfaceJourneyContext?
            if let id = jny["jid"].string {
                journeyContext = HafasClientInterfaceJourneyContext(journeyId: id)
            } else {
                journeyContext = nil
            }
            
            let departure = Departure(plannedTime: plannedTime, predictedTime: predictedTime, line: line, position: position, plannedPosition: plannedPosition, cancelled: cancelled || departureCancelled, destination: destination, capacity: nil, message: message, journeyContext: journeyContext)
            
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
        let svcRes = try validateResponse(with: request.responseData, requiredMethod: "TripSearch", "Reconstruction")
        if let err = svcRes["err"].string, err != "OK" {
            let errTxt = svcRes["errTxt"].string
            os_log("Hafas error %{public}@", log: .requestLogger, type: .error, errTxt ?? err)
            switch err {
            case "H890": // No connections found.
                completion(request, .noTrips)
            case "H891": // No route found (try entering an intermediate station).
                completion(request, .noTrips)
            case "H892": // HAFAS Kernel: Request too complex (try entering less intermediate stations).
                completion(request, .noTrips)
            case "H895": // Departure/Arrival are too near.
                completion(request, .tooClose)
            case "H9220": // Nearby to the given address stations could not be found.
                completion(request, .noTrips)
            case "H886": // HAFAS Kernel: No connections found within the requested time interval.
                throw ParseError(reason: "No connections found within the requested time interval.")
            case "H887": // HAFAS Kernel: Kernel computation time limit reached.
                throw ParseError(reason: "Kernel computation time limit reached.")
            case "H9240": // HAFAS Kernel: Internal error.
                throw ParseError(reason: "Internal error.")
            case "H9360": // Date outside of the timetable period.
                completion(request, .invalidDate)
            case "H9380": // Departure/Arrival/Intermediate or equivalent stations def'd more than once
                completion(request, .tooClose)
            case "FAIL" where errTxt == "HCI Service: request failed":
                throw ParseError(reason: "request failed")
            case "LOCATION" where errTxt == "HCI Service: location missing or invalid":
                completion(request, .ambiguous(ambiguousFrom: [], ambiguousVia: [], ambiguousTo: []))
            case "PROBLEMS" where errTxt == "HCI Service: problems during service execution":
                throw ParseError(reason: "problems during service execution")
            case "CGI_READ_FAILED":
                throw ParseError(reason: "cgi read failed")
            default:
                throw ParseError(reason: "unknown hafas error \(errTxt ?? err)")
            }
            return
        }
        
        let common = svcRes["res", "common"]
        let locList = common["locL"]
        let prodList = common["prodL"]
        let opList = common["opL"]
        let remList = common["remL"]
        let himList = common["himL"]
        let polyList = common["polyL"]
        let loadFactorList = common["tcocL"]
        
        let locations = try parseLocList(locList: locList)
        let operators = try parseOpList(opList: opList)
        let lines = try parseProdList(prodList: prodList, operators: operators)
        let rems = try parseRemList(remList: remList)
        let messages = try parseMessageList(himList: himList)
        let encodedPolyList = try parsePolyList(polyL: polyList)
        let loadFactors = try parseLoadFactorList(tcocL: loadFactorList)
        
        let outConL = svcRes["res", "outConL"].arrayValue
        if outConL.isEmpty {
            completion(request, .noTrips)
            return
        }
        
        var trips: [Trip] = []
        for outCon in outConL {
            // Parse trip from/to
            guard let from = locations[safe: outCon["dep", "locX"].int] else { throw ParseError(reason: "could not parse trip from") }
            guard let to   = locations[safe: outCon["arr", "locX"].int] else { throw ParseError(reason: "could not parse trip to") }
            
            let baseDate = try parseBaseDate(from: outCon["date"].stringValue)
            
            var legs: [Leg] = []
            for sec in outCon["secL"].arrayValue {
                // Parse leg from/to
                guard let departureStop = try parseStop(json: sec["dep"], locations: locations, rems: rems, messages: messages, baseDate: baseDate)?.departure else {
                    throw ParseError(reason: "failed to parse departure stop")
                }
                guard let arrivalStop = try parseStop(json: sec["arr"], locations: locations, rems: rems, messages: messages, baseDate: baseDate)?.arrival else {
                    throw ParseError(reason: "failed to parse arrival stop")
                }
                let gis = sec["gis"]
                let distance = gis["distance"].intValue
                let path = parsePath(encodedPolyList: encodedPolyList, jny: gis)
                
                switch sec["type"].stringValue {
                case "JNY", "TETA":
                    let line = lines[safe: sec["jny", "prodX"].int]
                    let leg = try processPublicLeg(jny: sec["jny"], baseDate: baseDate, locations: locations, line: line, rems: rems, messages: messages, encodedPolyList: encodedPolyList, loadFactors: loadFactors, departureStop: departureStop, arrivalStop: arrivalStop, tariffClass: tripOptions.tariffProfile?.tariffClass)
                    
                    legs.append(leg)
                case "WALK", "TRSF", "DEVI":
                    processIndividualLeg(legs: &legs, type: .walk, departureStop: departureStop, arrivalStop: arrivalStop, distance: distance, path: path)
                case "BIKE":
                    processIndividualLeg(legs: &legs, type: .bike, departureStop: departureStop, arrivalStop: arrivalStop, distance: distance, path: path)
                case "TAXI":
                    processIndividualLeg(legs: &legs, type: .car, departureStop: departureStop, arrivalStop: arrivalStop, distance: distance, path: path)
                case "KISS", "PARK":
                    // handle BerlKönig (BVG)
                    let mcpData = sec["dep", "mcp", "mcpData"]
                    if let provider = mcpData["provider"].string, let providerName = mcpData["providerName"].string, provider == "berlkoenig" {
                        let line = Line(id: nil, network: nil, product: .onDemand, label: providerName, name: providerName, number: nil, vehicleNumber: nil, style: lineStyle(network: nil, product: .onDemand, label: providerName), attr: nil, message: nil, direction: nil)
                        legs.append(PublicLeg(line: line, destination: arrivalStop.location, departure: departureStop, arrival: arrivalStop, intermediateStops: [], message: nil, path: path, journeyContext: nil, wagonSequenceContext: nil, loadFactor: nil))
                    } else {
                        processIndividualLeg(legs: &legs, type: .car, departureStop: departureStop, arrivalStop: arrivalStop, distance: distance, path: path)
                    }
                default:
                    throw ParseError(reason: "could not parse outcon sec type \(sec["type"].stringValue)")
                }
            }
            
            let fares = try parseFares(outCon: outCon)
            let context: HafasClientInterfaceRefreshTripContext?
            if let ctxRecon = outCon["ctxRecon"].string {
                context = HafasClientInterfaceRefreshTripContext(contextRecon: ctxRecon, from: from, to: to)
            } else if let ctx = outCon["recon", "ctx"].string {
                context = HafasClientInterfaceRefreshTripContext(contextRecon: ctx, from: from, to: to)
            } else {
                context = nil
            }
            let duration = try parseJsonTime(baseDate: baseDate, dateString: outCon["dur"].string)?.timeIntervalSince(baseDate) ?? 0
            
            let trip = Trip(id: "", from: from, to: to, legs: legs, duration: duration, fares: fares, refreshContext: context)
            trips.append(trip)
        }
        let context: Context
        if let previousContext = previousContext as? Context {
            context = Context(from: from, via: via, to: to, date: date, departure: departure, laterContext: later ? svcRes["res", "outCtxScrF"].string : previousContext.laterContext, earlierContext: !later ? svcRes["res", "outCtxScrB"].string : previousContext.earlierContext, tripOptions: tripOptions)
        } else {
            context = Context(from: from, via: via, to: to, date: date, departure: departure, laterContext: svcRes["res", "outCtxScrF"].string, earlierContext: svcRes["res", "outCtxScrB"].string, tripOptions: tripOptions)
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
        let svcRes = try validateResponse(with: request.responseData, requiredMethod: "JourneyDetails")
        if let error = svcRes["err"].string, error != "OK" {
            if error == "LOCATION" {
                completion(request, .invalidId)
            } else {
                throw ParseError(reason: svcRes["errTxt"].string ?? error)
            }
        }
        let res = svcRes["res"]
        let common = res["common"]
        let locList = common["locL"]
        let prodList = common["prodL"]
        let opList = common["opL"]
        let remList = common["remL"]
        let himList = common["himL"]
        let polyList = common["polyL"]
        let loadFactorList = common["tcocL"]
        
        let locations = try parseLocList(locList: locList)
        let operators = try parseOpList(opList: opList)
        let lines = try parseProdList(prodList: prodList, operators: operators)
        let rems = try parseRemList(remList: remList)
        let messages = try parseMessageList(himList: himList)
        let encodedPolyList = try parsePolyList(polyL: polyList)
        let loadFactors = try parseLoadFactorList(tcocL: loadFactorList)
        
        let journey = res["journey"]
        
        let baseDate = try parseBaseDate(from: journey["date"].stringValue)
        let duration = try parseJsonTime(baseDate: baseDate, dateString: journey["dur"].string)?.timeIntervalSince(baseDate) ?? 0
        
        let line = lines[safe: journey["prodX"].int]
        
        let leg = try processPublicLeg(jny: journey, baseDate: baseDate, locations: locations, line: line, rems: rems, messages: messages, encodedPolyList: encodedPolyList, loadFactors: loadFactors, departureStop: nil, arrivalStop: nil, tariffClass: nil)
        
        let trip = Trip(id: "", from: leg.departure, to: leg.arrival, legs: [leg], duration: duration, fares: [])
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
        
        var gisFltrL: [[String: Any]] = []
        gisFltrL.append([
            "mode": "FB",
            "type": "M",
            "meta": meta
        ])
        if let dist = tripOptions.maxFootpathDist {
            gisFltrL.append([
                "mode": "FB",
                "profile": [
                    "type": "F",
                    "maxdist": dist
                ] as [String : Any],
                "type": "P"
            ])
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
            "gisFltrL": gisFltrL,
            "getPolyline": true,
            "getPasslist": true,
            "extChgTime": -1
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
        var tvlrProf: [String: Any] = [:]
        if supportedQueryTraits.contains(.tariffTravelerType) {
            tvlrProf["type"] = getTravelerTypeCode(from: tripOptions.tariffProfile?.travelerType)
        } else {
            tvlrProf["type"] = "E"
        }
        if supportedQueryTraits.contains(.tariffReductions), let code = tripOptions.tariffProfile?.tariffReduction?.code {
            tvlrProf["redtnCard"] = code
        }
        req["trfReq"] = [
            "jnyCl": tripOptions.tariffProfile?.tariffClass ?? 2,
            "cType": "PK",
            "tvlrProf": [tvlrProf]
        ] as [String : Any]
        return req
    }
    
    private func getTravelerTypeCode(from travelerType: TravelerType?) -> String {
        switch travelerType ?? .adult {
        case .adult: return "E"
        case .youngAdult: return "Y"
        case .child: return "K"
        case .youngChild: return "B"
        }
    }
    
    func wrapJsonApiRequest(meth: String, req: [String: Any], formatted: Bool) -> String? {
        var dict = [
            "auth": apiAuthorization ?? "",
            "client": apiClient ?? "",
            "ver": apiVersion ?? "",
            "lang": queryLanguage ?? defaultLanguage,
            "svcReqL": [[
                "cfg": configJson,
                "meth": meth,
                "req": req
            ] as [String : Any]],
            "formatted": formatted
        ]
        if let extVersion = extVersion {
            dict["ext"] = extVersion
        }
        return encodeJson(dict: dict)
    }
    
    // MARK: Response parse methods
    
    /// Parses a JSON object from a Data object and validates the api method.
    ///
    /// - Parameter data: Data containing the JSON string.
    /// - Parameter requiredMethod: Var-array with possible method names to validate against.
    /// - Throws: ParseError: if the json data could not be parsed or a wrong api-method has been returned.
    /// - Returns: A JSON object.
    private func validateResponse(with data: Data?, requiredMethod: String...) throws -> JSON {
        guard let data = data else {
            throw ParseError(reason: "failed to parse json from data")
        }
        let json = try JSON(data: data)
        let svcRes = json["svcResL", 0]
        let meth = svcRes["meth"].stringValue
        guard requiredMethod.contains(meth) else {
            throw ParseError(reason: "received illegal method response: got \(meth), expected \(requiredMethod)")
        }
        
        return svcRes
    }
    
    private func processPublicLeg(jny: JSON, baseDate: Date, locations: [Location], line: Line?, rems: [RemAttrib]?, messages: [String]?, encodedPolyList: [String]?, loadFactors: [(cls: String, loadFactor: LoadFactor?)]?, departureStop: StopEvent?, arrivalStop: StopEvent?, tariffClass: Int?) throws -> PublicLeg {
        var departureStop = departureStop
        var arrivalStop = arrivalStop
        // Parse remarks and messages
        var (legMessages, attrs, cancelled) = parseLineAttributesAndMessages(jny: jny, rems: rems, messages: messages)
        
        // Parse line
        guard let l = line else { throw ParseError(reason: "failed to parse leg line") }
        // Line direction
        let direction: Line.Direction?
        switch jny["dirFlg"].stringValue {
        case "1": direction = .return
        case "2": direction = .outward
        default: direction = nil
        }
        let line = Line(id: l.id, network: l.network, product: l.product, label: l.label, name: l.name, number: l.number, vehicleNumber: l.vehicleNumber, style: l.style, attr: attrs, message: l.message, direction: direction)
        
        // Parse line destination
        let dirTxt = jny["dirTxt"].string
        let nameAndPlace = split(stationName: stripLineFromDestination(line: line, destinationName: dirTxt))
        let destination: Location? = dirTxt == nil ? nil : Location(type: .any, id: nil, coord: nil, place: nameAndPlace.0, name: nameAndPlace.1)
        
        // Parse intermediate stops
        var intermediateStops: [Stop] = []
        for stop in jny["stopL"].arrayValue {
            if stop["border"].boolValue { continue } // hide borders from intermediate stops
            guard let intermediateStop = try parseStop(json: stop, locations: locations, rems: rems, messages: messages, baseDate: baseDate) else { continue }
            intermediateStops.append(intermediateStop)
        }
        if cancelled {
            intermediateStops.forEach({$0.departure?.cancelled = true; $0.arrival?.cancelled = true})
        }
        
        // Remove first and last stop of intermediates
        if intermediateStops.count >= 2 {
            let dep = intermediateStops.removeFirst()
            if departureStop == nil {
                departureStop = dep.departure
            }
            let arr = intermediateStops.removeLast()
            if arrivalStop == nil {
                arrivalStop = arr.arrival
            }
        }
        guard let departureStop = departureStop, let arrivalStop = arrivalStop else {
            throw ParseError(reason: "failed to parse leg departure/arrival")
        }
        
        // Insert messages of departure and arrival stop
        if let departureMessage = departureStop.message {
            legMessages.insert(departureMessage, at: 0)
        }
        if let arrivalMessage = arrivalStop.message {
            legMessages.append(arrivalMessage)
        }
        let message = legMessages.joined(separator: "\n").emptyToNil
        
        // Parse coord-path
        let path = parsePath(encodedPolyList: encodedPolyList, jny: jny)
        
        // Parse journey context
        let journeyContext: HafasClientInterfaceJourneyContext?
        if let id = jny["jid"].string {
            journeyContext = HafasClientInterfaceJourneyContext(journeyId: id)
        } else {
            journeyContext = nil
        }
        
        // Parse load factor
        let loadFactor: LoadFactor?
        if let tcocXL = jny["dTrnCmpSX", "tcocX"].array {
            let className = tariffClass == 1 ? "FIRST" : "SECOND"
            loadFactor = tcocXL.compactMap({ loadFactors?[safe: $0.int] }).first(where: { $0.cls == className })?.loadFactor
        } else {
            loadFactor = parseLoadFactorFromRems(jny: jny, rems: rems)
        }
        
        return PublicLeg(line: line, destination: destination, departure: departureStop, arrival: arrivalStop, intermediateStops: intermediateStops, message: message, path: path, journeyContext: journeyContext, wagonSequenceContext: getWagonSequenceContext(line: line, departureStop: departureStop), loadFactor: loadFactor)
    }
    
    func getWagonSequenceContext(line: Line, departureStop: StopEvent) -> QueryWagonSequenceContext? {
        return nil
    }
    
    private func processIndividualLeg(legs: inout [Leg], type: IndividualLeg.`Type`, departureStop: StopEvent, arrivalStop: StopEvent, distance: Int, path: [LocationPoint]) {
        var path = path
        var departureTime = departureStop.predictedTime ?? departureStop.plannedTime
        var arrivalTime = arrivalStop.predictedTime ?? arrivalStop.plannedTime
        
        // Workaround for GVH bug:
        // When querying trips before midnight, for some reason the departure time of footpath legs
        // is offset by one day. The arrival time is the correct time though.
        let nearlyOneDay: TimeInterval = 60 * 60 * 23
        let oneDay: TimeInterval = 60 * 60 * 24
        // Departure time is offset by nearly one day
        if let lastArrival = legs.last?.arrivalTime, departureTime.timeIntervalSince(lastArrival) >= nearlyOneDay {
            departureTime = departureTime.addingTimeInterval(-oneDay)
        }
        // Arrival time is offset by nearly one day
        if arrivalTime.timeIntervalSince(departureTime) >= nearlyOneDay {
            arrivalTime = arrivalTime.addingTimeInterval(-oneDay)
        }
        // Workaround end
        
        let addTime: TimeInterval = !legs.isEmpty ? max(0, -departureTime.timeIntervalSince(legs.last!.maxTime)) : 0
        if let lastLeg = legs.last as? IndividualLeg, lastLeg.type == type {
            legs.removeLast()
            path.insert(contentsOf: lastLeg.path, at: 0)
            legs.append(IndividualLeg(type: lastLeg.type, departureTime: lastLeg.departureTime, departure: lastLeg.departure, arrival: arrivalStop.location, arrivalTime: arrivalTime.addingTimeInterval(addTime), distance: 0, path: path))
        } else {
            legs.append(IndividualLeg(type: type, departureTime: departureTime.addingTimeInterval(addTime), departure: departureStop.location, arrival: arrivalStop.location, arrivalTime: arrivalTime.addingTimeInterval(addTime), distance: distance, path: path))
        }
    }
    
    func parsePosition(json: JSON, platfName: String, pltfName: String) -> String? {
        if let pltf = json[pltfName, "txt"].string, !pltf.isEmpty {
            return normalize(position: pltf)
        } else if let platf = json[platfName].string, !platf.isEmpty {
            return normalize(position: platf)
        } else {
            return nil
        }
    }
    
    func parseStop(json: JSON, locations: [Location], rems: [RemAttrib]?, messages: [String]?, baseDate: Date) throws -> Stop? {
        guard let location = locations[safe: json["locX"].int] else { throw ParseError(reason: "failed to get stop location") }
        
        let arrivalCancelled = json["isCncl"].bool ?? json["aCncl"].bool ?? false
        let plannedArrivalTime = try parseJsonTime(baseDate: baseDate, dateString: json["aTimeS"].string)
        let predictedArrivalTime = try parseJsonTime(baseDate: baseDate, dateString: json["aTimeR"].string)
        let plannedArrivalPosition = parsePosition(json: json, platfName: "aPlatfS", pltfName: "aPltfS")
        let predictedArrivalPosition = parsePosition(json: json, platfName: "aPlatfR", pltfName: "aPltfR")
        
        let departureCancelled = json["isCncl"].bool ?? json["dCncl"].bool ?? false
        let plannedDepartureTime = try parseJsonTime(baseDate: baseDate, dateString: json["dTimeS"].string)
        let predictedDepartureTime = try parseJsonTime(baseDate: baseDate, dateString: json["dTimeR"].string)
        let plannedDeparturePosition = parsePosition(json: json, platfName: "dPlatfS", pltfName: "dPltfS")
        let predictedDeparturePosition = parsePosition(json: json, platfName: "dPlatfR", pltfName: "dPltfR")
        
        let (legMessages, _, _) = parseLineAttributesAndMessages(jny: json, rems: rems, messages: messages)
        let message = legMessages.joined(separator: "\n").emptyToNil
        
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
        
        return Stop(location: location, departure: departure, arrival: arrival, message: message)
    }
    
    let P_JSON_TIME = try! NSRegularExpression(pattern: "^(?:(\\d{4})(\\d{2}))?(\\d{2})?(\\d{2})(\\d{2})(\\d{2})$")
    
    func parseJsonTime(baseDate: Date, dateString: String?) throws -> Date? {
        guard let dateString = dateString else { return nil }
        guard let match = dateString.match(pattern: P_JSON_TIME) else { throw ParseError(reason: "failed to parse json time") }
        var date = baseDate
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        if let year = Int(match[0] ?? "") {
            date = calendar.date(byAdding: .year, value: year, to: date) ?? date
        }
        if let month = Int(match[1] ?? "") {
            date = calendar.date(byAdding: .month, value: month, to: date) ?? date
        }
        if let day = Int(match[2] ?? "") {
            date = calendar.date(byAdding: .day, value: day, to: date) ?? date
        }
        if let hour = Int(match[3] ?? "") {
            date = calendar.date(bySetting: .hour, value: hour, of: date) ?? date
        }
        if let minute = Int(match[4] ?? "") {
            date = calendar.date(bySetting: .minute, value: minute, of: date) ?? date
        }
        if let second = Int(match[5] ?? "") {
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
    
    private func parseBaseDate(from string: String) throws -> Date {
        var dateComponents = DateComponents()
        dateComponents.timeZone = timeZone
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        parseIsoDate(from: string, dateComponents: &dateComponents)
        guard let baseDate = calendar.date(from: dateComponents) else { throw ParseError(reason: "failed to parse base date") }
        return baseDate
    }
    
    let P_LOCATION_ID_COORDS = try! NSRegularExpression(pattern: ".*@X=(\\d+)@Y=(\\d+)@.*")
    
    func parseLocList(locList: JSON, throwErrors: Bool = true) throws -> [Location] {
        var locations: [Location] = []
        
        for locElem in locList.arrayValue {
            let locationType: LocationType
            let id: String?
            let placeAndName: (String?, String?)
            let products: [Product]?
            let type = locElem["type"].stringValue
            switch type {
            case "S":
                locationType = .station
                if let lid = locElem["lid"].string, lid.hasSuffix("@") {
                    id = normalize(stationId: lid)
                } else {
                    id = normalize(stationId: locElem["extId"].string)
                }
                placeAndName = split(stationName: locElem["name"].string)
                let pCls = locElem["pCls"].int ?? -1
                products = pCls == -1 ? nil : self.products(from: pCls)
                break
            case "P":
                locationType = .poi
                id = locElem["lid"].string
                placeAndName = split(poi: locElem["name"].string)
                products = nil
                break
            case "A":
                locationType = .address
                id = locElem["lid"].string
                placeAndName = split(address: locElem["name"].string)
                products = nil
                break
            case "C":
                locationType = .coord
                id = nil
                placeAndName = (nil, nil)
                products = nil
            default:
                // currently, DB receives some illegal locations without any associated type
                if throwErrors {
                    throw ParseError(reason: "unknown loc type \(type)")
                } else {
                    continue
                }
            }
            
            let location: Location?
            if let lat = locElem["crd", "y"].int, let lon = locElem["crd", "x"].int {
                location = Location(type: locationType, id: id, coord: LocationPoint(lat: lat, lon: lon), place: placeAndName.0, name: placeAndName.1, products: products)
            } else {
                if let lid = locElem["lid"].string, let match = lid.match(pattern: P_LOCATION_ID_COORDS), let x = Int(match[0] ?? ""), let y = Int(match[1] ?? "") {
                    location = Location(type: locationType, id: id, coord: LocationPoint(lat: y, lon: x), place: placeAndName.0, name: placeAndName.1, products: products)
                } else {
                    location = Location(type: locationType, id: id, coord: nil, place: placeAndName.0, name: placeAndName.1, products: products)
                }
            }
            if let location = location {
                locations.append(location)
            } else if throwErrors {
                throw ParseError(reason: "could not parse location")
            }
        }
        
        return locations
    }
    
    func parseOpList(opList: JSON) throws -> [String]? {
        guard let opList = opList.array else { return nil }
        var operators: [String] = []
        for op in opList {
            guard let name = op["name"].string else { throw ParseError(reason: "could not parse operator") }
            operators.append(name)
        }
        return operators
    }
    
    func parseProdList(prodList: JSON, operators: [String]?) throws -> [Line] {
        var lines: [Line] = []
        for prod in prodList.arrayValue {
            let name = (prod["addName"].string ?? prod["name"].string)?.emptyToNil
            let nameS = prod["nameS"].string
            let number = prod["number"].string
            let oprIndex = prod["oprX"].int ?? -1
            let op = oprIndex == -1 ? nil : operators?[safe: oprIndex]
            let cls = prod["cls"].int ?? -1
            let product = cls == -1 ? nil : try intToProduct(productInt: cls)
            let id = prod["prodCtx", "lineId"].string

            var vehicleNumber = prod["prodCtx", "num"].string
            if number != nil && vehicleNumber == nameS {
                vehicleNumber = nil
            }

            lines.append(newLine(id: id, network: op, product: product, name: name, shortName: nameS, number: number, vehicleNumber: vehicleNumber))
        }
        return lines
    }
    
    func parseRemList(remList: JSON) throws -> [RemAttrib]? {
        guard let remList = remList.array, !remList.isEmpty else { return nil }
        var result: [RemAttrib] = []
        for rem in remList {
            let type = rem["type"].string
            let code = rem["code"].string
            let txtN = rem["txtN"].string
            result.append(RemAttrib(type: type, code: code, txtN: txtN))
        }
        return result
    }
    
    private func parseLineAttributesAndMessages(jny: JSON, rems: [RemAttrib]?, messages: [String]?) -> (legMessages: [String], lineAttrs: [Line.Attr]?, cancelled: Bool) {
        var attrs: [Line.Attr]?
        var legMessages: [String] = []
        var cancelled = jny["isCncl"].boolValue
        if let remL = jny["remL"].array ?? jny["msgL"].array {
            var result = Set<Line.Attr>()
            for jsonRem in remL {
                if jsonRem["type"].string == "REM", let remX = jsonRem["remX"].int, let rem = rems?[safe: remX] {
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
                    case "operator", "df", "ay", "nw", "kc", "al", "cy", "am", "da": // line operator
                        break
                    case "hm": // RB 20: die euregiobahn
                        break
                    case "jw": // NordWestBahn-Servicetelefon
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
                } else if jsonRem["type"].string == "HIM", let himX = jsonRem["himX"].int {
                    guard let text = messages?[safe: himX] else { continue }
                    legMessages.append(text)
                }
            }
            attrs = result.isEmpty ? nil : Array(result)
        } else {
            attrs = nil
        }
        for him in jny["himL"].arrayValue {
            guard let himX = him["himX"].int else { continue }
            guard let text = messages?[safe: himX] else { continue }
            legMessages.append(text)
        }
        // please, please continue to wear a mask, even if the app doesn't nag you about it anymore
        legMessages = legMessages.filter({!$0.lowercased().contains("ffp") && !$0.lowercased().contains("maskenpflicht") && !$0.lowercased().contains("\"3g-pflicht\"") && !$0.lowercased().contains("corona-präventionsmaßnahme")})
        legMessages = legMessages.map({ $0.ensurePunctuation })
        return (legMessages.uniqued(), attrs, cancelled)
    }
    
    func parseLoadFactorFromRems(jny: JSON, rems: [RemAttrib]?) -> LoadFactor? {
        if let remL = jny["remL"].array ?? jny["msgL"].array {
            for jsonRem in remL {
                if jsonRem["type"].string == "REM", let remX = jsonRem["remX"].int, let rem = rems?[safe: remX] {
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
    
    func parseMessageList(himList: JSON) throws -> [String]? {
        guard !himList.arrayValue.isEmpty else { return nil }
        var result: [String] = []
        for him in himList.arrayValue {
            guard var head = him["head"].string ?? him["text"].string else {
                result.append("")
                continue
            }
            while head.hasPrefix(".") {
                head = String(head.dropFirst())
            }
            head = head.ensurePunctuation
            
            if let text = him["lead"].string, !text.isEmpty {
                if !head.isEmpty {
                    head += "\n"
                }
                head += text.ensurePunctuation
            }
            result.append(head)
        }
        // please, please continue to wear a mask, even if the app doesn't nag you about it anymore
        result = result.filter({!$0.lowercased().contains("ffp") && !$0.lowercased().contains("maskenpflicht") && !$0.lowercased().contains("\"3g-pflicht\"") && !$0.lowercased().contains("corona-präventionsmaßnahme")})
        return result
    }
    
    private func parsePolyList(polyL: JSON) throws -> [String]? {
        guard let polyL = polyL.array else { return nil }
        var result: [String] = []
        for poly in polyL {
            guard let coords = poly["crdEncYX"].string else { throw ParseError(reason: "failed to parse poly list") }
            result.append(coords)
        }
        return result
    }
    
    private func parseLoadFactorList(tcocL: JSON) throws -> [(cls: String, loadFactor: LoadFactor?)]? {
        guard let tcocL = tcocL.array else {
            return nil
        }
        var result: [(String, LoadFactor?)] = []
        for tcoc in tcocL {
            guard let cls = tcoc["c"].string else { throw ParseError(reason: "failed to parse load factor") }
            let loadFactor = LoadFactor(rawValue: tcoc["r"].intValue)
            result.append((cls, loadFactor))
        }
        return result
    }
    
    private func parsePath(encodedPolyList: [String]?, jny: JSON) -> [LocationPoint] {
        let path: [LocationPoint]
        if let coords = jny["poly", "crdEncYX"].string, let polyline = try? decodePolyline(from: coords) {
            path = polyline
        } else if let polyX = jny["polyG", "polyXL", 0].int, let polyline = try? decodePolyline(from: encodedPolyList?[safe: polyX]) {
            path = polyline
        } else {
            path = []
        }
        return path
    }
    
    private func parseFares(outCon: JSON) throws -> [Fare] {
        var fares: [Fare] = []
        
        let fareSetList = outCon["trfRes"]["fareSetL"].arrayValue
        let ovwTrfRefList = outCon["ovwTrfRefL"].arrayValue
        
        // iterate over all fare sets, fares and tickets
        // if ovwTrfRefList is not empty, only try add fares from this list, else add all fares
        for (fareSetX, jsonFareSet) in fareSetList.enumerated() {
            guard ovwTrfRefList.isEmpty || ovwTrfRefList.contains(where: { ovwTrfRef in
                return (!ovwTrfRef["fareSetX"].exists() || ovwTrfRef["fareSetX"].int == fareSetX)
            }) else { continue }
            
            let fareList = jsonFareSet["fareL"].arrayValue
            for (fareX, jsonFare) in fareList.enumerated() {
                guard ovwTrfRefList.isEmpty || ovwTrfRefList.contains(where: { ovwTrfRef in
                    return (!ovwTrfRef["fareSetX"].exists() || ovwTrfRef["fareSetX"].int == fareSetX)
                        && (!ovwTrfRef["fareX"   ].exists() || ovwTrfRef["fareX"   ].int == fareX)
                }) else { continue }
                
                let fareName = jsonFare["name"].string ?? jsonFare["desc"].string
                
                if let ticketList = jsonFare["ticketL"].array {
                    for (ticketX, jsonTicket) in ticketList.enumerated() {
                        guard ovwTrfRefList.isEmpty || ovwTrfRefList.contains(where: { ovwTrfRef in
                            return (!ovwTrfRef["fareSetX"].exists() || ovwTrfRef["fareSetX"].int == fareSetX)
                                && (!ovwTrfRef["fareX"   ].exists() || ovwTrfRef["fareX"   ].int == fareX)
                                && (!ovwTrfRef["ticketX" ].exists() || ovwTrfRef["ticketX" ].int == ticketX)
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
    
    private func parseFare(jsonFare: JSON) -> Fare? {
        let price: Int
        if let prc = jsonFare["prc"].int, prc > 0 {
            price = prc
        } else if let amount = jsonFare["price", "amount"].int, amount > 0 {
            price = amount
        } else {
            return nil
        }
        let desc = jsonFare["desc"].string
        let fareName = jsonFare["name"].string ?? desc
        let currency = jsonFare["cur"].string ?? "EUR"
        let name = parse(fareName: fareName, ticketName: nil)
        let fareType = normalize(fareType: fareName ?? "") ?? normalize(fareType: desc ?? "") ?? .adult
        return Fare(name: name.emptyToNil, type: fareType, currency: currency, fare: Float(price) / Float(100), unitsName: nil, units: nil)
    }
    
    private func parseTicket(fareName: String?, jsonTicket: JSON) -> Fare? {
        let price: Int
        if let prc = jsonTicket["prc"].int, prc > 0 {
            price = prc
        } else if let amount = jsonTicket["price", "amount"].int, amount > 0 {
            price = amount
        } else {
            return nil
        }
        let ticketName = jsonTicket["name"].string
        let currency = jsonTicket["cur"].string ?? "EUR"
        let name = parse(fareName: fareName, ticketName: ticketName)
        let fareType = normalize(fareType: fareName ?? "") ?? normalize(fareType: ticketName ?? "") ?? normalize(fareType: jsonTicket["desc"].stringValue) ?? .adult
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
        case let name where name.contains("deutschland-ticket"): return true
        default: return false
        }
    }
    
    func newLine(id: String?, network: String?, product: Product?, name: String?, shortName: String?, number: String?, vehicleNumber: String?) -> Line {
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
            return Line(id: id, network: network, product: product, label: label, name: longName, number: number, style: lineStyle(network: network, product: product, label: label), attr: nil, message: nil)
        } else {
            var label = name ?? shortName ?? number
            if label?.contains("Zug-Nr.") ?? false, let shortName = shortName, name?.contains(shortName) ?? false {
                label = shortName
            }
            return Line(id: id, network: network, product: product, label: label?.replacingOccurrences(of: " ", with: ""), name: longName, number: number, vehicleNumber: vehicleNumber, style: lineStyle(network: network, product: product, label: name), attr: nil, message: nil)
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
    
    public class Context: QueryTripsContext {
        
        public override class var supportsSecureCoding: Bool { return true }
        
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
                urlBuilder.addParameter(key: "checksum", value: (requestString + salt).md5.hex)
            case .micMac(let salt):
                let requestHash = requestString.md5.hex
                urlBuilder.addParameter(key: "mic", value: requestHash)
                urlBuilder.addParameter(key: "mac", value: (requestHash + salt).md5.hex)
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
