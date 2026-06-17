import Foundation
import os.log
import SWXMLHash

/// Base class for all providers using the Open Journey Planner (OJP) 2.0 API.
///
/// OJP is a SIRI-based XML protocol developed by the VDV. All requests are sent as an XML
/// `POST` body to a single endpoint, wrapped in an `<OJP>` / `<OJPRequest>` / `<siri:ServiceRequest>`
/// envelope. The following OJP services are used:
///
/// - `OJPLocationInformationRequest` for location suggestions and nearby locations
/// - `OJPTripRequest` for trip queries
/// - `OJPTripRefineRequest` for refreshing a trip (including its geographic projection)
/// - `OJPTripInfoRequest` for journey details
/// - `OJPStopEventRequest` for departure boards
public class AbstractOjpProvider: AbstractNetworkProvider {

    override public var supportedQueryTraits: Set<QueryTrait> { [] }

    /// The single endpoint all OJP requests are posted to.
    let apiEndpoint: String
    /// Value of the SIRI `RequestorRef` element, identifying the client to the server.
    var requestorRef: String = "TripKit"
    /// Maps an OJP `ProductCategoryRef` value to a ``Product``. May be overridden by subclasses.
    var productsByCategoryRef: [String: Product] = [:]
    /// Additional HTTP headers sent with every request (e.g. an API key).
    var requestHeaders: [String: String] = [:]

    static let SERVER_PRODUCT = "ojp"

    /// Splits a "Place, Name" string into its place and name parts.
    var P_SPLIT_NAME_FIRST_COMMA: NSRegularExpression { return try! NSRegularExpression(pattern: "^(?:([^,]*), (?!$))?([^,]*)(?:, )?$") }

    init(networkId: NetworkId, apiEndpoint: String) {
        self.apiEndpoint = apiEndpoint
        super.init(networkId: networkId)
    }

    // MARK: Date formatting

    /// ISO 8601 formatter producing/consuming UTC timestamps as used by OJP (e.g. `2026-06-16T11:18:34Z`).
    private lazy var dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    /// Formatter for an OperatingDayRef (e.g. `2026-06-16`).
    private lazy var operatingDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    func formatDate(_ date: Date) -> String {
        return dateTimeFormatter.string(from: date)
    }

    func parseDate(_ string: String?) -> Date? {
        guard let string = string else { return nil }
        // OJP timestamps may contain fractional seconds and/or an explicit time zone offset.
        // Strip everything except the second to normalize to the base formatter.
        if let date = dateTimeFormatter.date(from: string) {
            return date
        }
        return AbstractOjpProvider.flexibleDateFormatter.date(from: string)
    }

    private static let flexibleDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    func formatOperatingDay(_ date: Date) -> String {
        return operatingDayFormatter.string(from: date)
    }

    /// Parses an ISO 8601 duration (e.g. `PT13M`, `PT1H4M30S`) into seconds.
    func parseDuration(_ string: String?) -> TimeInterval {
        guard let string = string, string.hasPrefix("PT") else { return 0 }
        var result: TimeInterval = 0
        if let match = string.match(pattern: AbstractOjpProvider.P_DURATION) {
            if let h = match[0], let hours = Double(h) { result += hours * 3600 }
            if let m = match[1], let minutes = Double(m) { result += minutes * 60 }
            if let s = match[2], let seconds = Double(s) { result += seconds }
        }
        return result
    }

    static let P_DURATION = try! NSRegularExpression(pattern: "PT(?:(\\d+)H)?(?:(\\d+)M)?(?:(\\d+)S)?")

    // MARK: Request envelope

    /// Wraps the given OJP service request element in the common OJP/SIRI envelope and serializes it.
    func wrapRequest(serviceRequest: OjpXmlElement) -> String {
        let ojp = OjpXmlElement("OJP")
            .attribute("xmlns:siri", "http://www.siri.org.uk/siri")
            .attribute("xmlns:xsi", "http://www.w3.org/2001/XMLSchema-instance")
            .attribute("xmlns", "http://www.vdv.de/ojp")
            .attribute("version", "2.0")
        let serviceRequestElement = OjpXmlElement("siri:ServiceRequest")
            .add(OjpXmlElement("siri:ServiceRequestContext")
                .addLeaf("siri:Language", queryLanguage ?? defaultLanguage))
            .addLeaf("siri:RequestTimestamp", formatDate(Date()))
            .addLeaf("siri:RequestorRef", requestorRef)
            .add(serviceRequest)
        ojp.add(OjpXmlElement("OJPRequest").add(serviceRequestElement))
        return "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" + ojp.serialize()
    }

    /// Builds an ``HttpRequest`` that posts the given OJP service request to the endpoint.
    func makeOjpRequest(serviceRequest: OjpXmlElement) -> HttpRequest {
        let urlBuilder = UrlBuilder(path: apiEndpoint, encoding: .utf8)
        return HttpRequest(urlBuilder: urlBuilder)
            .setPostPayload(wrapRequest(serviceRequest: serviceRequest))
            .setContentType("application/xml")
            .setHeaders(requestHeaders.isEmpty ? nil : requestHeaders)
    }

    // MARK: Authorization

    /// Authorizes an outgoing request before it is sent.
    ///
    /// The default implementation applies the static ``requestHeaders`` and proceeds immediately.
    /// OJP itself does not mandate any authentication scheme, so providers whose endpoint is secured
    /// (e.g. with an OAuth2 bearer token) override this to inject credentials — potentially after an
    /// asynchronous token fetch. Implementations must eventually call `completion` exactly once,
    /// either with the (possibly mutated) request to proceed, or with an error to abort.
    func authorizeRequest(_ httpRequest: HttpRequest, completion: @escaping (Result<HttpRequest, Error>) -> Void) {
        completion(.success(httpRequest))
    }

    /// Authorizes and then performs an OJP request, returning a cancellable handle immediately.
    ///
    /// Because authorization may itself be asynchronous (fetching a token), the returned
    /// ``AsyncRequest`` is a proxy: its underlying task is filled in once the actual OJP request
    /// starts, so callers can still cancel an in-flight (or pending) request.
    func performOjpRequest(serviceRequest: OjpXmlElement, parseHandler: @escaping (HttpRequest) throws -> Void, errorHandler: @escaping (HttpRequest, Error) -> Void, caller: String = #function) -> AsyncRequest {
        let httpRequest = makeOjpRequest(serviceRequest: serviceRequest)
        let proxy = AsyncRequest(task: nil)
        authorizeRequest(httpRequest) { result in
            switch result {
            case .success(let authorizedRequest):
                let request = self.makeRequest(authorizedRequest, parseHandler: {
                    try parseHandler(authorizedRequest)
                }, errorHandler: { err in
                    errorHandler(authorizedRequest, err)
                }, caller: caller)
                proxy.task = request.task
            case .failure(let error):
                errorHandler(httpRequest, error)
            }
        }
        return proxy
    }

    // MARK: Common XML helpers

    /// Reads a localized `<Text>` element. OJP nests display strings in `<...><Text>value</Text></...>`.
    func text(_ indexer: XMLIndexer) -> String? {
        return indexer["Text"].element?.text.emptyToNil ?? indexer.element?.text.emptyToNil
    }

    /// Parses a `<GeoPosition>` (or any element containing `siri:Longitude`/`siri:Latitude`).
    func parseCoord(_ indexer: XMLIndexer) -> LocationPoint? {
        guard
            let lonString = indexer["siri:Longitude"].element?.text, let lon = Double(lonString),
            let latString = indexer["siri:Latitude"].element?.text, let lat = Double(latString)
        else { return nil }
        return LocationPoint(lat: Int(round(lat * 1e6)), lon: Int(round(lon * 1e6)))
    }

    /// Maps an OJP `<Service>` to a ``Product``.
    ///
    /// OJP exposes the means of transport in several places. We prefer the most specific one:
    /// an explicit `ProductCategoryRef` mapping, then the human-readable product category, then
    /// the `Mode`/`Submode` pair as a fallback.
    func parseProduct(ptMode: String?, subMode: String?, categoryRef: String?, categoryName: String?, categoryShortName: String?) -> Product? {
        if let categoryRef = categoryRef, let product = productsByCategoryRef[categoryRef] {
            return product
        }
        // The product category name is the most reliable signal across CH operators.
        let category = (categoryName ?? "").lowercased()
        if category.contains("s-bahn") || category == "s" || categoryShortName?.lowercased() == "s" {
            return .suburbanTrain
        }
        if category.contains("intercity") || category.contains("eurocity") || category.contains("ice") || category.contains("tgv") || category.contains("railjet") || category.contains("hochgeschwindigkeit") {
            return .highSpeedTrain
        }

        switch ptMode {
        case "rail":
            switch subMode {
            case "highSpeedRail", "longDistance", "internationalRail", "interregionalRail":
                return .highSpeedTrain
            case "suburbanRailway", "s-bahn":
                return .suburbanTrain
            default:
                return .regionalTrain
            }
        case "urbanRail", "metro":
            return .subway
        case "tram":
            return .tram
        case "bus", "coach":
            return .bus
        case "water", "ferry":
            return .ferry
        case "telecabin", "funicular", "cableway":
            return .cablecar
        default:
            return nil
        }
    }

    /// Hook for subclasses to customize line naming (mirrors the Hafas providers' `newLine`).
    func newLine(id: String?, network: String?, product: Product?, name: String?, shortName: String?, number: String?, vehicleNumber: String?, direction: Line.Direction?, style: LineStyle) -> Line {
        return Line(id: id, network: network, product: product, label: name, name: name, number: number, vehicleNumber: vehicleNumber, style: style, attr: nil, message: nil, direction: direction)
    }

    func parseDirection(_ string: String?) -> Line.Direction? {
        switch string {
        case "H":
            return .outward
        case "R":
            return .return
        default:
            return nil
        }
    }

    // MARK: Location parsing

    /// Parses a `<Place>` element (as returned within a `PlaceResult` or `TripResponseContext/Places`).
    func parsePlace(_ place: XMLIndexer) -> Location? {
        let coord = parseCoord(place["GeoPosition"])

        if place["StopPlace"].element != nil {
            let stopPlace = place["StopPlace"]
            let id = stopPlace["StopPlaceRef"].element?.text.emptyToNil
            let name = text(stopPlace["StopPlaceName"]) ?? text(place["Name"])
            let (placeName, locationName) = split(stationName: name)
            return Location(type: .station, id: id, coord: coord, place: placeName, name: locationName)
        } else if place["StopPoint"].element != nil {
            let stopPoint = place["StopPoint"]
            let id = stopPoint["siri:StopPointRef"].element?.text.emptyToNil
            let name = text(stopPoint["StopPointName"]) ?? text(place["Name"])
            let (placeName, locationName) = split(stationName: name)
            return Location(type: .station, id: id, coord: coord, place: placeName, name: locationName)
        } else if place["Address"].element != nil {
            let address = place["Address"]
            let id = address["PublicCode"].element?.text.emptyToNil
            let name = text(address["Name"]) ?? text(place["Name"])
            let (placeName, locationName) = split(address: name)
            return Location(type: .address, id: id, coord: coord, place: placeName, name: locationName)
        } else if place["TopographicPlace"].element != nil {
            let name = text(place["TopographicPlace"]["TopographicPlaceName"]) ?? text(place["Name"])
            return Location(type: .poi, id: nil, coord: coord, place: nil, name: name)
        } else {
            // Fallback: use the generic name and coordinate, if any.
            let name = text(place["Name"])
            return Location(type: coord != nil ? .coord : .any, id: nil, coord: coord, place: nil, name: name)
        }
    }

    /// Splits a combined station name (e.g. `Bern, Hauptbahnhof`) into place and name.
    /// May be overridden by subclasses.
    func split(stationName: String?) -> (place: String?, name: String?) {
        return (nil, stationName)
    }

    func split(poi: String?) -> (place: String?, name: String?) {
        return (nil, poi)
    }

    func split(address: String?) -> (place: String?, name: String?) {
        return (nil, address)
    }

    // MARK: PlaceRef encoding (request side)

    /// Encodes a ``Location`` as an OJP `<PlaceRef>`, used as origin/destination/via in requests.
    func encodePlaceRef(_ location: Location) -> OjpXmlElement {
        let placeRef = OjpXmlElement("PlaceRef")
        if let id = location.id {
            placeRef.addLeaf("StopPlaceRef", id)
        } else if let coord = location.coord {
            placeRef.add(OjpXmlElement("GeoPosition")
                .addLeaf("siri:Longitude", String(Double(coord.lon) / 1e6))
                .addLeaf("siri:Latitude", String(Double(coord.lat) / 1e6)))
        }
        placeRef.add(OjpXmlElement("Name").addLeaf("Text", location.getUniqueLongName()))
        return placeRef
    }

    // MARK: NetworkProvider request methods

    public override func suggestLocations(constraint: String, types: [LocationType]?, maxLocations: Int, completion: @escaping (HttpRequest, SuggestLocationsResult) -> Void) -> AsyncRequest {
        let request = OjpXmlElement("OJPLocationInformationRequest")
            .addLeaf("siri:RequestTimestamp", formatDate(Date()))
            .add(OjpXmlElement("InitialInput").addLeaf("Name", constraint))
            .add(locationRestrictions(types: types, maxLocations: maxLocations))
        return performOjpRequest(serviceRequest: request) { httpRequest in
            try self.suggestLocationsParsing(request: httpRequest, constraint: constraint, types: types, maxLocations: maxLocations, completion: completion)
        } errorHandler: { httpRequest, err in
            completion(httpRequest, .failure(err))
        }
    }

    public override func queryNearbyLocations(location: Location, types: [LocationType]?, maxDistance: Int, maxLocations: Int, completion: @escaping (HttpRequest, NearbyLocationsResult) -> Void) -> AsyncRequest {
        guard let coord = location.coord else {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .invalidId)
            return AsyncRequest(task: nil)
        }
        let radius = maxDistance > 0 ? maxDistance : 1000
        let request = OjpXmlElement("OJPLocationInformationRequest")
            .addLeaf("siri:RequestTimestamp", formatDate(Date()))
            .add(OjpXmlElement("InitialInput")
                .add(OjpXmlElement("GeoRestriction")
                    .add(OjpXmlElement("Circle")
                        .add(OjpXmlElement("Center")
                            .addLeaf("siri:Longitude", String(Double(coord.lon) / 1e6))
                            .addLeaf("siri:Latitude", String(Double(coord.lat) / 1e6)))
                        .addLeaf("Radius", String(radius)))))
            .add(locationRestrictions(types: types, maxLocations: maxLocations))
        return performOjpRequest(serviceRequest: request) { httpRequest in
            try self.queryNearbyLocationsByCoordinateParsing(request: httpRequest, location: location, types: types, maxDistance: maxDistance, maxLocations: maxLocations, completion: completion)
        } errorHandler: { httpRequest, err in
            completion(httpRequest, .failure(err))
        }
    }

    public override func queryDepartures(stationId: String, departures: Bool, time: Date?, maxDepartures: Int, equivs: Bool, completion: @escaping (HttpRequest, QueryDeparturesResult) -> Void) -> AsyncRequest {
        // Inferred from the OJP 2.0 specification: a departure board is requested using an
        // OJPStopEventRequest with a PlaceRef pointing at the requested stop.
        let number = maxDepartures > 0 ? maxDepartures : numTripsRequested
        let request = OjpXmlElement("OJPStopEventRequest")
            .addLeaf("siri:RequestTimestamp", formatDate(Date()))
            .add(OjpXmlElement("Location")
                .add(OjpXmlElement("PlaceRef").addLeaf("StopPlaceRef", stationId))
                .addLeaf("DepArrTime", formatDate(time ?? Date())))
            .add(OjpXmlElement("Params")
                .addLeaf("NumberOfResults", String(number))
                .addLeaf("StopEventType", departures ? "departure" : "arrival")
                .addLeaf("IncludePreviousCalls", "false")
                .addLeaf("IncludeOnwardCalls", "false")
                .addLeaf("IncludeRealtimeData", "true"))
        return performOjpRequest(serviceRequest: request) { httpRequest in
            try self.queryDeparturesParsing(request: httpRequest, stationId: stationId, departures: departures, time: time, maxDepartures: maxDepartures, equivs: equivs, completion: completion)
        } errorHandler: { httpRequest, err in
            completion(httpRequest, .failure(err))
        }
    }

    public override func queryTrips(from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        return doQueryTrips(from: from, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions, previousContext: nil, later: false, completion: completion)
    }

    public override func queryMoreTrips(context: QueryTripsContext, later: Bool, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        guard let context = context as? Context else {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .sessionExpired)
            return AsyncRequest(task: nil)
        }
        let date = later ? context.lastDepartureTime : context.firstArrivalTime
        return doQueryTrips(from: context.from, via: context.via, to: context.to, date: date, departure: later, tripOptions: context.tripOptions, previousContext: context, later: later, completion: completion)
    }

    private func doQueryTrips(from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions, previousContext: Context?, later: Bool, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        let origin = OjpXmlElement("Origin").add(encodePlaceRef(from))
        if departure { origin.addLeaf("DepArrTime", formatDate(date)) }
        let destination = OjpXmlElement("Destination").add(encodePlaceRef(to))
        if !departure { destination.addLeaf("DepArrTime", formatDate(date)) }

        let request = OjpXmlElement("OJPTripRequest")
            .addLeaf("siri:RequestTimestamp", formatDate(Date()))
            .add(origin)
            .add(destination)
        if let via = via {
            request.add(OjpXmlElement("Via").add(OjpXmlElement("ViaPoint").add(encodePlaceRef(via))))
        }
        let params = OjpXmlElement("Params")
            .addLeaf("NumberOfResults", String(numTripsRequested))
            .addLeaf("IncludeLegProjection", "true")
            .addLeaf("IncludeTrackSections", "true")
            .addLeaf("IncludeIntermediateStops", "true")
            .addLeaf("IncludeAllRestrictedLines", "true")
            .addLeaf("UseRealtimeData", "explanatory")
        if let modeFilter = ptModeFilter(tripOptions: tripOptions) {
            params.add(modeFilter)
        }
        request.add(params)
        return performOjpRequest(serviceRequest: request) { httpRequest in
            try self.queryTripsParsing(request: httpRequest, from: from, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions, previousContext: previousContext, later: later, completion: completion)
        } errorHandler: { httpRequest, err in
            completion(httpRequest, .failure(err))
        }
    }

    public override func refreshTrip(context: RefreshTripContext, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        guard let context = context as? OjpRefreshTripContext else {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .sessionExpired)
            return AsyncRequest(task: nil)
        }
        // The original <TripResult> element is echoed back verbatim, so it is inserted as raw XML.
        let request = OjpXmlElement("OJPTripRefineRequest")
            .addLeaf("siri:RequestTimestamp", formatDate(Date()))
            .add(OjpXmlElement("RefineParams")
                .addLeaf("NumberOfResults", "1")
                .addLeaf("IncludeTrackSections", "true")
                .addLeaf("IncludeLegProjection", "true")
                .addLeaf("IncludeIntermediateStops", "true")
                .addLeaf("IncludeAllRestrictedLines", "true")
                .addLeaf("UseRealtimeData", "explanatory"))
            .add(OjpRawXmlElement(rawXml: context.tripResultXml))
        return performOjpRequest(serviceRequest: request) { httpRequest in
            try self.refreshTripParsing(request: httpRequest, context: context, completion: completion)
        } errorHandler: { httpRequest, err in
            completion(httpRequest, .failure(err))
        }
    }

    public override func queryJourneyDetail(context: QueryJourneyDetailContext, completion: @escaping (HttpRequest, QueryJourneyDetailResult) -> Void) -> AsyncRequest {
        guard let context = context as? OjpJourneyContext else {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .invalidId)
            return AsyncRequest(task: nil)
        }
        let request = OjpXmlElement("OJPTripInfoRequest")
            .addLeaf("JourneyRef", context.journeyRef)
            .addLeaf("OperatingDayRef", context.operatingDayRef)
            .add(OjpXmlElement("Params")
                .addLeaf("UseRealTimeData", "explanatory")
                .addLeaf("IncludeCalls", "true")
                .addLeaf("IncludeService", "true")
                .addLeaf("IncludeTrackSections", "true")
                .addLeaf("IncludeTrackProjection", "true")
                .addLeaf("IncludePlacesContext", "false")
                .addLeaf("IncludeSituationsContext", "true"))
        return performOjpRequest(serviceRequest: request) { httpRequest in
            try self.queryJourneyDetailParsing(request: httpRequest, context: context, completion: completion)
        } errorHandler: { httpRequest, err in
            completion(httpRequest, .failure(err))
        }
    }

    // MARK: Request helpers

    /// Builds the `<Restrictions>` element shared by the location-information requests.
    private func locationRestrictions(types: [LocationType]?, maxLocations: Int) -> OjpXmlElement {
        let restrictions = OjpXmlElement("Restrictions")
        for type in ojpLocationTypes(from: types) {
            restrictions.addLeaf("Type", type)
        }
        restrictions.addLeaf("NumberOfResults", String(maxLocations > 0 ? maxLocations : 40))
        restrictions.addLeaf("IncludePtModes", "true")
        return restrictions
    }

    private func ojpLocationTypes(from types: [LocationType]?) -> [String] {
        guard let types = types, !types.contains(.any) else { return ["stop", "address"] }
        var result: [String] = []
        if types.contains(.station) { result.append("stop") }
        if types.contains(.poi) { result.append("poi") }
        if types.contains(.address) || types.contains(.coord) { result.append("address") }
        return result.isEmpty ? ["stop"] : result
    }

    /// Restricts the requested products. OJP exposes this through `<ModeFilter>`.
    private func ptModeFilter(tripOptions: TripOptions) -> OjpXmlElement? {
        guard let products = tripOptions.products, !products.isEmpty, Set(products) != Set(Product.allCases) else { return nil }
        let modes = Set(products.compactMap { ptMode(for: $0) })
        guard !modes.isEmpty else { return nil }
        let filter = OjpXmlElement("ModeFilter").addLeaf("Exclude", "false")
        for mode in modes {
            filter.addLeaf("siri:PtMode", mode)
        }
        return filter
    }

    private func ptMode(for product: Product) -> String? {
        switch product {
        case .highSpeedTrain, .regionalTrain, .suburbanTrain:
            return "rail"
        case .subway:
            return "metro"
        case .tram:
            return "tram"
        case .bus, .onDemand:
            return "bus"
        case .ferry:
            return "water"
        case .cablecar:
            return "telecabin"
        }
    }

    // MARK: NetworkProvider parsing methods (override points)

    override func suggestLocationsParsing(request: HttpRequest, constraint: String, types: [LocationType]?, maxLocations: Int, completion: @escaping (HttpRequest, SuggestLocationsResult) -> Void) throws {
        guard let data = request.responseData else { throw ParseError(reason: "no response") }
        let xml = XMLHash.parse(data)
        let delivery = xml["OJP"]["OJPResponse"]["siri:ServiceDelivery"]["OJPLocationInformationDelivery"]

        var locations: [SuggestedLocation] = []
        for result in delivery["PlaceResult"].all {
            guard let location = parsePlace(result["Place"]) else { continue }
            let probability = Double(result["Probability"].element?.text ?? "") ?? 0
            locations.append(SuggestedLocation(location: location, priority: Int(probability * 1000)))
        }
        locations.sort { $0.priority > $1.priority }
        completion(request, .success(locations: locations))
    }

    override func queryNearbyLocationsByCoordinateParsing(request: HttpRequest, location: Location, types: [LocationType]?, maxDistance: Int, maxLocations: Int, completion: @escaping (HttpRequest, NearbyLocationsResult) -> Void) throws {
        guard let data = request.responseData else { throw ParseError(reason: "no response") }
        let xml = XMLHash.parse(data)
        let delivery = xml["OJP"]["OJPResponse"]["siri:ServiceDelivery"]["OJPLocationInformationDelivery"]

        var locations: [Location] = []
        for result in delivery["PlaceResult"].all {
            guard let location = parsePlace(result["Place"]) else { continue }
            locations.append(location)
        }
        completion(request, .success(locations: locations))
    }

    override func queryDeparturesParsing(request: HttpRequest, stationId: String, departures: Bool, time: Date?, maxDepartures: Int, equivs: Bool, completion: @escaping (HttpRequest, QueryDeparturesResult) -> Void) throws {
        guard let data = request.responseData else { throw ParseError(reason: "no response") }
        let xml = XMLHash.parse(data)
        let delivery = xml["OJP"]["OJPResponse"]["siri:ServiceDelivery"]["OJPStopEventDelivery"]
        let placesById = indexPlaces(delivery["StopEventResponseContext"]["Places"])

        var resultDepartures: [Departure] = []
        var stopLocation: Location?

        for result in delivery["StopEventResult"].all {
            let stopEvent = result["StopEvent"]
            let call = stopEvent["ThisCall"]["CallAtStop"]

            guard let location = parseCallLocation(call, placesById: placesById) else { continue }
            if stopLocation == nil {
                stopLocation = location
            }

            let timeNode = departures ? call["ServiceDeparture"] : call["ServiceArrival"]
            guard let plannedTime = parseDate(timeNode["TimetabledTime"].element?.text) else { continue }
            let predictedTime = parseDate(timeNode["EstimatedTime"].element?.text)
            let plannedPlatform = text(call["PlannedQuay"])
            let predictedPlatform = text(call["EstimatedQuay"])

            let service = stopEvent["Service"]
            let line = parseLine(from: service)
            let destination = parseServiceDestination(from: service)
            let journeyContext = makeJourneyContext(from: service)

            let departure = Departure(plannedTime: plannedTime, predictedTime: predictedTime, line: line, position: predictedPlatform, plannedPosition: plannedPlatform, cancelled: false, destination: destination, capacity: nil, message: nil, journeyContext: journeyContext)
            resultDepartures.append(departure)
        }

        guard let stopLocation = stopLocation else {
            if resultDepartures.isEmpty {
                completion(request, .success(departures: []))
                return
            }
            throw ParseError(reason: "failed to parse departure stop")
        }
        let stationDepartures = StationDepartures(stopLocation: stopLocation, departures: resultDepartures, lines: [])
        completion(request, .success(departures: [stationDepartures]))
    }

    override func queryTripsParsing(request: HttpRequest, from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions, previousContext: QueryTripsContext?, later: Bool, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) throws {
        guard let data = request.responseData else { throw ParseError(reason: "no response") }
        let responseString = String(data: data, encoding: .utf8) ?? ""
        let xml = XMLHash.parse(data)
        let delivery = xml["OJP"]["OJPResponse"]["siri:ServiceDelivery"]["OJPTripDelivery"]

        // Index all places of the response context by their ref, so legs can resolve coordinates.
        let placesById = indexPlaces(delivery["TripResponseContext"]["Places"])

        var trips: [Trip] = []
        for result in delivery["TripResult"].all {
            guard let trip = try parseTrip(result, placesById: placesById, responseString: responseString, tripOptions: tripOptions) else { continue }
            trips.append(trip)
        }

        if trips.isEmpty {
            completion(request, .noTrips)
            return
        }

        let previous = previousContext as? Context
        let context: Context
        if let previous = previous {
            context = Context(from: previous.from, via: previous.via, to: previous.to, tripOptions: previous.tripOptions, firstArrivalTime: later ? previous.firstArrivalTime : trips.first!.minTime, lastDepartureTime: later ? trips.last!.maxTime : previous.lastDepartureTime)
        } else {
            context = Context(from: from, via: via, to: to, tripOptions: tripOptions, firstArrivalTime: trips.first!.minTime, lastDepartureTime: trips.last!.maxTime)
        }
        completion(request, .success(context: context, from: from, via: via, to: to, trips: trips, messages: []))
    }

    override func refreshTripParsing(request: HttpRequest, context: RefreshTripContext, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) throws {
        guard let context = context as? OjpRefreshTripContext else { throw ParseError(reason: "illegal context") }
        guard let data = request.responseData else { throw ParseError(reason: "no response") }
        let responseString = String(data: data, encoding: .utf8) ?? ""
        let xml = XMLHash.parse(data)
        let serviceDelivery = xml["OJP"]["OJPResponse"]["siri:ServiceDelivery"]
        // A refine request answers with an OJPTripRefineDelivery; a plain trip request with OJPTripDelivery.
        let delivery = serviceDelivery["OJPTripRefineDelivery"].element != nil ? serviceDelivery["OJPTripRefineDelivery"] : serviceDelivery["OJPTripDelivery"]
        let placesById = indexPlaces(delivery["TripResponseContext"]["Places"])

        for result in delivery["TripResult"].all {
            guard let trip = try parseTrip(result, placesById: placesById, responseString: responseString, tripOptions: context.tripOptions) else { continue }
            completion(request, .success(context: nil, from: trip.from, via: nil, to: trip.to, trips: [trip], messages: []))
            return
        }
        completion(request, .noTrips)
    }

    override func queryJourneyDetailParsing(request: HttpRequest, context: QueryJourneyDetailContext, completion: @escaping (HttpRequest, QueryJourneyDetailResult) -> Void) throws {
        guard let data = request.responseData else { throw ParseError(reason: "no response") }
        let xml = XMLHash.parse(data)
        let delivery = xml["OJP"]["OJPResponse"]["siri:ServiceDelivery"]["OJPTripInfoDelivery"]
        let result = delivery["TripInfoResult"]
        let placesById = indexPlaces(delivery["TripInfoResponseContext"]["Places"])

        let service = result["Service"]
        let line = parseLine(from: service)
        let destination = parseServiceDestination(from: service)

        // PreviousCall + current + OnwardCall represent the full sequence of stops of the journey.
        var stops: [Stop] = []
        for call in result["PreviousCall"].all + result["CurrentCall"].all + result["OnwardCall"].all {
            guard let stop = parseCallAsStop(call, placesById: placesById) else { continue }
            stops.append(stop)
        }
        guard let firstStop = stops.first, let lastStop = stops.last,
              let departureEvent = firstStop.departure ?? firstStop.arrival,
              let arrivalEvent = lastStop.arrival ?? lastStop.departure else {
            completion(request, .invalidId)
            return
        }
        let intermediateStops = stops.count > 2 ? Array(stops[1..<stops.count - 1]) : []
        
        let path = parseJourneyProjection(result)

        let leg = PublicLeg(line: line, destination: destination, departure: departureEvent, arrival: arrivalEvent, intermediateStops: intermediateStops, message: nil, path: path, journeyContext: context, wagonSequenceContext: nil, loadFactor: nil)
        let trip = Trip(id: "", from: departureEvent.location, to: arrivalEvent.location, legs: [leg], duration: 0, fares: [])
        completion(request, .success(trip: trip, leg: leg))
    }

}

// MARK: - Response parsing

extension AbstractOjpProvider {

    // MARK: Trip parsing

    private func parseTrip(_ tripResultNode: XMLIndexer, placesById: [String: Location], responseString: String, tripOptions: TripOptions) throws -> Trip? {
        let tripNode = tripResultNode["Trip"]
        var legs: [Leg] = []
        for legNode in tripNode["Leg"].all {
            if legNode["TimedLeg"].element != nil {
                if let leg = try parseTimedLeg(legNode["TimedLeg"], placesById: placesById, tripOptions: tripOptions) {
                    legs.append(leg)
                }
            } else if legNode["TransferLeg"].element != nil {
                if let leg = parseTransferLeg(legNode["TransferLeg"], placesById: placesById, previousLeg: legs.last) {
                    legs.append(leg)
                }
            } else if legNode["ContinuousLeg"].element != nil {
                if let leg = parseTransferLeg(legNode["ContinuousLeg"], placesById: placesById, previousLeg: legs.last) {
                    legs.append(leg)
                }
            }
        }
        guard !legs.isEmpty else { return nil }

        let duration = parseDuration(tripNode["Duration"].element?.text)
        let tripId = tripNode["Id"].element?.text ?? ""

        // Build a refresh context from the raw <TripResult> element echoed back in a refine request.
        let refreshContext: OjpRefreshTripContext?
        if let resultXml = extractTripResultXml(id: tripId, from: responseString) {
            refreshContext = OjpRefreshTripContext(tripResultXml: resultXml, tripOptions: tripOptions)
        } else {
            refreshContext = nil
        }

        return Trip(id: tripId, from: legs.first!.departure, to: legs.last!.arrival, legs: legs, duration: duration, fares: [], refreshContext: refreshContext)
    }

    private func parseTimedLeg(_ timedLeg: XMLIndexer, placesById: [String: Location], tripOptions: TripOptions) throws -> PublicLeg? {
        let board = timedLeg["LegBoard"]
        let alight = timedLeg["LegAlight"]

        guard
            let departureStop = parseStopEvent(board, placesById: placesById, isDeparture: true),
            let arrivalStop = parseStopEvent(alight, placesById: placesById, isDeparture: false)
        else { return nil }

        var intermediateStops: [Stop] = []
        for intermediate in timedLeg["LegIntermediate"].all {
            if let stop = parseIntermediateStop(intermediate, placesById: placesById) {
                intermediateStops.append(stop)
            }
        }

        let service = timedLeg["Service"]
        let line = parseLine(from: service)
        let destination = parseServiceDestination(from: service)
        let journeyContext = makeJourneyContext(from: service)
        let path = parseLegProjection(timedLeg)
        let loadFactor = parseLoadFactor(board, tripOptions: tripOptions)

        return PublicLeg(line: line, destination: destination, departure: departureStop, arrival: arrivalStop, intermediateStops: intermediateStops, message: nil, path: path, journeyContext: journeyContext, wagonSequenceContext: nil, loadFactor: loadFactor)
    }

    /// Parses the expected occupancy of a `LegBoard`/`LegAlight` into a ``LoadFactor``.
    ///
    /// OJP/SIRI reports occupancy per fare class in `<siri:ExpectedDepartureOccupancy>` elements.
    func parseLoadFactor(_ node: XMLIndexer, tripOptions: TripOptions) -> LoadFactor? {
        let occupancies = node["siri:ExpectedDepartureOccupancy"].all
        guard !occupancies.isEmpty else { return nil }

        let classText = tripOptions.tariffProfile?.tariffClass == 1 ? "firstClass" : "secondClass"
        let secondClass = occupancies.first { $0["siri:FareClass"].element?.text == classText }
        let chosen = secondClass ?? occupancies.first
        return mapOccupancyLevel(chosen?["siri:OccupancyLevel"].element?.text)
    }

    /// Maps a SIRI `OccupancyLevelEnumeration` value to a ``LoadFactor``.
    private func mapOccupancyLevel(_ level: String?) -> LoadFactor? {
        switch level {
        case "manySeatsAvailable", "empty":
            return .low
        case "seatsAvailable", "fewSeatsAvailable":
            return .medium
        case "standingRoomOnly", "standingAvailable":
            return .high
        case "crushedStandingRoomOnly", "full", "notAcceptingPassengers":
            return .exceptional
        default:
            return nil
        }
    }

    private func parseTransferLeg(_ transferLeg: XMLIndexer, placesById: [String: Location], previousLeg: Leg?) -> IndividualLeg? {
        guard
            let start = parseLegEndpoint(transferLeg["LegStart"], placesById: placesById),
            let end = parseLegEndpoint(transferLeg["LegEnd"], placesById: placesById)
        else { return nil }

        let duration = parseDuration(transferLeg["Duration"].element?.text)
        // A transfer leg carries no times of its own; anchor it to the previous leg's arrival.
        let departureTime = previousLeg?.arrivalTime ?? Date()
        let arrivalTime = departureTime.addingTimeInterval(duration)
        let path = parseLegProjection(transferLeg)
        return IndividualLeg(type: .walk, departureTime: departureTime, departure: start, arrival: end, arrivalTime: arrivalTime, distance: 0, path: path)
    }

    // MARK: Stop / call parsing

    private func parseStopEvent(_ node: XMLIndexer, placesById: [String: Location], isDeparture: Bool) -> StopEvent? {
        guard let location = parseCallLocation(node, placesById: placesById) else { return nil }
        let timeNode = isDeparture ? node["ServiceDeparture"] : node["ServiceArrival"]
        guard let plannedTime = parseDate(timeNode["TimetabledTime"].element?.text) else { return nil }
        let predictedTime = parseDate(timeNode["EstimatedTime"].element?.text)
        let plannedPlatform = text(node["PlannedQuay"])
        let predictedPlatform = text(node["EstimatedQuay"])
        return StopEvent(location: location, plannedTime: plannedTime, predictedTime: predictedTime, plannedPlatform: plannedPlatform, predictedPlatform: predictedPlatform, cancelled: false)
    }

    private func parseIntermediateStop(_ node: XMLIndexer, placesById: [String: Location]) -> Stop? {
        guard let location = parseCallLocation(node, placesById: placesById) else { return nil }

        let arrivalNode = node["ServiceArrival"]
        let departureNode = node["ServiceDeparture"]
        let plannedPlatform = text(node["PlannedQuay"])
        let predictedPlatform = text(node["EstimatedQuay"])

        var arrival: StopEvent?
        if let plannedTime = parseDate(arrivalNode["TimetabledTime"].element?.text) {
            arrival = StopEvent(location: location, plannedTime: plannedTime, predictedTime: parseDate(arrivalNode["EstimatedTime"].element?.text), plannedPlatform: plannedPlatform, predictedPlatform: predictedPlatform, cancelled: false)
        }
        var departure: StopEvent?
        if let plannedTime = parseDate(departureNode["TimetabledTime"].element?.text) {
            departure = StopEvent(location: location, plannedTime: plannedTime, predictedTime: parseDate(departureNode["EstimatedTime"].element?.text), plannedPlatform: plannedPlatform, predictedPlatform: predictedPlatform, cancelled: false)
        }
        guard arrival != nil || departure != nil else { return nil }
        return Stop(location: location, departure: departure, arrival: arrival, message: nil)
    }

    /// Parses a stop call (`LegBoard`/`LegAlight`/`LegIntermediate`/`*Call`) into a single stop with both events.
    private func parseCallAsStop(_ node: XMLIndexer, placesById: [String: Location]) -> Stop? {
        guard let location = parseCallLocation(node, placesById: placesById) else { return nil }
        let arrivalNode = node["ServiceArrival"]
        let departureNode = node["ServiceDeparture"]
        let plannedPlatform = text(node["PlannedQuay"])
        let predictedPlatform = text(node["EstimatedQuay"])

        var arrival: StopEvent?
        if let plannedTime = parseDate(arrivalNode["TimetabledTime"].element?.text) {
            arrival = StopEvent(location: location, plannedTime: plannedTime, predictedTime: parseDate(arrivalNode["EstimatedTime"].element?.text), plannedPlatform: plannedPlatform, predictedPlatform: predictedPlatform, cancelled: false)
        }
        var departure: StopEvent?
        if let plannedTime = parseDate(departureNode["TimetabledTime"].element?.text) {
            departure = StopEvent(location: location, plannedTime: plannedTime, predictedTime: parseDate(departureNode["EstimatedTime"].element?.text), plannedPlatform: plannedPlatform, predictedPlatform: predictedPlatform, cancelled: false)
        }
        guard arrival != nil || departure != nil else { return nil }
        return Stop(location: location, departure: departure, arrival: arrival, message: nil)
    }

    /// Resolves the ``Location`` of a stop call by its `StopPointRef` and name.
    ///
    /// A stop call (`LegBoard`/`LegAlight`/`LegIntermediate`) only carries the stop point ref and a
    /// display name — never a coordinate. The coordinate (and the cleanly split place/name) live in
    /// the `TripResponseContext/Places` block, which we index by ref beforehand and pass in here.
    private func parseCallLocation(_ node: XMLIndexer, placesById: [String: Location]) -> Location? {
        let id = node["siri:StopPointRef"].element?.text.emptyToNil ?? node["StopPointRef"].element?.text.emptyToNil
        let rawName = text(node["StopPointName"]) ?? text(node["Name"])
        let (place, name) = split(stationName: rawName)

        // Prefer the richer location from the response context (it has the coordinate). Fall back to
        // the inline name when the ref is not listed in the context.
        if let id = id, let contextLocation = placesById[id] {
            return Location(type: .station, id: id, coord: contextLocation.coord, place: contextLocation.place ?? place, name: contextLocation.name ?? name)
        }
        return Location(type: .station, id: id, coord: nil, place: place, name: name)
    }

    /// Resolves a transfer-leg endpoint (`LegStart`/`LegEnd`).
    private func parseLegEndpoint(_ node: XMLIndexer, placesById: [String: Location]) -> Location? {
        let id = node["siri:StopPointRef"].element?.text.emptyToNil ?? node["StopPointRef"].element?.text.emptyToNil
        let rawName = text(node["Name"]) ?? text(node["StopPointName"])
        let (place, name) = split(stationName: rawName)
        let coord = placesById[id ?? ""]?.coord
        return Location(type: .station, id: id, coord: coord, place: place, name: name)
    }

    // MARK: Line / service parsing

    func parseLine(from service: XMLIndexer) -> Line {
        let ptMode = service["Mode"]["PtMode"].element?.text
        let subMode = service["Mode"]["siri:RailSubmode"].element?.text ?? service["Mode"]["siri:BusSubmode"].element?.text
        let categoryRef = service["ProductCategory"]["ProductCategoryRef"].element?.text
        let categoryName = text(service["ProductCategory"]["Name"])
        let categoryShortName = text(service["ProductCategory"]["ShortName"])
        let product = parseProduct(ptMode: ptMode, subMode: subMode, categoryRef: categoryRef, categoryName: categoryName, categoryShortName: categoryShortName)

        let label = text(service["PublishedServiceName"]) ?? service["PublicCode"].element?.text
        let lineRef = service["siri:LineRef"].element?.text
        let number = label
        let direction = parseDirection(service["siri:DirectionRef"].element?.text)
        let style = lineStyle(network: AbstractOjpProvider.SERVER_PRODUCT, product: product, label: label)

        return newLine(id: lineRef, network: AbstractOjpProvider.SERVER_PRODUCT, product: product, name: label, shortName: label, number: number, vehicleNumber: service["TrainNumber"].element?.text, direction: direction, style: style)
    }

    func parseServiceDestination(from service: XMLIndexer) -> Location? {
        guard let name = text(service["DestinationText"]) else { return nil }
        let id = service["DestinationStopPointRef"].element?.text.emptyToNil
        let (place, locationName) = split(stationName: name)
        return Location(type: id != nil ? .station : .any, id: id, coord: nil, place: place, name: locationName)
    }

    func makeJourneyContext(from service: XMLIndexer) -> OjpJourneyContext? {
        guard
            let journeyRef = service["JourneyRef"].element?.text.emptyToNil,
            let operatingDayRef = service["OperatingDayRef"].element?.text.emptyToNil
        else { return nil }
        return OjpJourneyContext(journeyRef: journeyRef, operatingDayRef: operatingDayRef)
    }

    // MARK: Geometry

    /// Parses the coordinate sequence of a leg from its `LegTrack`/`TrackSection`/`LinkProjection`.
    func parseLegProjection(_ legNode: XMLIndexer) -> [LocationPoint] {
        var path: [LocationPoint] = []
        for section in legNode["LegTrack"]["TrackSection"].all {
            for position in section["LinkProjection"]["Position"].all {
                if let coord = parseCoord(position) {
                    path.append(coord)
                }
            }
        }
        // Some responses expose the projection directly under the leg.
        if path.isEmpty {
            for position in legNode["LegProjection"]["Position"].all {
                if let coord = parseCoord(position) {
                    path.append(coord)
                }
            }
        }
        return path
    }
    
    /// Parses the coordinate sequence of a leg from its `JourneyTrack`.
    func parseJourneyProjection(_ journeyNode: XMLIndexer) -> [LocationPoint] {
        var path: [LocationPoint] = []
        for section in journeyNode["JourneyTrack"]["TrackSection"].all {
            for position in section["LinkProjection"]["Position"].all {
                if let coord = parseCoord(position) {
                    path.append(coord)
                }
            }
        }
        return path
    }

    /// Extracts the raw `<TripResult>…</TripResult>` block whose `<Id>` matches the given trip id.
    ///
    /// The OJP refine request requires the original `<TripResult>` element to be echoed back verbatim.
    /// Rather than re-serializing the parsed tree, we slice the matching block out of the raw response.
    private func extractTripResultXml(id: String, from response: String) -> String? {
        let openTag = "<TripResult>"
        let closeTag = "</TripResult>"
        var searchRange = response.startIndex..<response.endIndex
        while let open = response.range(of: openTag, range: searchRange),
              let close = response.range(of: closeTag, range: open.upperBound..<response.endIndex) {
            let block = String(response[open.lowerBound..<close.upperBound])
            if block.contains("<Id>\(id)</Id>") {
                return block
            }
            searchRange = close.upperBound..<response.endIndex
        }
        return nil
    }

    /// Indexes the places of a `TripResponseContext`/`TripInfoResponseContext` by every ref under
    /// which a stop call may reference them (both the `StopPlace` and the `StopPoint` ref). The
    /// parsed ``Location`` already carries the coordinate from the place's `<GeoPosition>`.
    private func indexPlaces(_ placesNode: XMLIndexer) -> [String: Location] {
        var result: [String: Location] = [:]
        for placeNode in placesNode["Place"].all {
            guard let location = parsePlace(placeNode) else { continue }
            let ids = [
                placeNode["StopPlace"]["StopPlaceRef"].element?.text,
                placeNode["StopPoint"]["siri:StopPointRef"].element?.text
            ].compactMap { $0?.emptyToNil }
            for id in ids {
                result[id] = location
            }
        }
        return result
    }

}


// MARK: - Context objects

extension AbstractOjpProvider {

    /// Context for querying earlier/later trips. OJP is stateless, so we re-issue a trip request
    /// anchored at the first/last trip time of the previous result.
    public class Context: QueryTripsContext {

        public override class var supportsSecureCoding: Bool { return true }
        
        public override var canQueryEarlier: Bool { true }
        public override var canQueryLater: Bool { true }

        let from: Location
        let via: Location?
        let to: Location
        let tripOptions: TripOptions
        let firstArrivalTime: Date
        let lastDepartureTime: Date

        init(from: Location, via: Location?, to: Location, tripOptions: TripOptions, firstArrivalTime: Date, lastDepartureTime: Date) {
            self.from = from
            self.via = via
            self.to = to
            self.tripOptions = tripOptions
            self.firstArrivalTime = firstArrivalTime
            self.lastDepartureTime = lastDepartureTime
            super.init()
        }

        public required init?(coder aDecoder: NSCoder) {
            guard
                let from = aDecoder.decodeObject(of: Location.self, forKey: PropertyKey.from),
                let to = aDecoder.decodeObject(of: Location.self, forKey: PropertyKey.to),
                let tripOptions = aDecoder.decodeObject(of: TripOptions.self, forKey: PropertyKey.tripOptions),
                let firstArrivalTime = aDecoder.decodeObject(of: NSDate.self, forKey: PropertyKey.firstArrivalTime) as Date?,
                let lastDepartureTime = aDecoder.decodeObject(of: NSDate.self, forKey: PropertyKey.lastDepartureTime) as Date?
            else {
                return nil
            }
            self.from = from
            self.via = aDecoder.decodeObject(of: Location.self, forKey: PropertyKey.via)
            self.to = to
            self.tripOptions = tripOptions
            self.firstArrivalTime = firstArrivalTime
            self.lastDepartureTime = lastDepartureTime
            super.init(coder: aDecoder)
        }

        public override func encode(with aCoder: NSCoder) {
            super.encode(with: aCoder)
            aCoder.encode(from, forKey: PropertyKey.from)
            if let via = via {
                aCoder.encode(via, forKey: PropertyKey.via)
            }
            aCoder.encode(to, forKey: PropertyKey.to)
            aCoder.encode(tripOptions, forKey: PropertyKey.tripOptions)
            aCoder.encode(firstArrivalTime, forKey: PropertyKey.firstArrivalTime)
            aCoder.encode(lastDepartureTime, forKey: PropertyKey.lastDepartureTime)
        }

        struct PropertyKey {
            static let from = "from"
            static let via = "via"
            static let to = "to"
            static let tripOptions = "tripOptions"
            static let firstArrivalTime = "firstArrivalTime"
            static let lastDepartureTime = "lastDepartureTime"
        }
    }

}

/// Context for refreshing a single trip via an `OJPTripRefineRequest`.
///
/// The OJP refine request echoes back the original `<TripResult>` element, so we keep its raw XML.
public class OjpRefreshTripContext: RefreshTripContext {

    public override class var supportsSecureCoding: Bool { return true }
    
    let tripResultXml: String
    let tripOptions: TripOptions

    init(tripResultXml: String, tripOptions: TripOptions) {
        self.tripResultXml = tripResultXml
        self.tripOptions = tripOptions
        super.init()
    }

    public required init?(coder aDecoder: NSCoder) {
        guard let tripResultXml = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.tripResultXml) as String? else {
            return nil
        }
        guard let tripOptions = aDecoder.decodeObject(of: TripOptions.self, forKey: PropertyKey.tripOptions) else {
            return nil
        }
        self.tripResultXml = tripResultXml
        self.tripOptions = tripOptions
        super.init(coder: aDecoder)
    }

    public override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(tripResultXml, forKey: PropertyKey.tripResultXml)
        aCoder.encode(tripOptions, forKey: PropertyKey.tripOptions)
    }

    struct PropertyKey {
        static let tripResultXml = "tripResultXml"
        static let tripOptions = "tripOptions"
    }
}

/// Context for querying the details of a single journey via an `OJPTripInfoRequest`.
public class OjpJourneyContext: QueryJourneyDetailContext {

    public override class var supportsSecureCoding: Bool { return true }
    
    let journeyRef: String
    let operatingDayRef: String

    init(journeyRef: String, operatingDayRef: String) {
        self.journeyRef = journeyRef
        self.operatingDayRef = operatingDayRef
        super.init()
    }

    public required init?(coder aDecoder: NSCoder) {
        guard
            let journeyRef = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.journeyRef) as String?,
            let operatingDayRef = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.operatingDayRef) as String?
        else {
            return nil
        }
        self.journeyRef = journeyRef
        self.operatingDayRef = operatingDayRef
        super.init(coder: aDecoder)
    }

    public override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(journeyRef, forKey: PropertyKey.journeyRef)
        aCoder.encode(operatingDayRef, forKey: PropertyKey.operatingDayRef)
    }

    struct PropertyKey {
        static let journeyRef = "journeyRef"
        static let operatingDayRef = "operatingDayRef"
    }
}
