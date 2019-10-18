import Foundation

public class MockKvvProvider: AbstractEfaProvider {
    
    static let API_BASE = "https://projekte.kvv-efa.de/sl3/"
    static let DEPARTURE_MONITOR_ENDPOINT = "XSLT_DM_REQUEST"
    static let TRIP_ENDPOINT = "XSLT_TRIP_REQUEST2"
    static let STOPFINDER_ENDPOINT = "XML_STOPFINDER_REQUEST"
    static let COORD_ENDPOINT = "XML_COORD_REQUEST"
    static let DESKTOP_TRIP_ENDPOINT = "https://www.kvv.de/fahrt-planen/fahrplanauskunft.html?"
    static let DESKTOP_DEPARTURES_ENDPOINT = "https://www.kvv.de/fahrt-planen/abfahrtsmonitor.html?"
    
    let calendar = Calendar(identifier: .gregorian)
    
    public init() {
        super.init(networkId: .KVV, apiBase: KvvProvider.API_BASE, departureMonitorEndpoint: KvvProvider.DEPARTURE_MONITOR_ENDPOINT, tripEndpoint: KvvProvider.TRIP_ENDPOINT, stopFinderEndpoint: KvvProvider.STOPFINDER_ENDPOINT, coordEndpoint: KvvProvider.COORD_ENDPOINT, tripStopTimesEndpoint: nil, desktopTripEndpoint: KvvProvider.DESKTOP_TRIP_ENDPOINT, desktopDeparturesEndpoint: KvvProvider.DESKTOP_DEPARTURES_ENDPOINT)
        
        styles = [
            // S-Bahn
            "SS1": LineStyle(backgroundColor: LineStyle.parseColor("#00a76c"), foregroundColor: LineStyle.white),
            "SS11": LineStyle(backgroundColor: LineStyle.parseColor("#00a76c"), foregroundColor: LineStyle.white),
            "SS2": LineStyle(backgroundColor: LineStyle.parseColor("#9f68ab"), foregroundColor: LineStyle.white),
            "SS3": LineStyle(backgroundColor: LineStyle.parseColor("#00a99d"), foregroundColor: LineStyle.black),
            "SS31": LineStyle(backgroundColor: LineStyle.parseColor("#00a99d"), foregroundColor: LineStyle.white),
            "SS32": LineStyle(backgroundColor: LineStyle.parseColor("#00a99d"), foregroundColor: LineStyle.white),
            "SS33": LineStyle(backgroundColor: LineStyle.parseColor("#00a99d"), foregroundColor: LineStyle.white),
            "SS4": LineStyle(backgroundColor: LineStyle.parseColor("#9f184c"), foregroundColor: LineStyle.white),
            "SS41": LineStyle(backgroundColor: LineStyle.parseColor("#9f184c"), foregroundColor: LineStyle.white),
            "SS5": LineStyle(backgroundColor: LineStyle.parseColor("#f69795"), foregroundColor: LineStyle.black),
            "SS51": LineStyle(backgroundColor: LineStyle.parseColor("#f69795"), foregroundColor: LineStyle.black),
            "SS52": LineStyle(backgroundColor: LineStyle.parseColor("#f69795"), foregroundColor: LineStyle.black),
            "SS6": LineStyle(backgroundColor: LineStyle.parseColor("#292369"), foregroundColor: LineStyle.white),
            "SS7": LineStyle(backgroundColor: LineStyle.parseColor("#fef200"), foregroundColor: LineStyle.black),
            "SS71": LineStyle(backgroundColor: LineStyle.parseColor("#fef200"), foregroundColor: LineStyle.black),
            "SS8": LineStyle(backgroundColor: LineStyle.parseColor("#6e6928"), foregroundColor: LineStyle.white),
            "SS81": LineStyle(backgroundColor: LineStyle.parseColor("#6e6928"), foregroundColor: LineStyle.white),
            "SS9": LineStyle(backgroundColor: LineStyle.parseColor("#fab499"), foregroundColor: LineStyle.black),
            
            // S-Bahn RheinNeckar
            "ddb|SS3": LineStyle(backgroundColor: LineStyle.parseColor("#ffdd00"), foregroundColor: LineStyle.black),
            "ddb|SS33": LineStyle(backgroundColor: LineStyle.parseColor("#8d5ca6"), foregroundColor: LineStyle.white),
            "ddb|SS4": LineStyle(backgroundColor: LineStyle.parseColor("#00a650"), foregroundColor: LineStyle.white),
            "ddb|SS5": LineStyle(backgroundColor: LineStyle.parseColor("#f89835"), foregroundColor: LineStyle.white),
            
            // Tram
            "T1": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ed1c24"), foregroundColor: LineStyle.white),
            "T1E": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ed1c24"), foregroundColor: LineStyle.white),
            "T2": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#0071bc"), foregroundColor: LineStyle.white),
            "T2E": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#0071bc"), foregroundColor: LineStyle.white),
            "T3": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#947139"), foregroundColor: LineStyle.white),
            "T3E": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#947139"), foregroundColor: LineStyle.white),
            "T4": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ffcb04"), foregroundColor: LineStyle.black),
            "T4E": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ffcb04"), foregroundColor: LineStyle.black),
            "T5": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#00c0f3"), foregroundColor: LineStyle.white),
            "T5E": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#00c0f3"), foregroundColor: LineStyle.white),
            "T6": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#80c342"), foregroundColor: LineStyle.white),
            "T6E": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#80c342"), foregroundColor: LineStyle.white),
            "T7": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#58595b"), foregroundColor: LineStyle.white),
            "T7E": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#58595b"), foregroundColor: LineStyle.white),
            "T8": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#f7931d"), foregroundColor: LineStyle.black),
            "T8E": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#f7931d"), foregroundColor: LineStyle.black),
            
            // Nightliner
            "BNL3": LineStyle(backgroundColor: LineStyle.parseColor("#947139"), foregroundColor: LineStyle.white),
            "BNL4": LineStyle(backgroundColor: LineStyle.parseColor("#ffcb04"), foregroundColor: LineStyle.black),
            "BNL5": LineStyle(backgroundColor: LineStyle.parseColor("#00c0f3"), foregroundColor: LineStyle.white),
            "BNL6": LineStyle(backgroundColor: LineStyle.parseColor("#80c342"), foregroundColor: LineStyle.white),
            
            // Anruf-Linien-Taxi
            "BALT6": LineStyle(shape: .rect, backgroundColor: LineStyle.black, foregroundColor: LineStyle.yellow),
            "BALT11": LineStyle(shape: .rect, backgroundColor: LineStyle.black, foregroundColor: LineStyle.yellow),
            "BALT12": LineStyle(shape: .rect, backgroundColor: LineStyle.black, foregroundColor: LineStyle.yellow),
            "BALT13": LineStyle(shape: .rect, backgroundColor: LineStyle.black, foregroundColor: LineStyle.yellow),
            "BALT14": LineStyle(shape: .rect, backgroundColor: LineStyle.black, foregroundColor: LineStyle.yellow),
            "BALT16": LineStyle(shape: .rect, backgroundColor: LineStyle.black, foregroundColor: LineStyle.yellow)
        ]
    }
    
    let P_LINE = try! NSRegularExpression(pattern: "(.*?)\\s+\\([\\w/]+\\)", options: .caseInsensitive)
    
    override func parseLine(id: String?, network: String?, mot: String?, symbol: String?, name: String?, longName: String?, trainType: String?, trainNum: String?, trainName: String?) -> Line {
        var symbol = symbol
        if let s = symbol, let match = s.match(pattern: P_LINE), let first = match[0] {
            symbol = first
        }
        var name = name
        if let n = name, let match = n.match(pattern: P_LINE), let first = match[0] {
            name = first
        }
        var longName = longName
        if let n = longName, let match = n.match(pattern: P_LINE), let first = match[0] {
            longName = first
        }
        
        return super.parseLine(id: id, network: network, mot: mot, symbol: symbol, name: name, longName: longName, trainType: trainType, trainNum: trainNum, trainName: trainName)
    }
    
    public override func queryTrips(from: Location, via: Location?, to: Location, date: Date, departure: Bool, products: [Product]?, optimize: Optimize?, walkSpeed: WalkSpeed?, accessibility: Accessibility?, options: [Option]?, completion: @escaping (QueryTripsResult) -> Void) -> AsyncRequest {
        let fare = Fare(network: "KVV", type: .adult, currency: "EUR", fare: 2.4, unitsName: "Waben", units: "2")
        let fare2 = Fare(network: "KVV", type: .child, currency: "EUR", fare: 1.4, unitsName: "Waben", units: "2")
        let fares = [fare, fare2]
        let trip1 = Trip(id: "", from: from, to: to, legs: [PublicLeg(line: createLine(.suburbanTrain, "S2"), destination: nil, departureStop: createStop("Kronenplatz (Kaiserstraße)", createTime(9, 40)), arrivalStop: createStop("Europaplatz (Kaiserstraße)", createTime(9, 46)), intermediateStops: createIntermediates(createTime(9, 40)), message: nil, journeyContext: nil)], fares: fares)
        let trip2 = Trip(id: "", from: from, to: to, legs: [PublicLeg(line: createLine(.suburbanTrain, "S5"), destination: nil, departureStop: createStop("Kronenplatz (Kaiserstraße)", createTime(9, 42)), arrivalStop: createStop("Europaplatz (Kaiserstraße)", createTime(9, 48)), intermediateStops: createIntermediates(createTime(9, 42)), message: nil, journeyContext: nil)], fares: fares)
        let trip3 = Trip(id: "", from: from, to: to, legs: [PublicLeg(line: createLine(.suburbanTrain, "S1"), destination: nil, departureStop: createStop("Kronenplatz (Kaiserstraße)", createTime(9, 43)), arrivalStop: createStop("Europaplatz (Kaiserstraße)", createTime(9, 49)), intermediateStops: createIntermediates(createTime(9, 43)), message: nil, journeyContext: nil)], fares: fares)
        let trip4 = Trip(id: "", from: from, to: to, legs: [PublicLeg(line: createLine(.tram, "1"), destination: createStation("Oberreut"), departureStop: createStop("Kronenplatz (Kaiserstraße)", createTime(9, 44)), arrivalStop: createStop("Europaplatz (Kaiserstraße)", createTime(9, 50)), intermediateStops: createIntermediates(createTime(9, 44)), message: nil, journeyContext: nil)], fares: fares)
        let trip5 = Trip(id: "", from: from, to: to, legs: [PublicLeg(line: createLine(.tram, "4"), destination: nil, departureStop: createStop("Kronenplatz (Kaiserstraße)", createTime(9, 46)), arrivalStop: createStop("Europaplatz (Kaiserstraße)", createTime(9, 52)), intermediateStops: createIntermediates(createTime(9, 46)), message: nil, journeyContext: nil)], fares: fares)
        let trip6 = Trip(id: "", from: from, to: to, legs: [PublicLeg(line: createLine(.suburbanTrain, "S2"), destination: nil, departureStop: createStop("Kronenplatz (Kaiserstraße)", createTime(9, 48)), arrivalStop: createStop("Europaplatz (Kaiserstraße)", createTime(9, 54)), intermediateStops: createIntermediates(createTime(9, 48)), message: nil, journeyContext: nil)], fares: fares)
        let trip7 = Trip(id: "", from: from, to: to, legs: [PublicLeg(line: createLine(.suburbanTrain, "S5"), destination: createStation("Rheinbergstraße"), departureStop: createStop("Kronenplatz (Kaiserstraße)", createTime(9, 52)), arrivalStop: createStop("Europaplatz (Kaiserstraße)", createTime(9, 58)), intermediateStops: createIntermediates(createTime(9, 52)), message: nil, journeyContext: nil)], fares: fares)
        let trip8 = Trip(id: "", from: from, to: to, legs: [PublicLeg(line: createLine(.tram, "4"), destination: nil, departureStop: createStop("Kronenplatz (Kaiserstraße)", createTime(9, 54)), arrivalStop: createStop("Europaplatz (Kaiserstraße)", createTime(10, 0)), intermediateStops: createIntermediates(createTime(9, 54)), message: nil, journeyContext: nil)], fares: fares)
        let trip9 = Trip(id: "", from: from, to: to, legs: [PublicLeg(line: createLine(.tram, "1"), destination: nil, departureStop: createStop("Kronenplatz (Kaiserstraße)", createTime(9, 56)), arrivalStop: createStop("Europaplatz (Kaiserstraße)", createTime(10, 2)), intermediateStops: createIntermediates(createTime(9, 56)), message: nil, journeyContext: nil)], fares: fares)
        let trip10 = Trip(id: "", from: from, to: to, legs: [PublicLeg(line: createLine(.suburbanTrain, "S2"), destination: nil, departureStop: createStop("Kronenplatz (Kaiserstraße)", createTime(9, 58)), arrivalStop: createStop("Europaplatz (Kaiserstraße)", createTime(10, 4)), intermediateStops: createIntermediates(createTime(9, 58)), message: nil, journeyContext: nil)], fares: fares)
        let trip11 = Trip(id: "", from: from, to: to, legs: [PublicLeg(line: createLine(.suburbanTrain, "S52"), destination: nil, departureStop: createStop("Kronenplatz (Kaiserstraße)", createTime(10, 2)), arrivalStop: createStop("Europaplatz (Kaiserstraße)", createTime(10, 8)), intermediateStops: createIntermediates(createTime(10, 2)), message: nil, journeyContext: nil)], fares: fares)
        let trip12 = Trip(id: "", from: from, to: to, legs: [PublicLeg(line: createLine(.tram, "1"), destination: nil, departureStop: createStop("Kronenplatz (Kaiserstraße)", createTime(10, 4)), arrivalStop: createStop("Europaplatz (Kaiserstraße)", createTime(10, 10)), intermediateStops: createIntermediates(createTime(10, 4)), message: nil, journeyContext: nil)], fares: fares)
        
        completion(.success(context: nil, from: from, via: nil, to: to, trips: [trip1, trip2, trip3, trip4, trip5, trip6, trip7, trip8, trip9, trip10, trip11, trip12], messages: []))
        return AsyncRequest(task: nil)
    }
    
    public override func queryDepartures(stationId: String, departures: Bool, time: Date?, maxDepartures: Int, equivs: Bool, completion: @escaping (QueryDeparturesResult) -> Void) -> AsyncRequest {
        switch stationId {
        case "7000090", "7000090:$EF":
            let result = [StationDepartures(stopLocation: Location(type: .station, id: "7000090", coord: nil, place: nil, name: "Karlsruhe, Hbf")!, departures: [], lines: [])]
            result[0].departures.append(createDeparture(createTime(9, 41), createLine(.tram, "4"), "Waldstadt"))
            result[0].departures.append(createDeparture(createTime(9, 42), createLine(.suburbanTrain, "S51"), "Europaplatz"))
            result[0].departures.append(createDeparture(createTime(9, 42), createLine(.tram, "2"), "Wolfartsweier"))
            result[0].departures.append(createDeparture(createTime(9, 42), createLine(.bus, "62"), "Heidenstücker-Entenf."))
            result[0].departures.append(createDeparture(createTime(9, 44), createLine(.suburbanTrain, "S1"), "Hochstetten"))
            result[0].departures.append(createDeparture(createTime(9, 44), createLine(.tram, "3"), "Tivoli"))
            result[0].departures.append(createDeparture(createTime(9, 47), createLine(.suburbanTrain, "S1"), "Ettlingen"))
            result[0].departures.append(createDeparture(createTime(9, 47), createLine(.tram, "3"), "Heide"))
            result[0].departures.append(createDeparture(createTime(9, 50), createLine(.suburbanTrain, "S11"), "Hochstetten"))
            result[0].departures.append(createDeparture(createTime(9, 50), createLine(.suburbanTrain, "S4"), "Hbf"))
            result[0].departures.append(createDeparture(createTime(9, 50), createLine(.suburbanTrain, "S7"), "Achern"))
            result[0].departures.append(createDeparture(createTime(9, 54), createLine(.tram, "4"), "Tivoli"))
            result[0].departures.append(createDeparture(createTime(9, 56), createLine(.tram, "2"), "Siemensallee über ZKM"))
            result[0].departures.append(createDeparture(createTime(9, 56), createLine(.tram, "4"), "Waldstadt"))
            result[0].departures.append(createDeparture(createTime(9, 59), createLine(.bus, "62"), "Heidenstücker-Entenf."))
            result[0].departures.append(createDeparture(createTime(10, 1), createLine(.suburbanTrain, "S4"), "Weinsberg"))
            result[0].departures.append(createDeparture(createTime(10, 1), createLine(.tram, "3"), "Tivoli"))
            result[0].departures.append(createDeparture(createTime(10, 2), createLine(.bus, "10"), "Marktplatz"))
            result[0].departures.append(createDeparture(createTime(10, 5), createLine(.bus, "50"), "Oberreut"))
            result[0].departures.append(createDeparture(createTime(10, 8), createLine(.suburbanTrain, "S7"), "Tullastraße"))
            result[0].departures.append(createDeparture(createTime(10, 50), createLine(.suburbanTrain, "S8"), "Rastatt"))
            result[0].departures.append(createDeparture(createTime(10, 50), createLine(.bus, "10"), "Bus"))
            result[0].departures.append(createDeparture(createTime(10, 50), createLine(.bus, "47"), "Bus"))
            result[0].departures.append(createDeparture(createTime(10, 50), createLine(.bus, "50"), "Bus"))
            result[0].departures.append(createDeparture(createTime(10, 50), createLine(.bus, "55"), "Bus"))
            completion(.success(departures: result, desktopUrl: nil))
        case "7000001":
            let result = QueryDeparturesResult.success(departures: [StationDepartures(stopLocation: createStation("Marktplatz"), departures: [createDeparture(createTime(9, 42), createLine(.tram, "1"), "Oberreut")], lines: [])], desktopUrl: nil)
            completion(result)
        case "7000002":
            let result = QueryDeparturesResult.success(departures: [StationDepartures(stopLocation: createStation("Kronenplatz (Kaiserstraße)"), departures: [createDeparture(createTime(9, 43), createLine(.suburbanTrain, "S2"), "Rheinstrandsiedlung")], lines: [])], desktopUrl: nil)
            completion(result)
        case "7000031":
            let result = QueryDeparturesResult.success(departures: [StationDepartures(stopLocation: createStation("Europaplatz"), departures: [createDeparture(createTime(9, 42), createLine(.suburbanTrain, "S5"), "Mühlacker")], lines: [])], desktopUrl: nil)
            completion(result)
        default: completion(.invalidStation) ; break
        }
        
        return AsyncRequest(task: nil)
    }
    
    func createTime(_ hour: Int, _ minute: Int) -> Date {
        var components = calendar.dateComponents([.day, .month, .year], from: Date())
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components)!
    }
    
    func createStation(_ name: String) -> Location {
        if name == "Kronenplatz (Kaiserstraße)" {
            return Location(type: .station, id: "7000002", coord: LocationPoint(lat: 49008952, lon: 8407393), place: "Karlsruhe", name: "Kronenplatz (Kaiserstraße)")!
        } else if name == "Europaplatz (Kaiserstraße)" {
            return Location(type: .station, id: "7000031", coord: LocationPoint(lat: 49010075, lon: 8391898), place: "Karlsruhe", name: "Europaplatz (Kaiserstraße)")!
        } else {
            return Location(anyName: name)
        }
    }
    
    func createStop(_ name: String, _ time: Date) -> Stop {
        return Stop(location: createStation(name), plannedArrivalTime: time, predictedArrivalTime: time, plannedArrivalPlatform: nil, predictedArrivalPlatform: nil, arrivalCancelled: false, plannedDepartureTime: time, predictedDepartureTime: time, plannedDeparturePlatform: nil, predictedDeparturePlatform: nil, departureCancelled: false)
    }
    
    func createIntermediates(_ start: Date) -> [Stop] {
        return [createStop("s1", start.addingTimeInterval(60)), createStop("s2", start.addingTimeInterval(120))]
    }
    
    func createLine(_ product: Product, _ name: String) -> Line {
        return Line(id: nil, network: nil, product: product, label: name, name: name, style: lineStyle(network: nil, product: product, label: name), attr: nil, message: nil)
    }
    
    func createDeparture(_ date: Date, _ line: Line, _ destination: String) -> Departure {
        return Departure(plannedTime: date, predictedTime: date, line: line, position: nil, plannedPosition: nil, destination: createStation(destination), capacity: nil, message: nil, journeyContext: nil)
    }
}

