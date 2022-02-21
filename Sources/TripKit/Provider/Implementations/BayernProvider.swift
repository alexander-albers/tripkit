import Foundation

/// Bavaria (DE)
public class BayernProvider: AbstractEfaMobileProvider {
    
    static let API_BASE = "https://mobile.defas-fgi.de/beg/"
    static let DEPARTURE_MONITOR_ENDPOINT = "XML_DM_REQUEST"
    static let TRIP_ENDPOINT = "XML_TRIP_REQUEST2"
    static let STOP_FINDER_ENDPOINT = "XML_STOPFINDER_REQUEST"
    
    public override var supportedLanguages: Set<String> { ["de", "en"] }
    
    public init() {
        super.init(networkId: .BAYERN, apiBase: BayernProvider.API_BASE, departureMonitorEndpoint: BayernProvider.DEPARTURE_MONITOR_ENDPOINT, tripEndpoint: BayernProvider.TRIP_ENDPOINT, stopFinderEndpoint: BayernProvider.STOP_FINDER_ENDPOINT, coordEndpoint: nil, tripStopTimesEndpoint: nil)
        
        includeRegionId = false
        useProxFootSearch = false
    }
    
    override func queryTripsParameters(builder: UrlBuilder, from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions) {
        super.queryTripsParameters(builder: builder, from: from, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions)
        
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
                return super.parseLine(id: id, network: network, mot: mot, symbol: symbol, name: name.substring(from: "Stadtbus Linie ".count), longName: longName, trainType: trainType, trainNum: trainNum, trainName: trainName)
            } else if let name = name, name.hasPrefix("Linie ") { // Passau
                return super.parseLine(id: id, network: network, mot: mot, symbol: symbol, name: name.substring(from: "Linie ".count), longName: longName, trainType: trainType, trainNum: trainNum, trainName: trainName)
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
