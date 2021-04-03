import Foundation

import Foundation

public class BayernProvider: AbstractEfaProvider {
    
    static let API_BASE = "https://mobile.defas-fgi.de/beg/"
    static let DEPARTURE_MONITOR_ENDPOINT = "XML_DM_REQUEST"
    static let TRIP_ENDPOINT = "XML_TRIP_REQUEST2"
    static let STOP_FINDER_ENDPOINT = "XML_STOPFINDER_REQUEST"
    static let DESKTOP_TRIP_ENDPOINT = "https://www.bayern-fahrplan.de/de/auskunft"
    static let DESKTOP_DEPARTURES_ENDPOINT = "https://www.bayern-fahrplan.de/de/abfahrt-ankunft"
    
    public init() {
        super.init(networkId: .BAYERN, apiBase: BayernProvider.API_BASE, departureMonitorEndpoint: BayernProvider.DEPARTURE_MONITOR_ENDPOINT, tripEndpoint: BayernProvider.TRIP_ENDPOINT, stopFinderEndpoint: BayernProvider.STOP_FINDER_ENDPOINT, coordEndpoint: nil, tripStopTimesEndpoint: nil, desktopTripEndpoint: BayernProvider.DESKTOP_TRIP_ENDPOINT, desktopDeparturesEndpoint: BayernProvider.DESKTOP_DEPARTURES_ENDPOINT)
        
        numTripsRequested = 12
        includeRegionId = false
    }

    override public func queryNearbyLocations(location: Location, types: [LocationType]?, maxDistance: Int, maxLocations: Int, completion: @escaping (HttpRequest, NearbyLocationsResult) -> Void) -> AsyncRequest {
        if let coord = location.coord {
            return mobileCoordRequest(types: types, lat: coord.lat, lon: coord.lon, maxDistance: maxDistance, maxLocations: maxLocations, completion: completion)
        } else {
            completion(HttpRequest(urlBuilder: UrlBuilder()), .invalidId)
            return AsyncRequest(task: nil)
        }
    }
    
    override public func queryDepartures(stationId: String, departures: Bool, time: Date?, maxDepartures: Int, equivs: Bool, completion: @escaping (HttpRequest, QueryDeparturesResult) -> Void) -> AsyncRequest {
        return queryDeparturesMobile(stationId: stationId, departures: departures, time: time, maxDepartures: maxDepartures, equivs: equivs, completion: completion)
    }
    
    override public func queryJourneyDetail(context: QueryJourneyDetailContext, completion: @escaping (HttpRequest, QueryJourneyDetailResult) -> Void) -> AsyncRequest {
        return queryJourneyDetailMobile(context: context, completion: completion)
    }
    
    override public func suggestLocations(constraint: String, types: [LocationType]?, maxLocations: Int, completion: @escaping (HttpRequest, SuggestLocationsResult) -> Void) -> AsyncRequest {
        return mobileStopfinderRequest(constraint: constraint, types: types, maxLocations: maxLocations, completion: completion)
    }
    
    public override func queryTrips(from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        return queryTripsMobile(from: from, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions, completion: completion)
    }
    
    override func queryTripsParameters(builder: UrlBuilder, from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions, desktop: Bool) {
        super.queryTripsParameters(builder: builder, from: from, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions, desktop: desktop)
        
        if let products = tripOptions.products {
            for product in products {
                if product == .highSpeedTrain {
                    builder.addParameter(key: "inclMOT_15", value: "on")
                    builder.addParameter(key: "inclMOT_16", value: "on")
                } else if product == .regionalTrain {
                    builder.addParameter(key: "inclMOT_13", value: "on")
                }
            }
        }
        
        builder.addParameter(key: "inclMOT_11", value: "on")
        builder.addParameter(key: "inclMOT_14", value: "on")
        
        builder.addParameter(key: "calcOneDirection", value: 1)
        
        if desktop {
            builder.addParameter(key: "zope_command", value: "verify")
        }
    }
    
    override public func queryMoreTrips(context: QueryTripsContext, later: Bool, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        return queryMoreTripsMobile(context: context, later: later, completion: completion)
    }
    
    public override func refreshTrip(context: RefreshTripContext, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) -> AsyncRequest {
        return refreshTripMobile(context: context, completion: completion)
    }
    
    override func parseLine(id: String?, network: String?, mot: String?, symbol: String?, name: String?, longName: String?, trainType: String?, trainNum: String?, trainName: String?) -> Line {
        if mot == "0" {
            if let trainNum = trainNum, let trainName = trainName, trainType == "M", trainName.hasSuffix("Meridian") {
                return Line(id: id, network: network, product: .regionalTrain, label: "M" + trainNum)
            } else if let trainNum = trainNum, trainType == "ZUG" {
                return Line(id: id, network: network, product: .regionalTrain, label: trainNum)
            }
        } else if mot == "1" {
            if let trainNum = trainNum, trainType == "ABR" || trainName == "ABELLIO Rail NRW GmbH" {
                return Line(id: id, network: network, product: .suburbanTrain, label: "ABR" + trainNum)
            } else if let trainNum = trainNum, trainType == "SBB" || trainName == "SBB GmbH" {
                return Line(id: id, network: network, product: .suburbanTrain, label: "SBB" + trainNum)
            }
        } else if mot == "5" {
            if let name = name, name.hasPrefix("Stadtbus Linie ") { // Lindau
                return super.parseLine(id: id, network: network, mot: mot, symbol: symbol, name: name.substring(to: 15), longName: longName, trainType: trainType, trainNum: trainNum, trainName: trainName)
            } else {
                return super.parseLine(id: id, network: network, mot: mot, symbol: symbol, name: name, longName: longName, trainType: trainType, trainNum: trainNum, trainName: trainName)
            }
        } else if mot == "16" {
            if let trainNum = trainNum {
                if trainType == "EC" {
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "EC" + trainNum)
                } else if trainType == "IC" {
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "IC" + trainNum)
                } else if trainType == "ICE" {
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "ICE" + trainNum)
                } else if trainType == "CNL" {
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "CNL" + trainNum)
                } else if trainType == "THA" { // Thalys
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "THA" + trainNum)
                } else if trainType == "TGV" { // Train a grande Vitesse
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "TGV" + trainNum)
                } else if trainType == "RJ" { // railjet
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "RJ" + trainNum)
                } else if trainType == "WB" { // WESTbahn
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "WB" + trainNum)
                } else if trainType == "HKX" { // Hamburg-Köln-Express
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "HKX" + trainNum)
                } else if trainType == "D" { // Schnellzug
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "D" + trainNum)
                } else if trainType == "IR" { // InterRegio
                    return Line(id: id, network: network, product: .highSpeedTrain, label: "IR" + trainNum)
                }
            }
        }
        return super.parseLine(id: id, network: network, mot: mot, symbol: symbol, name: name, longName: longName, trainType: trainType, trainNum: trainNum, trainName: trainName)
    }
    
    
}
