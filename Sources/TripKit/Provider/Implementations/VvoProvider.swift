import Foundation

/// Verkehrsverbund Oberelbe (DE)
public class VvoProvider: AbstractEfaWebProvider {
    
    static let API_BASE = "https://efa.vvo-online.de/std3/"
    static let STOPFINDER_ENDPOINT = "XSLT_STOPFINDER_REQUEST"
    static let COORD_ENDPOINT = "XSLT_COORD_REQUEST"
    
    public override var supportedLanguages: Set<String> { ["de"] }
    
    public init() {
        super.init(networkId: .VVO, apiBase: VvoProvider.API_BASE, stopFinderEndpoint: VvoProvider.STOPFINDER_ENDPOINT, coordEndpoint: VvoProvider.COORD_ENDPOINT)
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
            } else if symbol == "U28" || symbol == "U 28" { // Nationalparkbahn
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
    
    override func _queryTripsParsing(request: HttpRequest, from: Location?, via: Location?, to: Location?, date: Date, departure: Bool, tripOptions: TripOptions, previousContext: QueryTripsContext?, later: Bool, completion: @escaping (HttpRequest, QueryTripsResult) -> Void) throws {
        // Workaround for invalid xml encoding
        // Specifically, the following line in the xml response is invalid
        // <value>Teilnetz voe Tarifzonen�bergangsfehler, von ddb 90D60  voe 7500 nach ddb 90D60  voe 7950 (Fehler 172)</value>
        
        guard let data = request.responseData else {
            try super._queryTripsParsing(request: request, from: from, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions, previousContext: previousContext, later: later, completion: completion)
            return
        }
        
        let string = String(decoding: data, as: UTF8.self) // lossy conversion, replacing invalid characters with �
        request.responseData = string.data(using: .utf8) ?? data
        try super._queryTripsParsing(request: request, from: from, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions, previousContext: previousContext, later: later, completion: completion)
    }
    
}
