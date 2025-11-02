import Foundation
import SWXMLHash
import SwiftyJSON
import os.log

public class AbstractEfaWebProvider: AbstractEfaProvider {
    
    // MARK: NetworkProvider implementations – Requests
    
    override public func suggestLocations(constraint: String, types: [LocationType]?, maxLocations: Int, completion: @escaping (HttpRequest, SuggestLocationsResult) -> Void) -> AsyncRequest {
        let urlBuilder = UrlBuilder(path: stopFinderEndpoint, encoding: requestUrlEncoding)
        stopFinderRequestParameters(builder: urlBuilder, constraint: constraint, types: types, maxLocations: maxLocations, outputFormat: "JSON")
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder)
        return makeRequest(httpRequest) {
            try self.suggestLocationsParsing(request: httpRequest, constraint: constraint, types: types, maxLocations: maxLocations, completion: completion)
        } errorHandler: { err in
            completion(httpRequest, .failure(err))
        }
    }
    
    override public func queryNearbyLocations(location: Location, types: [LocationType]?, maxDistance: Int, maxLocations: Int, completion: @escaping (HttpRequest, NearbyLocationsResult) -> Void) -> AsyncRequest {
        if let coord = location.coord {
            return coordRequest(types: types, lat: coord.lat, lon: coord.lon, maxDistance: maxDistance, maxLocations: maxLocations, completion: completion)
        } else if location.type == .station, let id = location.id {
            return nearbyStationsRequest(stationId: id, maxLocations: maxLocations, completion: completion)
        } else {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .invalidId)
            return AsyncRequest(task: nil)
        }
    }
    
    func nearbyStationsRequest(stationId: String, maxLocations: Int, completion: @escaping (HttpRequest, NearbyLocationsResult) -> Void) -> AsyncRequest {
        let urlBuilder = UrlBuilder(path: departureMonitorEndpoint, encoding: requestUrlEncoding)
        nearbyStationsRequestParameters(builder: urlBuilder, stationId: stationId, maxLocations: maxLocations)
        
        let httpRequest = HttpRequest(urlBuilder: urlBuilder)
        return makeRequest(httpRequest) {
            try self.handleNearbyStationsRequest(httpRequest: httpRequest, maxLocations: maxLocations, completion: completion)
        } errorHandler: { err in
            completion(httpRequest, .failure(err))
        }
    }
    
    func coordRequest(types: [LocationType]?, lat: Int, lon: Int, maxDistance: Int, maxLocations: Int, completion: @escaping (HttpRequest, NearbyLocationsResult) -> Void) -> AsyncRequest {
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
    
    override public func queryMoreTrips(context: QueryTripsContext, later: Bool, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        if let context = context as? Context {
            let urlBuilder = UrlBuilder(path: tripEndpoint, encoding: requestUrlEncoding)
            if later {
                commandLink(builder: urlBuilder, sessionId: context.queryLaterContext.sessionId, requestId: context.queryLaterContext.requestId)
            } else {
                commandLink(builder: urlBuilder, sessionId: context.queryEarlierContext.sessionId, requestId: context.queryEarlierContext.requestId)
            }
            appendCommonRequestParameters(builder: urlBuilder, outputFormat: "XML")
            urlBuilder.addParameter(key: "coordListOutputFormat", value: "STRING")
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
    
    override public func queryDepartures(stationId: String, departures: Bool, time: Date?, maxDepartures: Int, equivs: Bool, completion: @escaping (HttpRequest, QueryDeparturesResult) -> Void) -> AsyncRequest {
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
    
    // MARK: NetworkProvider responses
    
    override func suggestLocationsParsing(request: HttpRequest, constraint: String, types: [LocationType]?, maxLocations: Int, completion: @escaping (HttpRequest, SuggestLocationsResult) -> Void) throws {
        guard let data = request.responseData else { throw ParseError(reason: "no response") }
        let json = try JSON(data: data)
        let head = json["stopFinder"].exists() ? json["stopFinder"] : json
        
        // check for errors
        for message in head["message"].arrayValue {
            let name = message["name"].stringValue
            let value = message["value"].stringValue
            if name == "code" && value != "-8010" && value != "-8011" {
                throw ParseError(reason: "received illegal message code \(value)")
            }
        }
        
        var locations: [SuggestedLocation] = []
        let pointObj = head["points"]["point"]
        func parseJsonPoint(json: JSON) throws -> SuggestedLocation {
            var type = json["type"].stringValue
            if type == "any" {
                type = json["anyType"].string ?? type
            }
            let id = json["stateless"].string
            let name = normalizeLocationName(name: json["name"].string)
            let object = normalizeLocationName(name: json["object"].string)
            let postcode = json["postcode"].string
            let quality = json["quality"].intValue
            let place = json["ref"]["place"].string?.emptyToNil
            let coordinates = parseCoordinates(string: json["ref"]["coord"].string ?? json["ref"]["coords"].string)
            
            let location: Location?
            switch type {
            case "stop":
                location = Location(type: .station, id: id, coord: coordinates, place: place, name: object)
                break
            case "poi":
                location = Location(type: .poi, id: id, coord: coordinates, place: place, name: object)
                break
            case "crossing":
                location = Location(type: .address, id: id, coord: coordinates, place: place, name: object)
                break
            case "street", "address", "singlehouse", "buildingname", "loc":
                location = Location(type: .address, id: id, coord: coordinates, place: place, name: name)
                break
            case "postcode":
                location = Location(type: .address, id: id, coord: coordinates, place: place, name: postcode)
                break
            default:
                location = Location(type: .any, id: nil, coord: coordinates, place: place, name: name)
                break
            }
            guard let finalLocation = location else {
                throw ParseError(reason: "failed to init location")
            }
            return SuggestedLocation(location: finalLocation, priority: quality)
        }
        if pointObj.exists() {
            locations.append(try parseJsonPoint(json: pointObj))
        } else if head["points"].exists() {
            for point in head["points"].arrayValue {
                locations.append(try parseJsonPoint(json: point))
            }
        } else if let first = head.arrayValue.first {
            locations.append(try parseJsonPoint(json: first))
        }
        
        locations.sort {$0.priority > $1.priority}
        completion(request, .success(locations: locations))
    }
    
    override func queryNearbyLocationsByCoordinateParsing(request: HttpRequest, location: Location, types: [LocationType]?, maxDistance: Int, maxLocations: Int, completion: @escaping (HttpRequest, NearbyLocationsResult) -> Void) throws {
        guard let data = request.responseData else { throw ParseError(reason: "no response") }
        let xml = XMLHash.parse(data)
        let response = xml["itdRequest"]["itdCoordInfoRequest"]["itdCoordInfo"]["coordInfoItemList"]
        
        var locations: [Location] = []
        for coordItem in response["coordInfoItem"].all {
            let type = coordItem.element?.attribute(by: "type")?.text
            let locationType: LocationType
            if type == "STOP" {
                locationType = .station
            } else if type == "POI_POINT" {
                locationType = .poi
            } else {
                throw ParseError(reason: "unknown location type \(type ?? "")")
            }
            let id = coordItem.element?.attribute(by: "stateless")?.text ?? coordItem.element?.attribute(by: "id")?.text
            let name = normalizeLocationName(name: coordItem.element?.attribute(by: "name")?.text)
            let place = normalizeLocationName(name: coordItem.element?.attribute(by: "locality")?.text)
            let coordList = processItdPathCoordinates(coordItem["itdPathCoordinates"])
            let coord = coordList == nil ? nil : coordList!.count > 0 ? coordList![0] : nil
            
            let location = Location(type: locationType, id: id, coord: coord, place: place, name: name)
            if let location = location {
                locations.append(location)
            }
        }
        completion(request, .success(locations: locations))
    }
    
    func handleNearbyStationsRequest(httpRequest: HttpRequest, maxLocations: Int, completion: @escaping (HttpRequest, NearbyLocationsResult) -> Void) throws {
        guard let data = httpRequest.responseData else { throw ParseError(reason: "failed to parse data") }
        let xml = XMLHash.parse(data)
        let request = xml["itdRequest"]["itdDepartureMonitorRequest"]
        
        var ownStation: Location?
        var stations: [Location] = []
        let nameState = try processItdOdv(odv: request["itdOdv"], expectedUsage: "dm") { (nameState, location, matchQuality) in
            if location.type == .station {
                if nameState == "identified" {
                    ownStation = location
                } else if nameState == "assigned" {
                    stations.append(location)
                }
            }
        }
        
        if nameState == "notidentified" {
            completion(httpRequest, .invalidId)
            return
        }
        
        if let ownStation = ownStation, !stations.contains(ownStation) {
            stations.append(ownStation)
        }
        
        if maxLocations == 0 || maxLocations >= stations.count {
            completion(httpRequest, .success(locations: stations))
        } else {
            completion(httpRequest, .success(locations: Array(stations[0..<maxLocations])))
        }
    }
    
    override func queryTripsParsing(request: HttpRequest, from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions, previousContext: QueryTripsContext?, later: Bool, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) throws {
        try _queryTripsParsing(request: request, from: from, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions, previousContext: previousContext, later: later, completion: completion)
    }
    
    override func refreshTripParsing(request: HttpRequest, context: RefreshTripContext, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) throws {
        try _queryTripsParsing(request: request, from: nil, via: nil, to: nil, date: Date(), departure: true, tripOptions: TripOptions(), previousContext: nil, later: false, completion: completion)
    }
    
    func _queryTripsParsing(request: HttpRequest, from: Location?, via: Location?, to: Location?, date: Date, departure: Bool, tripOptions: TripOptions, previousContext: QueryTripsContext?, later: Bool, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) throws {
        guard let data = request.responseData else { throw ParseError(reason: "no response") }
        let xmlString = String(decoding: data, as: UTF8.self)  // automatically repair strings with illegal encoding
        let xml = XMLHash.parse(xmlString)
        var response = xml["itdRequest"]["itdTripRequest"]
        if response.all.isEmpty {
            response = xml["itdRequest"]
        }
        let requestId = response.element?.attribute(by: "requestID")?.text
        let sessionId = xml["itdRequest"].element?.attribute(by: "sessionID")?.text
        if let code = response["itdMessage"].element?.attribute(by: "code")?.text, code == "-4000" {
            completion(request, .noTrips)
            return
        }
        
        var ambiguousFrom, ambiguousTo, ambiguousVia: [Location]?
        var fromIdentified, viaIdentified, toIdentified: Location?
        for odv in response["itdOdv"].all {
            guard let usage = odv.element?.attribute(by: "usage")?.text else { continue }
            
            var locations: [Location] = []
            var sort: [Location: Int] = [:]
            
            let nameState = try processItdOdv(odv: odv, expectedUsage: usage, callback: { (nameState: String?, location: Location, matchQuality: Int) in
                locations.append(location)
                sort[location] = matchQuality
            })
            
            locations.sort {sort[$0]! > sort[$1]!}
            
            if nameState == "list" {
                if usage == "origin" {
                    ambiguousFrom = locations
                } else if usage == "via" {
                    ambiguousVia = locations
                } else if usage == "destination" {
                    ambiguousTo = locations
                } else {
                    throw ParseError(reason: "unknown usage \(usage)")
                }
            } else if nameState == "identified" {
                if usage == "origin" {
                    fromIdentified = locations[0]
                } else if usage == "via" {
                    viaIdentified = locations[0]
                } else if usage == "destination" {
                    toIdentified = locations[0]
                } else {
                    throw ParseError(reason: "unknown usage \(usage)")
                }
            } else if nameState == "notidentified" {
                if usage == "origin" {
                    completion(request, .unknownFrom)
                } else if usage == "via" {
                    completion(request, .unknownVia)
                } else if usage == "destination" {
                    completion(request, .unknownTo)
                } else {
                    throw ParseError(reason: "unknown usage \(usage)")
                }
                return
            }
        }
        if ambiguousFrom != nil || ambiguousVia != nil || ambiguousTo != nil {
            completion(request, .ambiguous(ambiguousFrom: ambiguousFrom ?? [], ambiguousVia: ambiguousVia ?? [], ambiguousTo: ambiguousTo ?? []))
            return
        }
        if let message = response["itdTripDateTime"]["itdDateTime"]["itdDate"]["itdMessage"].element?.text, message == "invalid date" {
            completion(request, .invalidDate)
            return
        }
        
        var messages: [InfoText] = []
        for infoLink in xml["itdRequest"]["itdInfoLinkList"]["itdBannerInfoList"]["infoLink"].all {
            guard let infoLinkText = infoLink["infoLinkText"].element?.text, let infoLinkUrl = infoLink["infoLinkURL"].element?.text else { continue }
            messages.append(InfoText(text: infoLinkText.stripHTMLTags(), url: infoLinkUrl))
        }
        
        var trips: [Trip] = []
        var routes = response["itdItinerary"]["itdRouteList"]["itdRoute"].all
        if routes.isEmpty {
            routes = response["itdTripCoordSeqRequest"]["itdRoute"].all
        }
        if routes.isEmpty {
            completion(request, .noTrips)
            return
        }
        
        for route in routes {
            let id = "" // when using query earlier, trip ids are no longer unique, but shift
            
            var legs: [Leg] = []
            var firstDepartureLocation: Location?
            var lastArrivalLocation: Location?
            var cancelled = false
            
            for partialRoute in route["itdPartialRouteList"]["itdPartialRoute"].all {
                var legMessages: [String] = []
                for infoLink in partialRoute["infoLink"].all {
                    guard let infoLinkText = infoLink["infoText"]["subtitle"].element?.text else { continue }
                    legMessages.append(infoLinkText.stripHTMLTags())
                }
                
                let points = partialRoute["itdPoint"].all
                var point = points[0]
                if point.element?.attribute(by: "usage")?.text != "departure" {
                    throw ParseError(reason: "wrong route usage")
                }
                guard let departureLocation = processItdPointAttributes(point: point) else {
                    throw ParseError(reason: "departure location point attr")
                }
                if firstDepartureLocation == nil {
                    firstDepartureLocation = departureLocation
                }
                let departurePosition = parsePosition(position: point.element?.attribute(by: "platformName")?.text)
                let plannedDeparturePosition = parsePosition(position: point.element?.attribute(by: "plannedPlatformName")?.text)
                guard let departureTime = processItdDateTime(xml: point["itdDateTime"]) else {
                    throw ParseError(reason: "departure time")
                }
                let departureTargetTime = processItdDateTime(xml: point["itdDateTimeTarget"])
                
                point = points[1]
                if point.element?.attribute(by: "usage")?.text != "arrival" {
                    throw ParseError(reason: "wrong route usage")
                }
                guard let arrivalLocation = processItdPointAttributes(point: point) else {
                    throw ParseError(reason: "arrival location point attr")
                }
                lastArrivalLocation = arrivalLocation
                let arrivalPosition = parsePosition(position: point.element?.attribute(by: "platformName")?.text)
                let plannedArrivalPosition = parsePosition(position: point.element?.attribute(by: "plannedPlatformName")?.text)
                guard let arrivalTime = processItdDateTime(xml: point["itdDateTime"]) else {
                    throw ParseError(reason: "arrival time")
                }
                let arrivalTargetTime = processItdDateTime(xml: point["itdDateTimeTarget"])
                
                let meansOfTransportProductName = partialRoute["itdMeansOfTransport"].element?.attribute(by: "productName")?.text
                guard let meansOfTransportType = Int(partialRoute["itdMeansOfTransport"].element?.attribute(by: "type")?.text ?? "") else {
                    throw ParseError(reason: "means of transport type")
                }
                if meansOfTransportType <= 16 {
                    cancelled |= try processPublicLeg(partialRoute, &legs, departureTime, departureTargetTime, departureLocation, departurePosition, plannedDeparturePosition, arrivalTime, arrivalTargetTime, arrivalLocation, arrivalPosition, plannedArrivalPosition, legMessages)
                } else if meansOfTransportType == 97 && meansOfTransportProductName == "nicht umsteigen" {
                    if let last = legs.last as? PublicLeg {
                        var lastMessage = "Nicht umsteigen, Weiterfahrt im selben Fahrzeug möglich."
                        if let message = last.message?.emptyToNil {
                            lastMessage += "\n" + message
                        }
                        if let msg = legMessages.joined(separator: "\n").emptyToNil {
                            lastMessage += "\n" + msg
                        }
                        legs[legs.count - 1] = PublicLeg(line: last.line, destination: last.destination, departure: last.departureStop, arrival: last.arrivalStop, intermediateStops: last.intermediateStops, message: lastMessage, path: last.path, journeyContext: last.journeyContext, wagonSequenceContext: nil, loadFactor: last.loadFactor)
                    }
                } else if meansOfTransportType == 98 && meansOfTransportProductName == "gesicherter Anschluss" {
                    // ignore
                } else if meansOfTransportType == 99 && meansOfTransportProductName == "Fussweg" {
                    processIndividualLeg(partialRoute, &legs, .walk, departureTime, departureLocation, arrivalTime, arrivalLocation)
                } else if meansOfTransportType == 100 && (meansOfTransportProductName == nil || meansOfTransportProductName == "Fussweg") {
                    processIndividualLeg(partialRoute, &legs, .walk, departureTime, departureLocation, arrivalTime, arrivalLocation)
                } else if meansOfTransportType == 105 && meansOfTransportProductName == "Taxi" {
                    processIndividualLeg(partialRoute, &legs, .car, departureTime, departureLocation, arrivalTime, arrivalLocation)
                } else {
                    throw ParseError(reason: "unknown means of transport: \(meansOfTransportType) \(meansOfTransportProductName ?? "")")
                }
            }
            guard let from = firstDepartureLocation, let to = lastArrivalLocation else {
                throw ParseError(reason: "from/to location")
            }
            
            var fares: [Fare] = []
            if let elem = route["itdFare"]["itdSingleTicket"].element, let currency = elem.attribute(by: "currency")?.text {
                let unitName = elem.attribute(by: "unitName")?.text.trimmingCharacters(in: .whitespaces)
                if let fareAdult = elem.attribute(by: "fareAdult")?.text, let fare = Float(fareAdult), fare != 0 {
                    let level = elem.attribute(by: "levelAdult")?.text.trimmingCharacters(in: .whitespaces)
                    let units = elem.attribute(by: "unitsAdult")?.text.trimmingCharacters(in: .whitespaces)
                    
                    fares.append(Fare(name: nil, type: .adult, currency: currency, fare: fare, unitsName: level ?? "" != "" ? nil : (unitName ?? "" == "" ? nil : unitName), units: level ?? "" != "" ? level : units))
                }
                if let fareChild = elem.attribute(by: "fareChild")?.text, let fare = Float(fareChild), fare != 0 {
                    let level = elem.attribute(by: "levelChild")?.text.trimmingCharacters(in: .whitespaces)
                    let units = elem.attribute(by: "unitsChild")?.text.trimmingCharacters(in: .whitespaces)
                    
                    fares.append(Fare(name: nil, type: .child, currency: currency, fare: fare, unitsName: level ?? "" != "" ? nil : (unitName ?? "" == "" ? nil : unitName), units: level ?? "" != "" ? level : units))
                }
            } else {
                let tickets = route["itdFare"]["itdUnifiedTicket"].all
                for ticket in tickets {
                    guard
                        let name = ticket.element?.attribute(by: "name")?.text,
                        name.starts(with: "Einzelfahrschein"),
                        let currency = ticket.element?.attribute(by: "currency")?.text,
                        let person = ticket.element?.attribute(by: "person")?.text,
                        let fareString = ticket.element?.attribute(by: "priceBrutto")?.text,
                        let fare = Float(fareString)
                    else {
                        continue
                    }
                    switch person {
                    case "ADULT":
                        fares.append(Fare(name: nil, type: .adult, currency: currency, fare: fare, unitsName: nil, units: nil))
                    case "CHILD":
                        fares.append(Fare(name: nil, type: .child, currency: currency, fare: fare, unitsName: nil, units: nil))
                    default: break
                    }
                        
                }
            }
            
            let context: EfaRefreshTripContext?
            if let sessionId = sessionId, let requestId = requestId {
                context = EfaRefreshTripContext(sessionId: sessionId, requestId: requestId, routeIndex: "\(trips.count + 1)")
            } else {
                context = nil
            }
            
            let duration = parseDuration(from: route.element?.attribute(by: "publicDuration")?.text)
            
            let trip = Trip(id: id, from: from, to: to, legs: legs, duration: duration, fares: fares, refreshContext: context)
            trips.append(trip)
        }
        if trips.count == 0 {
            completion(request, .noTrips)
            return
        }
        
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
            context = previousContext as? Context
        }
        
        completion(request, .success(context: context, from: fromIdentified, via: viaIdentified, to: toIdentified, trips: trips, messages: messages))
    }
    
    override func queryDeparturesParsing(request: HttpRequest, stationId: String, departures: Bool, time: Date?, maxDepartures: Int, equivs: Bool, completion: @escaping (HttpRequest, QueryDeparturesResult) -> Void) throws {
        guard let data = request.responseData else { throw ParseError(reason: "no response") }
        let xml = XMLHash.parse(data)
        let response = xml["itdRequest"]["itdDepartureMonitorRequest"]
        
        var result: [StationDepartures] = []
        
        let departureStop = response["itdOdv"]
        let nameState = try self.processItdOdv(odv: departureStop, expectedUsage: "dm", callback: { (nameState: String?, location: Location, matchQuality: Int) in
            if location.type == .station {
                if !result.contains(where: {$0.stopLocation.id == location.id}) {
                    result.append(StationDepartures(stopLocation: location, departures: [], lines: []))
                }
            }
        })
        
        if nameState != "identified" {
            completion(request, .invalidStation)
            return
        }
        
        for servingLine in response["itdServingLines"]["itdServingLine"].all {
            guard let (line, destination, _) = self.parseLine(xml: servingLine) else {
                throw ParseError(reason: "failed to parse line")
            }
            let assignedStopId = servingLine.element?.attribute(by: "assignedStopID")?.text
            result.first(where: {$0.stopLocation.id == assignedStopId})?.lines.append(ServingLine(line: line, destination: destination))
        }
        
        for departure in response[departures ? "itdDepartureList" : "itdArrivalList"][departures ? "itdDeparture" : "itdArrival"].all {
            let assignedStopId = departure.element?.attribute(by: "stopID")?.text
            guard let plannedTime = self.parseDate(xml: departure["itdDateTime"]) else { continue }
            let predictedTime = self.parseDate(xml: departure["itdRTDateTime"])
            guard let (line, destination, cancelled) = self.parseLine(xml: departure["itdServingLine"]) else {
                throw ParseError(reason: "failed to parse line")
            }
            let predictedPosition = parsePosition(position: departure.element?.attribute(by: "platformName")?.text)
            let plannedPosition = parsePosition(position: departure.element?.attribute(by: "plannedPlatformName")?.text) ?? predictedPosition
            
            let context: EfaJourneyContext?
            let tripCode = departure["itdServingTrip"].element?.attribute(by: "tripCode")?.text ?? departure["itdServingLine"].element?.attribute(by: "key")?.text
            if let stopId = assignedStopId, let tripCode = tripCode, line.id != nil {
                context = EfaJourneyContext(stopId: stopId, stopDepartureTime: plannedTime, line: line, tripCode: tripCode)
            } else {
                context = nil
            }
            
            let departure = Departure(plannedTime: plannedTime, predictedTime: predictedTime, line: line, position: predictedPosition, plannedPosition: plannedPosition, cancelled: cancelled, destination: destination, capacity: nil, message: line.message, journeyContext: context)
            result.first(where: {$0.stopLocation.id == assignedStopId})?.departures.append(departure)
        }
        
        completion(request, .success(departures: result))
    }
    
    override func queryJourneyDetailParsing(request: HttpRequest, context: QueryJourneyDetailContext, completion: @escaping (HttpRequest, QueryJourneyDetailResult) -> Void) throws {
        guard let data = request.responseData, let line = (context as? EfaJourneyContext)?.line else { throw ParseError(reason: "no response") }
        let xml = XMLHash.parse(data)
        let response = xml["itdRequest"]["itdStopSeqCoordRequest"]["stopSeq"]
        var stops: [Stop] = []
        for point in response["itdPoint"].all {
            guard let stopLocation = processItdPointAttributes(point: point) else { continue }
            let stopPosition = parsePosition(position: point.element?.attribute(by: "platformName")?.text)
            
            let plannedStopArrivalTime = processItdDateTime(xml: point["itdDateTime"][0])
            let predictedStopArrivalTime = processItdDateTime(xml: point["itdDateTimeTarget"][0])
            let plannedStopDepartureTime = processItdDateTime(xml: point["itdDateTime"][1])
            let predictedStopDepartureTime = processItdDateTime(xml: point["itdDateTimeTarget"][1])
            
            let departure: StopEvent?
            if let plannedStopDepartureTime = plannedStopDepartureTime {
                departure = StopEvent(location: stopLocation, plannedTime: plannedStopDepartureTime, predictedTime: predictedStopDepartureTime, plannedPlatform: stopPosition, predictedPlatform: nil, cancelled: false)
            } else {
                departure = nil
            }
            let arrival: StopEvent?
            if let plannedStopArrivalTime = plannedStopArrivalTime {
                arrival = StopEvent(location: stopLocation, plannedTime: plannedStopArrivalTime, predictedTime: predictedStopArrivalTime, plannedPlatform: stopPosition, predictedPlatform: nil, cancelled: false)
            } else {
                arrival = nil
            }
            
            let stop = Stop(location: stopLocation, departure: departure, arrival: arrival, message: nil)
            
            stops.append(stop)
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
        let path = processItdPathCoordinates(xml["itdRequest"]["itdStopSeqCoordRequest"]["itdPathCoordinates"]) ?? []
        let leg = PublicLeg(line: line, destination: arrivalStop.location, departure: departureStop, arrival: arrivalStop, intermediateStops: stops, message: nil, path: path, journeyContext: nil, wagonSequenceContext: nil, loadFactor: nil)
        let trip = Trip(id: "", from: departureStop.location, to: arrivalStop.location, legs: [leg], duration: 0, fares: [])
        completion(request, .success(trip: trip, leg: leg))
    }
    
    // MARK: Response parse methods
    
    func processItdOdv(odv: XMLIndexer, expectedUsage: String, callback: (_ nameState: String?, _ location: Location, _ matchQuality: Int) -> Void) throws -> String {
        guard let usage = odv.element?.attribute(by: "usage")?.text, usage == expectedUsage else {
            throw ParseError(reason: "expecting \(expectedUsage), got \(odv.element?.attribute(by: "usage")?.text ?? "unknown")")
        }
        
        let type = odv.element?.attribute(by: "type")?.text
        let place = try processItdOdvPlace(odv: odv["itdOdvPlace"])
        let nameState = odv["itdOdvName"].element?.attribute(by: "state")?.text
        if nameState == "identified" {
            let location = try processOdvNameElem(odv: odv["itdOdvName"]["odvNameElem"], type: type, defaultPlace: place)
            if let location = location {
                callback(nameState, location, Int(INT_MAX))
            }
        } else if nameState == "list" {
            for nameElem in odv["itdOdvName"]["odvNameElem"].all {
                let matchQuality = Int(nameElem.element?.attribute(by: "matchQuality")?.text ?? "") ?? Int(INT_MAX)
                let location = try processOdvNameElem(odv: nameElem, type: type, defaultPlace: place)
                if let location = location {
                    callback(nameState, location, matchQuality)
                }
            }
        } else if nameState != "notidentified" && nameState != "empty" {
            throw ParseError(reason: "cannot handle namestate \(nameState ?? "")")
        }
        
        for assignedStop in odv["itdOdvAssignedStops"]["itdOdvAssignedStop"].all {
            let stop = processItdOdvAssignedStop(odv: assignedStop)
            if let stop = stop {
                callback("assigned", stop, 0)
            }
        }
        
        return nameState ?? ""
    }
    
    func processItdOdvPlace(odv: XMLIndexer) throws -> String? {
        guard let placeState = odv.element?.attribute(by: "state")?.text else { throw ParseError(reason: "place state not found") }
        if placeState == "identified" {
            return odv["odvPlaceElem"].element?.text
        } else {
            return nil
        }
    }
    
    func processOdvNameElem(odv: XMLIndexer, type: String?, defaultPlace: String?) throws -> Location? {
        var type = type
        if type == "any" {
            type = odv.element?.attribute(by: "anyType")?.text
        }
        guard let id = odv.element?.attribute(by: "stateless")?.text else { throw ParseError(reason: "could not parse odv name id") }
        let locality = normalizeLocationName(name: odv.element?.attribute(by: "locality")?.text)
        let objectName = normalizeLocationName(name: odv.element?.attribute(by: "objectName")?.text)
        let buildingName = odv.element?.attribute(by: "buildingName")?.text
        let buildingNumber = odv.element?.attribute(by: "buildingNumber")?.text
        let postCode = odv.element?.attribute(by: "postCode")?.text
        let streetName = odv.element?.attribute(by: "streetName")?.text
        let coord = processCoordAttr(odv: odv)
        
        let nameElem = normalizeLocationName(name: odv.element?.text)
        
        let locationType: LocationType
        let place: String?
        let name: String?
        
        if type == "stop" {
            locationType = .station
            place = locality ?? defaultPlace
            name = objectName ?? nameElem
        } else if type == "poi" {
            locationType = .poi
            place = locality ?? defaultPlace
            name = objectName ?? nameElem
        } else if type == "loc" {
            if let locality = locality {
                locationType = .address
                place = nil
                name = locality
            } else if let nameElem = nameElem {
                locationType = .address
                place = nil
                name = nameElem
            } else if let _ = coord {
                locationType = .coord
                place = nil
                name = nil
            } else {
                throw ParseError(reason: "failed to parse location")
            }
        } else if type == "address" || type == "singlehouse" {
            locationType = .address
            place = locality ?? defaultPlace
            if let objectName = objectName, let buildingNumber = buildingNumber {
                name = objectName + " " + buildingNumber
            } else {
                name = objectName
            }
        } else if type == "street" || type == "crossing" {
            locationType = .address
            place = locality ?? defaultPlace
            name = objectName ?? nameElem
        } else if type == "postcode" {
            locationType = .address
            place = locality ?? defaultPlace
            name = postCode
        } else if type == "buildingname" {
            locationType = .address
            place = locality ?? defaultPlace
            name = buildingName ?? streetName
        } else if type == "coord" {
            locationType = .address
            place = defaultPlace
            name = nameElem
        } else {
            throw ParseError(reason: "unknown type \(type ?? "")")
        }
        
        return Location(type: locationType, id: id, coord: coord, place: place, name: name)
    }
    
    func processItdOdvAssignedStop(odv: XMLIndexer) -> Location? {
        guard let id = odv.element?.attribute(by: "stopID")?.text else { return nil }
        let coord = processCoordAttr(odv: odv)
        let place = normalizeLocationName(name: odv.element?.attribute(by: "place")?.text)
        guard let name = normalizeLocationName(name: odv.element?.text) else { return nil }
        
        return Location(type: .station, id: id, coord: coord, place: place, name: name)
    }
    
    func processItdPointAttributes(point: XMLIndexer) -> Location? {
        guard let id = point.element?.attribute(by: "stopID")?.text else { return nil }
        var place = normalizeLocationName(name: point.element?.attribute(by: "locality")?.text)
        if place == nil {
            place = normalizeLocationName(name: point.element?.attribute(by: "place")?.text)
        }
        var name = normalizeLocationName(name: point.element?.attribute(by: "nameWO")?.text)
        if name == nil || name == "???" || place == nil {
            name = normalizeLocationName(name: point.element?.attribute(by: "name")?.text)
        }
        let coord = processCoordAttr(odv: point)
        let isStop = id != "99999999" && id != "99999998" && id != "99999997"
        return Location(type: isStop ? .station : .any, id: isStop ? id : nil, coord: coord, place: place, name: name)
    }
    
    func processPublicLeg(_ xml: XMLIndexer, _ legs: inout [Leg], _ departureTime: Date, _ departureTargetTime: Date?, _ departureLocation: Location, _ departurePosition: String?, _ plannedDeparturePosition: String?, _ arrivalTime: Date, _ arrivalTargetTime: Date?, _ arrivalLocation: Location, _ arrivalPosition: String?, _ plannedArrivalPosition: String?, _ legMessages: [String]) throws -> Bool {
        let motSymbol = xml["itdMeansOfTransport"].element?.attribute(by: "symbol")?.text
        let motType = xml["itdMeansOfTransport"].element?.attribute(by: "motType")?.text
        let motShortName = xml["itdMeansOfTransport"].element?.attribute(by: "shortname")?.text
        let motName = xml["itdMeansOfTransport"].element?.attribute(by: "name")?.text
        let motTrainName = xml["itdMeansOfTransport"].element?.attribute(by: "trainName")?.text
        let motTrainType = xml["itdMeansOfTransport"].element?.attribute(by: "trainType")?.text
        let tripCode = xml["itdMeansOfTransport"].element?.attribute(by: "tC")?.text
        let number = xml["itdMeansOfTransport"].element?.attribute(by: "number")?.text
        let trainNum = xml["itdMeansOfTransport"].element?.attribute(by: "trainNum")?.text
        
        guard let divaNetwork = xml["itdMeansOfTransport"]["motDivaParams"].element?.attribute(by: "network")?.text, let divaLine = xml["itdMeansOfTransport"]["motDivaParams"].element?.attribute(by: "line")?.text, let divaDirection = xml["itdMeansOfTransport"]["motDivaParams"].element?.attribute(by: "direction")?.text else {
            throw ParseError(reason: "diva")
        }
        let divaSupplement = xml["itdMeansOfTransport"]["motDivaParams"].element?.attribute(by: "supplement")?.text ?? ""
        let divaProject = xml["itdMeansOfTransport"]["motDivaParams"].element?.attribute(by: "project")?.text ?? ""
        let lineId = divaNetwork + ":" + divaLine + ":" + divaSupplement + ":" + divaDirection + ":" + divaProject
        
        let line: Line
        if motSymbol == "AST" {
            line = Line(id: nil, network: divaNetwork, product: .onDemand, label: "AST")
        } else {
            line = parseLine(id: lineId, network: divaNetwork, mot: motType, symbol: motSymbol, name: motShortName, longName: motName, trainType: motTrainType, trainNum: motShortName, trainName: motTrainName)
        }
        
        var destinationName = stripLineFromDestination(line: line, destinationName: normalizeLocationName(name: xml["itdMeansOfTransport"].element?.attribute(by: "destination")?.text))
        var messages = Set<String>()
        if let destination = destinationName, destination.hasSuffix(" EILZUG") {
            destinationName = String(destination.dropLast(" EILZUG".count))
            messages.insert("Eilzug: Zug hält nicht überall.")
        }
        let destinationId = xml["itdMeansOfTransport"].element?.attribute(by: "destID")?.text
        let destination: Location?
        if let destinationId = destinationId, destinationId != "" {
            destination = Location(type: .station, id: destinationId, coord: nil, place: nil, name: destinationName)
        } else if let destinationName = destinationName {
            destination = Location(anyName: destinationName)
        } else {
            destination = nil
        }
        
        var lowFloorVehicle = false
        for infoText in xml["itdInfoTextList"]["infoTextListElem"].all {
            if let text = infoText.element?.text {
                if text.lowercased().hasPrefix("niederflurwagen") {
                    lowFloorVehicle = true
                } else if text.lowercased().contains("ruf") || text.lowercased().contains("anmeld") || text.lowercased().contains("ast") {
                    messages.insert(text.stripHTMLTags())
                }
            }
        }
        
        if let infoText = xml["infoLink"]["infoLinkText"].element?.text {
            messages.insert(infoText.stripHTMLTags())
        }
        messages = messages.union(legMessages)
        
        let rblDepartureDelay = Int(xml["itdRBLControlled"].element?.attribute(by: "delayMinutes")?.text ?? "")
        let rblArrivalDelay = Int(xml["itdRBLControlled"].element?.attribute(by: "delayMinutesArr")?.text ?? "")
        let cancelled = rblDepartureDelay == -9999 || rblArrivalDelay == -9999
        
        var stops: [Stop] = []
        for point in xml["itdStopSeq"]["itdPoint"].all {
            guard let stopLocation = processItdPointAttributes(point: point) else { continue }
            let stopPosition = parsePosition(position: point.element?.attribute(by: "platformName")?.text)
            
            let plannedStopArrivalTime = processItdDateTime(xml: point["itdDateTime"][0])
            var predictedStopArrivalTime = processItdDateTime(xml: point["itdDateTimeTarget"][0])
            let arrValid = point.element?.attribute(by: "arrValid")?.text ?? "" == "1"
            var arrivalCancelled = cancelled
            if let delay = Int(point.element?.attribute(by: "arrDelay")?.text ?? ""), delay != -1 && arrValid, predictedStopArrivalTime == nil {
                if delay == -9999 {
                    arrivalCancelled = true
                } else {
                    predictedStopArrivalTime = plannedStopArrivalTime?.addingTimeInterval(TimeInterval(delay * 60))
                }
            }
            if let rblArrivalDelay = rblArrivalDelay, rblArrivalDelay != -9999, predictedStopArrivalTime == nil {
                predictedStopArrivalTime = plannedStopArrivalTime?.addingTimeInterval(TimeInterval(rblArrivalDelay * 60))
            }
            let plannedStopDepartureTime = point["itdDateTime"].all.count > 1 ? processItdDateTime(xml: point["itdDateTime"][1]) : plannedStopArrivalTime
            var predictedStopDepartureTime = point["itdDateTimeTarget"].all.count > 1 ? processItdDateTime(xml: point["itdDateTimeTarget"][1]) : predictedStopArrivalTime
            let depValid = point.element?.attribute(by: "depValid")?.text ?? "" == "1"
            var departureCancelled = cancelled
            if let delay = Int(point.element?.attribute(by: "depDelay")?.text ?? ""), delay != -1 && depValid, predictedStopDepartureTime == nil {
                if delay == -9999 {
                    departureCancelled = true
                } else {
                    predictedStopDepartureTime = plannedStopDepartureTime?.addingTimeInterval(TimeInterval(delay * 60))
                }
            }
            if let rblDepartureDelay = rblDepartureDelay, rblDepartureDelay != -9999, predictedStopDepartureTime == nil {
                predictedStopDepartureTime = plannedStopDepartureTime?.addingTimeInterval(TimeInterval(rblDepartureDelay * 60))
            }
            let departure: StopEvent?
            if let plannedStopDepartureTime = plannedStopDepartureTime {
                departure = StopEvent(location: stopLocation, plannedTime: plannedStopDepartureTime, predictedTime: predictedStopDepartureTime, plannedPlatform: stopPosition, predictedPlatform: nil, cancelled: departureCancelled)
            } else {
                departure = nil
            }
            let arrival: StopEvent?
            if let plannedStopArrivalTime = plannedStopArrivalTime {
                arrival = StopEvent(location: stopLocation, plannedTime: plannedStopArrivalTime, predictedTime: predictedStopArrivalTime, plannedPlatform: stopPosition, predictedPlatform: nil, cancelled: arrivalCancelled)
            } else {
                arrival = nil
            }
            
            let stop = Stop(location: stopLocation, departure: departure, arrival: arrival, message: nil)
            stops.append(stop)
        }
        
        let departure: StopEvent
        let arrival: StopEvent
        if stops.count >= 2 {
            if !stops.last!.location.isEqual(arrivalLocation) {
                throw ParseError(reason: "last intermediate stop is not arrival location!")
            }
            let a = stops.removeLast()
            // workaround for MVV sending wrong position for arrival and departure locations in intermediate stops
            // still use the time of the intermediate point because arrival and departure time is *always* sent as predicted, even when its not
            arrival = StopEvent(location: a.location, plannedTime: a.arrival?.plannedTime ?? arrivalTime, predictedTime: a.arrival?.predictedTime, plannedPlatform: plannedArrivalPosition ?? a.arrival?.plannedPlatform, predictedPlatform: a.arrival?.predictedPlatform, cancelled: a.arrival?.cancelled ?? cancelled)
            arrival.message = a.message
            
            if !stops.first!.location.isEqual(departureLocation) {
                throw ParseError(reason: "first intermediate stop is not departure location!")
            }
            let d = stops.removeFirst()
            departure = StopEvent(location: d.location, plannedTime: d.departure?.plannedTime ?? departureTime, predictedTime: d.departure?.predictedTime, plannedPlatform: plannedDeparturePosition ?? d.departure?.plannedPlatform, predictedPlatform: d.departure?.predictedPlatform, cancelled: d.departure?.cancelled ?? cancelled)
            departure.message = d.message
        } else {
            departure = StopEvent(location: departureLocation, plannedTime: departureTargetTime ?? departureTime, predictedTime: departureTargetTime == nil ? nil : departureTime, plannedPlatform: departurePosition, predictedPlatform: nil, cancelled: cancelled)
            arrival = StopEvent(location: arrivalLocation, plannedTime: arrivalTargetTime ?? arrivalTime, predictedTime: arrivalTargetTime == nil ? nil : arrivalTime, plannedPlatform: arrivalPosition, predictedPlatform: nil, cancelled: cancelled)
        }
        
        let path = processItdPathCoordinates(xml["itdPathCoordinates"])
        
        var lineAttrs: [Line.Attr] = []
        if lowFloorVehicle {
            lineAttrs.append(Line.Attr.wheelChairAccess)
        }
        
        let styledLine = Line(id: line.id, network: line.network, product: line.product, label: line.label, name: line.label, number: number, vehicleNumber: trainNum, style: lineStyle(network: divaNetwork, product: line.product, label: line.label), attr: lineAttrs, message: nil)
        
        let journeyContext: EfaJourneyContext?
        if let departureId = departureLocation.id, let tripCode = tripCode, styledLine.id != nil {
            journeyContext = EfaJourneyContext(stopId: departureId, stopDepartureTime: departureTargetTime ?? departureTime, line: styledLine, tripCode: tripCode)
        } else {
            journeyContext = nil
        }
        
        legs.append(PublicLeg(line: styledLine, destination: destination, departure: departure, arrival: arrival, intermediateStops: stops, message: messages.joined(separator: "\n").emptyToNil, path: path ?? [], journeyContext: journeyContext, wagonSequenceContext: nil, loadFactor: nil))
        return cancelled
    }
    
    func processIndividualLeg(_ xml: XMLIndexer, _ legs: inout [Leg], _ type: IndividualLeg.`Type`, _ departureTime: Date, _ departureLocation: Location, _ arrivalTime: Date, _ arrivalLocation: Location) {
        var path: [LocationPoint] = processItdPathCoordinates(xml["itdPathCoordinates"]) ?? []
        
        let addTime: TimeInterval = !legs.isEmpty ? max(0, -departureTime.timeIntervalSince(legs.last!.maxTime)) : 0
        if let lastLeg = legs.last as? IndividualLeg, lastLeg.type == type {
            legs.removeLast()
            path.insert(contentsOf: lastLeg.path, at: 0)
            legs.append(IndividualLeg(type: type, departureTime: lastLeg.departureTime, departure: lastLeg.departure, arrival: arrivalLocation, arrivalTime: arrivalTime.addingTimeInterval(addTime), distance: 0, path: path))
        } else {
            let leg = IndividualLeg(type: type, departureTime: departureTime.addingTimeInterval(addTime), departure: departureLocation, arrival: arrivalLocation, arrivalTime: arrivalTime.addingTimeInterval(addTime), distance: 0, path: path)
            legs.append(leg)
        }
    }
    
    func parseLine(xml: XMLIndexer) -> (line: Line, destination: Location?, cancelled: Bool)? {
        guard let motType = xml.element?.attribute(by: "motType")?.text else {
            os_log("%{public}@: failed to parse line type", log: .requestLogger, type: .error, #function)
            return nil
        }
        let symbol = xml.element?.attribute(by: "symbol")?.text
        let number = xml.element?.attribute(by: "number")?.text
        let stateless = xml.element?.attribute(by: "stateless")?.text
        var trainType = xml.element?.attribute(by: "trainType")?.text
        var trainName = xml.element?.attribute(by: "trainName")?.text
        let trainNum = xml.element?.attribute(by: "trainNum")?.text
        let network = xml["motDivaParams"].element?.attribute(by: "network")?.text
        let dir = xml["motDivaParams"].element?.attribute(by: "direction")?.text
        let direction: Line.Direction?
        if let dir = dir {
            switch dir {
            case "H": direction = .outward
            case "R": direction = .return
            default:  direction = nil
            }
        } else {
            direction = nil
        }
        
        var delay: String? = nil
        var message: String = ""
        if let train = xml["itdTrain"].element {
            if let name = train.attribute(by: "name")?.text {
                trainName = name
            }
            if let type = train.attribute(by: "type")?.text {
                trainType = type
            }
            delay = train.attribute(by: "delay")?.text
        }
        if let train = xml["itdNoTrain"].element {
            if let name = train.attribute(by: "name")?.text {
                trainName = name
            }
            if let type = train.attribute(by: "type")?.text {
                trainType = type
            }
            delay = train.attribute(by: "delay")?.text
            if let trainName = trainName, trainName.lowercased().contains("ruf") {
                message = train.text
            } else if train.text.lowercased().contains("ruf") {
                message = train.text
            }
        }
        
        let line = self.parseLine(id: stateless, network: network, mot: motType, symbol: symbol, name: number, longName: number, trainType: trainType, trainNum: trainNum, trainName: trainName)
        
        let destinationIdStr = xml.element?.attribute(by: "destID")?.text
        let destinationId = "-1" != destinationIdStr ? destinationIdStr : nil
        var destinationName = stripLineFromDestination(line: line, destinationName: xml.element?.attribute(by: "direction")?.text)
        if let destination = destinationName, destination.hasSuffix(" EILZUG") {
            destinationName = String(destination.dropLast(" EILZUG".count))
            if message.isEmpty {
                message = "Eilzug: Zug hält nicht überall."
            } else {
                message = "Eilzug: Zug hält nicht überall.\n" + message
            }
        }
        let nameAndPlace = split(directionName: destinationName)
        let destination: Location?
        if let id = destinationId, id != "" {
            destination = Location(type: .station, id: id, coord: nil, place: nameAndPlace.place, name: nameAndPlace.name)
        } else {
            if let name = nameAndPlace.name {
                destination = Location(type: .any, id: nil, coord: nil, place: nameAndPlace.place, name: name)
            } else {
                destination = nil
            }
        }
        
        let cancelled = delay == "-9999"
        
        return (Line(id: line.id, network: line.network, product: line.product, label: line.label, name: nil, number: number, vehicleNumber: trainNum, style: self.lineStyle(network: line.network, product: line.product, label: line.label), attr: nil, message: message.emptyToNil, direction: direction), destination, cancelled)
    }
    
    func processItdPathCoordinates(_ xml: XMLIndexer) -> [LocationPoint]? {
        guard let coordEllipsoid = xml["coordEllipsoid"].element?.text, coordEllipsoid == "WGS84", let type = xml["coordType"].element?.text, type == "GEO_DECIMAL" else { return nil }
        
        if let coordString = xml["itdCoordinateString"].element?.text {
            return processCoordinateStrings(coordString)
        } else if xml["itdCoordinateBaseElemList"].all.count > 0 {
            return processCoordinateBaseElems(xml)
        }
        return nil
    }
    
    func processCoordinateBaseElems(_ xml: XMLIndexer) -> [LocationPoint] {
        var path: [LocationPoint] = []
        for elem in xml["itdCoordinateBaseElemList"].children {
            guard let latStr = elem["y"].element?.text, let lonStr = elem["x"].element?.text else { continue }
            guard let latDouble = Double(latStr), let lonDouble = Double(lonStr) else { continue }
            let lat = Int(round(latDouble))
            let lon = Int(round(lonDouble))
            path.append(LocationPoint(lat: lat, lon: lon))
        }
        return path
    }
    
    func parseDate(xml: XMLIndexer) -> Date? {
        let date = xml["itdDate"]
        let time = xml["itdTime"]
        
        guard let yearStr = date.element?.attribute(by: "year")?.text, let year = Int(yearStr), let monthStr = date.element?.attribute(by: "month")?.text, let month = Int(monthStr), let dayStr = date.element?.attribute(by: "day")?.text, let day = Int(dayStr), let hourStr = time.element?.attribute(by: "hour")?.text, let hour = Int(hourStr), let minuteStr = time.element?.attribute(by: "minute")?.text, let minute = Int(minuteStr) else {
            return nil
        }
        var dateComponents = DateComponents()
        dateComponents.timeZone = timeZone
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        dateComponents.hour = hour
        dateComponents.minute = minute
        return NSCalendar(calendarIdentifier: .gregorian)?.date(from: dateComponents)
    }
    
    func processItdDateTime(xml: XMLIndexer) -> Date? {
        let date = xml["itdDate"].element
        let time = xml["itdTime"].element
        guard let year = Int(date?.attribute(by: "year")?.text ?? ""), let month = Int(date?.attribute(by: "month")?.text ?? ""), let day = Int(date?.attribute(by: "day")?.text ?? ""), let hour = Int(time?.attribute(by: "hour")?.text ?? ""), let minute = Int(time?.attribute(by: "minute")?.text ?? "") else { return nil }
        
        if year == 0 || day == -1 || hour == -1 || minute == -1 {
            return nil
        }
        //        let second = Int(time?.attribute(by: "second")?.text ?? "") ?? 0
        
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        dateComponents.hour = hour
        dateComponents.minute = minute
        //        dateComponents.second = second
        dateComponents.timeZone = timeZone
        return NSCalendar(calendarIdentifier: .gregorian)?.date(from: dateComponents)
    }
    
    func processCoordAttr(odv: XMLIndexer) -> LocationPoint? {
        guard let mapName = odv.element?.attribute(by: "mapName")?.text, mapName == "WGS84" else { return nil }
        
        guard let latText = odv.element?.attribute(by: "y")?.text, let lonText = odv.element?.attribute(by: "x")?.text else { return nil }
        guard let lat = Double(latText), let lon = Double(lonText) else { return nil }
        
        return LocationPoint(lat: Int(round(lat)), lon: Int(round(lon)))
    }
    
}
