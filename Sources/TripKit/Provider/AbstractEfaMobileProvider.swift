import Foundation
import SWXMLHash
import os.log

public class AbstractEfaMobileProvider: AbstractEfaProvider {
    
    // MARK: NetworkProvider mobile implementations – Requests
    
    public override func suggestLocations(constraint: String, types: [LocationType]?, maxLocations: Int, completion: @escaping (HttpRequest, SuggestLocationsResult) -> Void) -> AsyncRequest {
        let urlBuilder = UrlBuilder(path: stopFinderEndpoint, encoding: requestUrlEncoding)
        stopFinderRequestParameters(builder: urlBuilder, constraint: constraint, types: types, maxLocations: maxLocations, outputFormat: "XML")
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder)
        return makeRequest(httpRequest) {
            try self.suggestLocationsParsing(request: httpRequest, constraint: constraint, types: types, maxLocations: maxLocations, completion: completion)
        } errorHandler: { err in
            completion(httpRequest, .failure(err))
        }
    }
    
    public override func queryNearbyLocations(location: Location, types: [LocationType]?, maxDistance: Int, maxLocations: Int, completion: @escaping (HttpRequest, NearbyLocationsResult) -> Void) -> AsyncRequest {
        if let coord = location.coord {
            return mobileCoordRequest(types: types, lat: coord.lat, lon: coord.lon, maxDistance: maxDistance, maxLocations: maxLocations, completion: completion)
        } else {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .invalidId)
            return AsyncRequest(task: nil)
        }
    }
    
    func mobileCoordRequest(types: [LocationType]?, lat: Int, lon: Int, maxDistance: Int, maxLocations: Int, completion: @escaping (HttpRequest, NearbyLocationsResult) -> Void) -> AsyncRequest {
        let urlBuilder = UrlBuilder(path: coordEndpoint, encoding: requestUrlEncoding)
        coordRequestParameters(builder: urlBuilder, types: types, lat: lat, lon: lon, maxDistance: maxDistance, maxLocations: maxLocations)
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder)
        return makeRequest(httpRequest) {
            try self.queryNearbyLocationsByCoordinateParsing(request: httpRequest, location: Location(lat: lat, lon: lon), types: types, maxDistance: maxDistance, maxLocations: maxLocations, completion: completion)
        } errorHandler: { err in
            completion(httpRequest, .failure(err))
        }
    }
    
    public override func queryTrips(from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        let urlBuilder = UrlBuilder(path: tripEndpoint, encoding: requestUrlEncoding)
        queryTripsParameters(builder: urlBuilder, from: from, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions)
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder)
        return makeRequest(httpRequest) {
            try self.queryTripsParsing(request: httpRequest, from: from, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions, previousContext: nil, later: false, completion: completion)
        } errorHandler: { err in
            completion(httpRequest, .failure(err))
        }
    }
    
    public override func queryMoreTrips(context: QueryTripsContext, later: Bool, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        if let context = context as? Context {
            let urlBuilder = UrlBuilder(path: tripEndpoint, encoding: requestUrlEncoding)
            if later {
                commandLink(builder: urlBuilder, sessionId: context.queryLaterContext.sessionId, requestId: context.queryLaterContext.requestId)
            } else {
                commandLink(builder: urlBuilder, sessionId: context.queryEarlierContext.sessionId, requestId: context.queryEarlierContext.requestId)
            }
            appendCommonRequestParameters(builder: urlBuilder, outputFormat: "XML")
            urlBuilder.addParameter(key: "command", value: later ? "tripNext" : "tripPrev")
            
            let httpRequest = HttpRequest(urlBuilder: urlBuilder)
            return makeRequest(httpRequest) {
                try self._queryTripsParsing(request: httpRequest, from: nil, via: nil, to: nil, date: Date(), departure: true, tripOptions: TripOptions(), previousContext: context, later: later, completion: completion)
            } errorHandler: { err in
                self.checkSessionExpired(httpRequest: httpRequest, err: err, completion: completion)
            }
        } else if let context = context as? StatelessContext {
            let refDate = later ? context.lastDepartureTime : context.firstArrivalTime
            
            let urlBuilder = UrlBuilder(path: tripEndpoint, encoding: requestUrlEncoding)
            queryTripsParameters(builder: urlBuilder, from: context.from, via: context.via, to: context.to, date: refDate, departure: later, tripOptions: context.tripOptions)
            // ensure that the first displayed trip is after the given departure time /
            // last displayed trip is before the given arrival time
            urlBuilder.addParameter(key: "calcOneDirection", value: 1)
            
            let httpRequest = HttpRequest(urlBuilder: urlBuilder)
            return makeRequest(httpRequest) {
                try self.queryTripsParsing(request: httpRequest, from: context.from, via: context.via, to: context.to, date: refDate, departure: later, tripOptions: context.tripOptions, previousContext: context, later: later, completion: completion)
            } errorHandler: { err in
                completion(httpRequest, .failure(err))
            }
        } else {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .sessionExpired)
            return AsyncRequest(task: nil)
        }
    }
    
    public override func refreshTrip(context: RefreshTripContext, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        guard let context = context as? EfaRefreshTripContext else {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .sessionExpired)
            return AsyncRequest(task: nil)
        }
        let urlBuilder = UrlBuilder(path: tripEndpoint, encoding: requestUrlEncoding)
        urlBuilder.addParameter(key: "language", value: queryLanguage ?? defaultLanguage)
        urlBuilder.addParameter(key: "outputFormat", value: "XML")
        urlBuilder.addParameter(key: "coordOutputFormat", value: "WGS84")
        urlBuilder.addParameter(key: "sessionID", value: context.sessionId)
        urlBuilder.addParameter(key: "requestID", value: context.requestId)
        urlBuilder.addParameter(key: "command", value: "tripCoordSeq:\(context.routeIndex)")
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder)
        return makeRequest(httpRequest) {
            try self.refreshTripParsing(request: httpRequest, context: context, completion: completion)
        } errorHandler: { err in
            self.checkSessionExpired(httpRequest: httpRequest, err: err, completion: completion)
        }
    }
    
    public override func queryDepartures(stationId: String, departures: Bool, time: Date?, maxDepartures: Int, equivs: Bool, completion: @escaping (HttpRequest, QueryDeparturesResult) -> Void) -> AsyncRequest {
        let urlBuilder = UrlBuilder(path: departureMonitorEndpoint, encoding: requestUrlEncoding)
        queryDeparturesParameters(builder: urlBuilder, stationId: stationId, departures: departures, time: time, maxDepartures: maxDepartures, equivs: equivs)
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder)
        return makeRequest(httpRequest) {
            try self.queryDeparturesParsing(request: httpRequest, stationId: stationId, departures: departures, time: time, maxDepartures: maxDepartures, equivs: equivs, completion: completion)
        } errorHandler: { err in
            completion(httpRequest, .failure(err))
        }
    }
    
    public override func queryJourneyDetail(context: QueryJourneyDetailContext, completion: @escaping (HttpRequest, QueryJourneyDetailResult) -> Void) -> AsyncRequest {
        guard let context = context as? EfaJourneyContext, var lineId = context.line.id else {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .invalidId)
            return AsyncRequest(task: nil)
        }
        if lineId.hasSuffix(":") {
            lineId += "j18"
        }
        let urlBuilder = UrlBuilder(path: tripStopTimesEndpoint, encoding: requestUrlEncoding)
        appendCommonRequestParameters(builder: urlBuilder, outputFormat: "XML")
        urlBuilder.addParameter(key: "stopID", value: context.stopId)
        urlBuilder.addParameter(key: "tripCode", value: context.tripCode)
        urlBuilder.addParameter(key: "line", value: context.line.id)
        appendDate(builder: urlBuilder, date: context.stopDepartureTime, dateParam: "date", timeParam: "time")
        urlBuilder.addParameter(key: "tStOTType", value: "all")
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder)
        return makeRequest(httpRequest) {
            try self.queryJourneyDetailParsing(request: httpRequest, context: context, completion: completion)
        } errorHandler: { err in
            completion(httpRequest, .failure(err))
        }
    }
    
    // MARK: NetworkProvider mobile responses
    
    override func suggestLocationsParsing(request: HttpRequest, constraint: String, types: [LocationType]?, maxLocations: Int, completion: @escaping (HttpRequest, SuggestLocationsResult) -> Void) throws {
        guard let data = request.responseData else { throw ParseError(reason: "no response") }
        let xml = XMLHash.parse(data)
        var locations: [SuggestedLocation] = []
        for elem in xml["efa"]["sf"]["p"].all {
            guard let name = normalizeLocationName(name: elem["n"].element?.text), let ty = elem["ty"].element?.text else {
                throw ParseError(reason: "failed to parse stop")
            }
            guard let u = elem["u"].element?.text, u == "sf" else {
                throw ParseError(reason: "unknown usage \(elem["n"].element?.text ?? "")")
            }
            
            let locationType: LocationType
            switch ty {
            case "stop":
                locationType = .station
            case "poi":
                locationType = .poi
            case "loc":
                locationType = .coord
            case "street", "singlehouse":
                locationType = .address
            default:
                os_log("%{public}@: unknown location type %{public}@", log: .requestLogger, type: .error, #function, ty)
                locationType = .any
            }
            
            let r = elem["r"]
            guard let id = r["id"].element?.text, let stateless = r["stateless"].element?.text else {
                throw ParseError(reason: "failed to parse stop id")
            }
            let place = normalizeLocationName(name: r["pc"].element?.text)
            let coord = parseCoordinates(string: r["c"].element?.text)
            let qal = Int(elem["qal"].element?.text ?? "") ?? 0
            
            let location = Location(type: locationType, id: locationType == .station ? id : stateless, coord: coord, place: place, name: name)
            if let location = location {
                locations.append(SuggestedLocation(location: location, priority: qal))
            } else {
                throw ParseError(reason: "failed to parse stop")
            }
        }
        locations.sort {$0.priority > $1.priority}
        completion(request, .success(locations: locations))
    }
    
    override func queryNearbyLocationsByCoordinateParsing(request: HttpRequest, location: Location, types: [LocationType]?, maxDistance: Int, maxLocations: Int, completion: @escaping (HttpRequest, NearbyLocationsResult) -> Void) throws {
        guard let data = request.responseData else { throw ParseError(reason: "no response") }
        let xml = XMLHash.parse(data)
        let response = xml["efa"]["ci"]
        
        var locations: [Location] = []
        for pi in response["pis"]["pi"].all {
            let name = normalizeLocationName(name: pi["de"].element?.text)
            let type = pi["ty"].element?.text
            let locationType: LocationType
            switch type ?? "" {
            case "STOP":
                locationType = .station
                break
            case "POI_POINT":
                locationType = .poi
            default:
                throw ParseError(reason: "unknown type \(type ?? "")")
            }
            
            let id = pi["id"].element?.text
            let stateless = pi["stateless"].element?.text
            let place = normalizeLocationName(name: pi["locality"].element?.text)
            let coord = parseCoordinates(string: pi["c"].element?.text)
            
            let location: Location?
            let locationId = locationType == .station ? id : stateless
            if let name = name {
                location = Location(type: locationType, id: locationId, coord: coord, place: place, name: name)
            } else {
                location = Location(type: locationType, id: locationId, coord: coord, place: nil, name: place)
            }
            if let location = location {
                locations.append(location)
            } else {
                throw ParseError(reason: "failed to parse location")
            }
        }
        completion(request, .success(locations: locations))
    }
    
    override func refreshTripParsing(request: HttpRequest, context: RefreshTripContext, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) throws {
        try _queryTripsParsing(request: request, from: nil, via: nil, to: nil, date: Date(), departure: true, tripOptions: TripOptions(), previousContext: nil, later: false, completion: completion)
    }
    
    override func queryTripsParsing(request: HttpRequest, from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions, previousContext: QueryTripsContext?, later: Bool, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) throws {
        try _queryTripsParsing(request: request, from: from, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions, previousContext: previousContext, later: later, completion: completion)
    }
    
    func _queryTripsParsing(request: HttpRequest, from: Location?, via: Location?, to: Location?, date: Date, departure: Bool, tripOptions: TripOptions, previousContext: QueryTripsContext?, later: Bool, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) throws {
        guard let data = request.responseData else { throw ParseError(reason: "no response") }
        let xml = XMLHash.parse(data)
        let response = xml["efa"]
        
        for err in response["ers"]["err"].all {
            if err["tx"].element?.text == "stop invalid" {
                switch err["u"].element?.text ?? "" {
                case "origin":
                    completion(request, .unknownFrom)
                case "via":
                    completion(request, .unknownVia)
                case "destination":
                    completion(request, .unknownTo)
                default:
                    completion(request, .noTrips)
                }
                return
            }
        }
        
        let requestId = response["pas"]["pa"].all.first(where: {$0["n"].element?.text == "requestID"})?["v"].element?.text
        let sessionId = response["pas"]["pa"].all.first(where: {$0["n"].element?.text == "sessionID"})?["v"].element?.text
        
        var trips: [Trip] = []
        for tp in response["ts"]["tp"].all {
            let tripId = ""
            
            var firstDepartureLocation: Location? = nil
            var lastArrivalLocation: Location? = nil
            
            
            var legs: [Leg] = []
            for l in tp["ls"]["l"].all {
                let realtime = l["realtime"].element?.text == "1"
                var departure: StopEvent? = nil
                var arrival: StopEvent? = nil
                for p in l["ps"]["p"].all {
                    let name = p["n"].element?.text
                    let id = p["r"]["id"].element?.text
                    let usage = p["u"].element?.text
                    
                    guard let plannedTime = parseMobilePlannedTime(xml: p["st"]) else {
                        throw ParseError(reason: "failed to parse planned departure/arrival time")
                    }
                    let predictedTime = realtime ? parseMobilePredictedTime(xml: p["st"]) : nil
                    
                    let position = parsePosition(position: p["r"]["pl"].element?.text)
                    let place = normalizeLocationName(name: p["r"]["pc"].element?.text)
                    let coord = parseCoordinates(string: p["r"]["c"].element?.text)
                    
                    let location: Location?
                    if id == "99999997" || id == "99999998" {
                        location = Location(type: .address, id: nil, coord: coord, place: place, name: name)
                    } else {
                        location = Location(type: .station, id: id, coord: coord, place: place, name: name)
                    }
                    guard let location = location else {
                        throw ParseError(reason: "failed to parse location")
                    }
                    let stop = StopEvent(location: location, plannedTime: plannedTime, predictedTime: predictedTime, plannedPlatform: position, predictedPlatform: nil, cancelled: false)
                    switch usage {
                    case "departure":
                        departure = stop
                        if firstDepartureLocation == nil {
                            firstDepartureLocation = location
                        }
                    case "arrival":
                        arrival = stop
                        lastArrivalLocation = location
                    default:
                        throw ParseError(reason: "unknown usage \(usage ?? "")")
                    }
                }
                
                guard let departure = departure else {
                    throw ParseError(reason: "failed to parse departure stop")
                }
                guard let arrival = arrival else {
                    throw ParseError(reason: "failed to parse arrival stop")
                }
                
                let lineDestination = try parseMobileLineDestination(xml: l, tyOrCo: false)
                let path: [LocationPoint]
                if let coordString = l["pt"].element?.text {
                    path = processCoordinateStrings(coordString)
                } else {
                    path = []
                }
                
                var intermediateStops: [Stop] = []
                
                for stop in l["pss"]["s"].all {
                    guard let s = stop.element?.text else { throw ParseError(reason: "failed to parse stop") }
                    let intermediateParts = s.components(separatedBy: ";")
                    guard intermediateParts.count > 4 else { throw ParseError(reason: "failed to parse intermediate") }
                    let id = intermediateParts[0]
                    if id != departure.location.id && id != arrival.location.id {
                        let name = normalizeLocationName(name: intermediateParts[1])!
                        
                        var plannedTime: Date? = nil
                        var predictedTime: Date? = nil
                        if !(intermediateParts[2] == "0000-1" && intermediateParts[3] == "000-1") {
                            var dateComponents = DateComponents()
                            dateComponents.timeZone = timeZone
                            parseIsoDate(from: intermediateParts[2], dateComponents: &dateComponents)
                            parseIsoTime(from: intermediateParts[3], dateComponents: &dateComponents)
                            plannedTime = gregorianCalendar.date(from: dateComponents)
                            
                            if realtime {
                                dateComponents = DateComponents()
                                dateComponents.timeZone = timeZone
                                parseIsoDate(from: intermediateParts[2], dateComponents: &dateComponents)
                                parseIsoTime(from: intermediateParts[3], dateComponents: &dateComponents)
                                predictedTime = gregorianCalendar.date(from: dateComponents)
                                
                                if intermediateParts.count > 5 && intermediateParts[5].count > 0 {
                                    if let delay = Int(intermediateParts[5]) {
                                        predictedTime = predictedTime?.addingTimeInterval(Double(delay) * 60.0)
                                    }
                                }
                            }
                        }
                        let coordPart = intermediateParts[4]
                        let coords: LocationPoint?
                        if coordPart != "::" {
                            let coordParts = coordPart.components(separatedBy: ":")
                            if coordParts[2] == "WGS84", let lat = Double(coordParts[1]), let lon = Double(coordParts[0]) {
                                coords = LocationPoint(lat: Int(round(lat)), lon: Int(round(lon)))
                            } else {
                                coords = nil
                            }
                        } else {
                            coords = nil
                        }
                        
                        let location = Location(type: .station, id: id, coord: coords, place: nil, name: name)
                        if let location = location {
                            let stopEvent: StopEvent?
                            if let plannedTime = plannedTime {
                                stopEvent = StopEvent(location: location, plannedTime: plannedTime, predictedTime: predictedTime, plannedPlatform: nil, predictedPlatform: nil, cancelled: false)
                            } else {
                                stopEvent = nil
                            }
                            let stop = Stop(location: location, departure: stopEvent, arrival: stopEvent, message: nil)
                            intermediateStops.append(stop)
                        } else {
                            throw ParseError(reason: "failed to parse stop location")
                        }
                    }
                }
                let addTime: TimeInterval = !legs.isEmpty ? max(0, -departure.minTime.timeIntervalSince(legs.last!.maxTime)) : 0
                if lineDestination.line === Line.FOOTWAY {
                    legs.append(IndividualLeg(type: .walk, departureTime: departure.minTime.addingTimeInterval(addTime), departure: departure.location, arrival: arrival.location, arrivalTime: arrival.maxTime.addingTimeInterval(addTime), distance: 0, path: path))
                } else if lineDestination.line === Line.TRANSFER {
                    legs.append(IndividualLeg(type: .transfer, departureTime: departure.minTime.addingTimeInterval(addTime), departure: departure.location, arrival: arrival.location, arrivalTime: arrival.maxTime.addingTimeInterval(addTime), distance: 0, path: path))
                } else if lineDestination.line === Line.DO_NOT_CHANGE {
                    if let last = legs.last as? PublicLeg {
                        var lastMessage = "Nicht umsteigen, Weiterfahrt im selben Fahrzeug möglich."
                        if let message = last.message?.emptyToNil {
                            lastMessage += "\n" + message
                        }
                        legs[legs.count - 1] = PublicLeg(line: last.line, destination: last.destination, departure: last.departureStop, arrival: last.arrivalStop, intermediateStops: last.intermediateStops, message: lastMessage, path: last.path, journeyContext: last.journeyContext, wagonSequenceContext: nil, loadFactor: last.loadFactor)
                    }
                } else if lineDestination.line === Line.SECURE_CONNECTION {
                    // ignore
                } else {
                    let journeyContext: EfaJourneyContext?
                    // currently, I don't think trip code exists in the data. Added this just in case this changes in the future
                    if let departureId = departure.location.id, let tripCode = l["m"]["dv"]["tk"].element?.text, lineDestination.line.id != nil {
                        journeyContext = EfaJourneyContext(stopId: departureId, stopDepartureTime: departure.plannedTime, line: lineDestination.line, tripCode: tripCode)
                    } else {
                        journeyContext = nil
                    }
                    legs.append(PublicLeg(line: lineDestination.line, destination: lineDestination.destination, departure: departure, arrival: arrival, intermediateStops: intermediateStops, message: nil, path: path, journeyContext: journeyContext, wagonSequenceContext: nil, loadFactor: nil))
                }
            }
            
            var fares: [Fare] = []
            for elem in tp["tcs"]["tc"].all {
                guard let type = elem["n"].element?.text, type == "SINGLE_TICKET" else { continue }
                let unitsName = elem["un"].element?.text
                if let fareAdult = elem["fa"].element?.text, let fare = Float(fareAdult), fare != 0 {
                    let unit = elem["ua"].element?.text
                    fares.append(Fare(name: nil, type: .adult, currency: "EUR", fare: fare, unitsName: unitsName, units: unit))
                }
                if let fareChild = elem["fc"].element?.text, let fare = Float(fareChild), fare != 0 {
                    let unit = elem["uc"].element?.text
                    fares.append(Fare(name: nil, type: .child, currency: "EUR", fare: fare, unitsName: unitsName, units: unit))
                }
                break
            }
            let duration = parseDuration(from: tp["d"].element?.text)
            
            let context: EfaRefreshTripContext? = nil
            if let firstDepartureLocation = firstDepartureLocation, let lastArrivalLocation = lastArrivalLocation {
                let trip = Trip(id: tripId, from: firstDepartureLocation, to: lastArrivalLocation, legs: legs, duration: duration, fares: fares, refreshContext: context)
                trips.append(trip)
            } else {
                throw ParseError(reason: "failed to parse trip from/to")
            }
        }
        if trips.count > 0 {
            let context: QueryTripsContext?
            if useStatelessTripContexts, let from = from, let to = to {
                context = StatelessContext(from: from, via: via, to: to, tripOptions: tripOptions, trips: trips, previousContext: previousContext)
            } else if let sessionId = sessionId, let requestId = requestId {
                if let previousContext = previousContext as? Context {
                    context = Context(queryEarlierContext: later ? previousContext.queryEarlierContext : (sessionId: sessionId, requestId: requestId), queryLaterContext: !later ? previousContext.queryLaterContext : (sessionId: sessionId, requestId: requestId))
                } else {
                    context = Context(queryEarlierContext: (sessionId: sessionId, requestId: requestId), queryLaterContext: (sessionId: sessionId, requestId: requestId))
                }
            } else {
                context = nil
            }
            completion(request, .success(context: context, from: from, via: via, to: to, trips: trips, messages: []))
        } else {
            completion(request, .noTrips)
        }
    }
    
    override func queryDeparturesParsing(request: HttpRequest, stationId: String, departures: Bool, time: Date?, maxDepartures: Int, equivs: Bool, completion: @escaping (HttpRequest, QueryDeparturesResult) -> Void) throws {
        guard let data = request.responseData else { throw ParseError(reason: "no response") }
        let xml = XMLHash.parse(data)
        if let error = xml["efa"]["ers"]["err"].element, let mod = error.attribute(by: "mod")?.text, let co = error.attribute(by: "co")?.text {
            throw ParseError(reason: "Efa error: " + mod + " " + co)
        }
        let departures = xml["efa"]["dps"]["dp"].all
        if departures.count == 0 {
            completion(request, .invalidStation)
            return
        }
        
        var result: [StationDepartures] = []
        for dp in departures {
            guard let assignedId = dp["r"]["id"].element?.text else { throw ParseError(reason: "failed to parse departure id") }
            let cancelled = dp["rts"].element?.text == "DEPARTURE_CANCELLED"
            
            guard let plannedTime = parseMobilePlannedTime(xml: dp["st"]) else { throw ParseError(reason: "failed to parse planned time") }
            let predictedTime = parseMobilePredictedTime(xml: dp["st"])
            
            let lineDestination = try parseMobileLineDestination(xml: dp, tyOrCo: true)
            let position = parsePosition(position: dp["r"]["pl"].element?.text)
            
            var stationDepartures = result.first(where: {$0.stopLocation.id == assignedId})
            if stationDepartures == nil, let location = Location(type: .station, id: assignedId) {
                stationDepartures = StationDepartures(stopLocation: location, departures: [], lines: [])
                result.append(stationDepartures!)
            }
            let context: EfaJourneyContext?
            let tripCode = dp["m"]["dv"]["tk"].element?.text
            if let tripCode = tripCode, lineDestination.line.id != nil {
                context = EfaJourneyContext(stopId: assignedId, stopDepartureTime: plannedTime, line: lineDestination.line, tripCode: tripCode)
            } else {
                context = nil
            }
            
            stationDepartures?.departures.append(Departure(plannedTime: plannedTime, predictedTime: predictedTime, line: lineDestination.line, position: position, plannedPosition: position, cancelled: cancelled, destination: lineDestination.destination, journeyContext: context))
        }
        completion(request, .success(departures: result))
    }
    
    private func parseStopEvent(from p: XMLIndexer, format: DateFormatter, prefix: String) throws -> StopEvent? {
        guard let timeString = p["r"]["\(prefix)DateTime"].element?.text else { return nil }
        let name = p["n"].element?.text
        let id = p["r"]["id"].element?.text
        
        let plannedTime = format.date(from: timeString)
        
        let position = parsePosition(position: p["r"]["pl"].element?.text)
        let place = normalizeLocationName(name: p["r"]["pc"].element?.text)
        let coord = parseCoordinates(string: p["r"]["c"].element?.text)
        
        guard let location = Location(type: .station, id: id, coord: coord, place: place, name: name) else { throw ParseError(reason: "failed to parse stop") }
        if let plannedTime = plannedTime {
            return StopEvent(location: location, plannedTime: plannedTime, predictedTime: nil, plannedPlatform: position, predictedPlatform: nil, cancelled: false)
        }
        return nil
    }
    
    override func queryJourneyDetailParsing(request: HttpRequest, context: QueryJourneyDetailContext, completion: @escaping (HttpRequest, QueryJourneyDetailResult) -> Void) throws {
        guard let data = request.responseData, let line = (context as? EfaJourneyContext)?.line else { throw ParseError(reason: "no response") }
        let xml = XMLHash.parse(data)
        let response = xml["efa"]["stopSeqCoords"]
        var stops: [Stop] = []
        let format = DateFormatter()
        format.dateFormat = "yyyyMMdd HH:mm"
        for p in response["params"]["stopSeq"]["p"].all {
            let departure = try parseStopEvent(from: p, format: format, prefix: "dep")
            let arrival = try parseStopEvent(from: p, format: format, prefix: "arr")
            if let location = departure?.location ?? arrival?.location {
                let stop = Stop(location: location, departure: departure, arrival: arrival, message: nil)
                stops.append(stop)
            }
        }
        guard stops.count >= 2 else {
            throw ParseError(reason: "could not parse departure and arrival")
        }
        guard let departureStop = stops.removeFirst().departure else {
            throw ParseError(reason: "could not parse departure")
        }
        guard let arrivalStop = stops.removeLast().arrival else {
            throw ParseError(reason: "could not parse arrival")
        }
        let path: [LocationPoint]
        if let coordString = response["c"]["pt"].element?.text {
            path = processCoordinateStrings(coordString)
        } else {
            path = []
        }
        let leg = PublicLeg(line: line, destination: arrivalStop.location, departure: departureStop, arrival: arrivalStop, intermediateStops: stops, message: nil, path: path, journeyContext: nil, wagonSequenceContext: nil, loadFactor: nil)
        let trip = Trip(id: "", from: departureStop.location, to: arrivalStop.location, legs: [leg], duration: 0, fares: [])
        completion(request, .success(trip: trip, leg: leg))
    }
    
    // MARK: Response mobile parse methods
    
    func parseMobilePlannedTime(xml: XMLIndexer) -> Date? {
        guard let timeString = xml["t"].element?.text, let dateString = xml["da"].element?.text else { return nil }
        
        var dateComponents = DateComponents()
        dateComponents.timeZone = timeZone
        parseIsoTime(from: timeString, dateComponents: &dateComponents)
        parseIsoDate(from: dateString, dateComponents: &dateComponents)
        
        return gregorianCalendar.date(from: dateComponents)
    }
    
    func parseMobilePredictedTime(xml: XMLIndexer) -> Date? {
        guard let timeString = xml["rt"].element?.text, let dateString = xml["rda"].element?.text else { return nil }
        
        var dateComponents = DateComponents()
        dateComponents.timeZone = timeZone
        parseIsoTime(from: timeString, dateComponents: &dateComponents)
        parseIsoDate(from: dateString, dateComponents: &dateComponents)
        
        return gregorianCalendar.date(from: dateComponents)
    }
    
    let P_MOBILE_M_SYMBOL = try! NSRegularExpression(pattern: "([^\\s]*)\\s+([^\\s]*)")
    
    func parseMobileLineDestination(xml: XMLIndexer, tyOrCo: Bool) throws -> ServingLine {
        let productNu = xml["m"]["nu"].element?.text
        let ty = xml["m"]["ty"].element?.text
        let n = xml["m"]["n"].element?.text
        
        let line: Line
        let destination: Location?
        if ty == "100" || ty == "99" {
            destination = nil
            line = Line.FOOTWAY
        } else if ty == "105" {
            destination = nil
            line = Line.TRANSFER
        } else if ty == "98" {
            destination = nil
            line = Line.SECURE_CONNECTION
        } else if ty == "97" {
            destination = nil
            line = Line.DO_NOT_CHANGE
        } else {
            guard let co = xml["m"]["co"].element?.text else { throw ParseError(reason: "failed to parse co") }
            let productType = tyOrCo ? ty : co
            let destinationName = normalizeLocationName(name: xml["m"]["des"].element?.text)
            if let destinationName = destinationName {
                destination = Location(anyName: destinationName)
            } else {
                destination = nil
            }
            let de = xml["m"]["de"].element?.text
            let productName = n ?? de
            let lineId = try parseMobileDiva(xml: xml["m"])
            
            let symbol: String
            if let productName = productName, productNu == nil {
                symbol = productName
            } else if let productName = productName, let productNu = productNu, productNu.hasSuffix(" " + productName) {
                symbol = String(productNu[..<productNu.index(productNu.startIndex, offsetBy: productNu.count - productName.count - 1)])
            } else {
                symbol = productNu!
            }
            
            let trainType: String?
            let trainNum: String?
            if let match = symbol.match(pattern: P_MOBILE_M_SYMBOL) {
                trainType = match[0]
                trainNum = match[1]
            } else {
                trainType = nil
                trainNum = nil
            }
            
            let network = xml["m"]["dv"]["ne"].element?.text
            let parsedLine = parseLine(id: lineId, network: network, mot: productType, symbol: symbol, name: symbol, longName: nil, trainType: trainType, trainNum: trainNum, trainName: productName)
            line = Line(id: parsedLine.id, network: parsedLine.network, product: parsedLine.product, label: parsedLine.label, name: parsedLine.name, style: lineStyle(network: parsedLine.network, product: parsedLine.product, label: parsedLine.label), attr: nil, message: nil)
        }
        
        return ServingLine(line: line, destination: destination)
    }
    
    func parseMobileDiva(xml: XMLIndexer) throws -> String {
        if let stateless = xml["dv"]["stateless"].element?.text, stateless.contains(":") {
            return stateless
        }
        guard let lineIdLi = xml["dv"]["li"].element?.text, let lineIdSu = xml["dv"]["su"].element?.text, let lineIdPr = xml["dv"]["pr"].element?.text, let lineIdDct = xml["dv"]["dct"].element?.text, let lineIdNe = xml["dv"]["ne"].element?.text else { throw ParseError(reason: "could not parse line diva") }
        let branch = xml["dv"]["branch"].element?.text ?? ""
        return lineIdNe + ":" + branch + lineIdLi + ":" + lineIdSu + ":" + lineIdDct + ":" + lineIdPr
    }
    
}
