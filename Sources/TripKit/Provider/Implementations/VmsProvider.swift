import Foundation

/// Verkehrsverbund Mittelsachsen (DE)
public class VmsProvider: AbstractEfaProvider {
    
    static let API_BASE = "https://efa.vms.de/VMSSL3/"
    
    public init() {
        super.init(networkId: .VMS, apiBase: VmsProvider.API_BASE)
        useLineRestriction = false
    }
    
    override func queryTripsParameters(builder: UrlBuilder, from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions) {
        super.queryTripsParameters(builder: builder, from: from, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions)
        builder.addParameter(key: "inclMOT_11", value: "on")
        builder.addParameter(key: "inclMOT_13", value: "on")
        builder.addParameter(key: "inclMOT_14", value: "on")
        builder.addParameter(key: "inclMOT_15", value: "on")
        builder.addParameter(key: "inclMOT_16", value: "on")
        builder.addParameter(key: "inclMOT_17", value: "on")
    }
    
    override func parseLine(id: String?, network: String?, mot: String?, symbol: String?, name: String?, longName: String?, trainType: String?, trainNum: String?, trainName: String?) -> Line {
        if mot == "0" {
            if trainName == "Ilztalbahn" && trainNum == nil {
                return Line(id: id, network: network, product: .regionalTrain, label: "ITB")
            } else if trainName == "Meridian" && trainNum == nil {
                return Line(id: id, network: network, product: .regionalTrain, label: "M")
            } else if trainName == "CityBahn" && trainNum == nil {
                return Line(id: id, network: network, product: .regionalTrain, label: "CB")
            } else if longName == "CityBahn" && symbol == "C11" {
                return Line(id: id, network: network, product: .regionalTrain, label: "CB")
            } else if longName == "Zug" && (symbol == "C11" || symbol == "C13" || symbol == "C14" || symbol == "C15") {
                return Line(id: id, network: network, product: .regionalTrain, label: symbol)
            } else if longName == "Zug" && symbol == "RE 3" {
                return Line(id: id, network: network, product: .regionalTrain, label: "RE3")
            }
        }
        return super.parseLine(id: id, network: network, mot: mot, symbol: symbol, name: name, longName: longName, trainType: trainType, trainNum: trainNum, trainName: trainName)
    }
}
