import Foundation

public class VvoProvider: AbstractEfaProvider {
    
    static let API_BASE = "http://efa.vvo-online.de:8080/dvb/"
    static let STOPFINDER_ENDPOINT = "XSLT_STOPFINDER_REQUEST"
    static let COORD_ENDPOINT = "XSLT_COORD_REQUEST"
    static let TRIPSTOPTIMES_ENDPOINT = "XSLT_TRIPSTOPTIMES_REQUEST"
    static let DESKTOP_TRIP_ENDPOINT = "https://www.vvo-online.de/de/fahrplan/fahrplanauskunft/fahrten"
    static let DESKTOP_DEPARTURES_ENDPOINT = "https://www.vvo-online.de/de/fahrplan/aktuelle-abfahrten-ankuenfte/abfahrten"
    
    public init() {
        super.init(networkId: .VVO, apiBase: VvoProvider.API_BASE, departureMonitorEndpoint: nil, tripEndpoint: nil, stopFinderEndpoint: VvoProvider.STOPFINDER_ENDPOINT, coordEndpoint: VvoProvider.COORD_ENDPOINT, tripStopTimesEndpoint: VvoProvider.TRIPSTOPTIMES_ENDPOINT, desktopTripEndpoint: VvoProvider.DESKTOP_TRIP_ENDPOINT, desktopDeparturesEndpoint: VvoProvider.DESKTOP_DEPARTURES_ENDPOINT)
    }
    
    override func parseLine(id: String?, network: String?, mot: String?, symbol: String?, name: String?, longName: String?, trainType: String?, trainNum: String?, trainName: String?) -> Line {
        if mot == "0" {
            if trainName == "Twoje Linie Kolejowe", let symbol = symbol {
                return Line(id: id, network: network, product: .highSpeedTrain, label: "TLK" + symbol)
            } else if trainName == "Regionalbahn" && trainNum == nil {
                return Line(id: id, network: network, product: .regionalTrain, label: nil)
            } else if longName == "Ostdeutsche Eisenbahn GmbH" {
                return Line(id: id, network: network, product: .regionalTrain, label: "OE")
            } else if longName == "Meridian" {
                return Line(id: id, network: network, product: .regionalTrain, label: "M")
            } else if longName == "trilex" {
                return Line(id: id, network: network, product: .regionalTrain, label: "TLX")
            } else if trainName == "Trilex" && trainNum == nil {
                return Line(id: id, network: network, product: .regionalTrain, label: "TLX")
            } else if symbol == "U 28" { // Nationalparkbahn
                return Line(id: id, network: network, product: .regionalTrain, label: "U28")
            } else if symbol == "SB 71" { // Städtebahn Sachsen
                return Line(id: id, network: network, product: .regionalTrain, label: "SB71")
            } else if symbol == "RB 71" {
                return Line(id: id, network: network, product: .regionalTrain, label: "RB71")
            } else if trainName == "Fernbus" && trainNum == nil {
                return Line(id: id, network: network, product: .regionalTrain, label: "Fernbus")
            }
        }
        return super.parseLine(id: id, network: network, mot: mot, symbol: symbol, name: name, longName: longName, trainType: trainType, trainNum: trainNum, trainName: trainName)
    }
    
    override func queryTripsParameters(builder: UrlBuilder, from: Location, via: Location?, to: Location, date: Date, departure: Bool, products: [Product]?, optimize: Optimize?, walkSpeed: WalkSpeed?, accessibility: Accessibility?, options: [Option]?, desktop: Bool) {
        if desktop {
            builder.addParameter(key: "originid", value: locationValue(location: from))
            if let via = via {
                builder.addParameter(key: "viaid", value: locationValue(location: via))
            }
            builder.addParameter(key: "destinationid", value: locationValue(location: to))
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd.MM.yyyy"
            dateFormatter.timeZone = timeZone
            dateFormatter.locale = Locale(identifier: "de_DE")
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            timeFormatter.timeZone = timeZone
            timeFormatter.locale = Locale(identifier: "de_DE")
            builder.addParameter(key: "date", value: dateFormatter.string(from: date))
            builder.addParameter(key: "time", value: timeFormatter.string(from: date))
            builder.addParameter(key: "arrival", value: !departure)
        } else {
            super.queryTripsParameters(builder: builder, from: from, via: via, to: to, date: date, departure: departure, products: products, optimize: optimize, walkSpeed: walkSpeed, accessibility: accessibility, options: options, desktop: desktop)
        }
    }
    
    override func queryDeparturesParameters(builder: UrlBuilder, stationId: String, time: Date?, maxDepartures: Int, equivs: Bool, desktop: Bool) {
        if desktop {
            builder.addParameter(key: "stopid", value: stationId)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd.MM.yyyy"
            dateFormatter.timeZone = timeZone
            dateFormatter.locale = Locale(identifier: "de_DE")
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            timeFormatter.timeZone = timeZone
            timeFormatter.locale = Locale(identifier: "de_DE")
            builder.addParameter(key: "date", value: dateFormatter.string(from: time ?? Date()))
            builder.addParameter(key: "time", value: timeFormatter.string(from: time ?? Date()))
        } else {
            super.queryDeparturesParameters(builder: builder, stationId: stationId, time: time, maxDepartures: maxDepartures, equivs: equivs, desktop: desktop)
        }
    }
    
}
