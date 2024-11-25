import Foundation

/// Verkehrsgesellschaft Mecklenburg-Vorpommern (DE)
public class VmvProvider: AbstractEfaWebProvider {
    
    static let API_BASE = "https://www.fahrplanauskunft-mv.de/vmv-efa/"
    
    public override var supportedLanguages: Set<String> { ["de", "en"] }
    
    public init() {
        super.init(networkId: .VMV, apiBase: VmvProvider.API_BASE)
        useRouteIndexAsTripId = false
        includeRegionId = false
        styles = [
            "SS1": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(9, 154, 135), foregroundColor: LineStyle.white),
            "SS2": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(135, 50, 122), foregroundColor: LineStyle.white),
            "SS3": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(145, 89, 67), foregroundColor: LineStyle.white),
            
            "RRE1": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(34, 119, 74), foregroundColor: LineStyle.white),
            "RRE2": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(245, 210, 78), foregroundColor: LineStyle.black),
            "RRE3": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(214, 119, 61), foregroundColor: LineStyle.white),
            "RRE4": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(177, 204, 84), foregroundColor: LineStyle.white),
            "RRE5": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(15, 96, 153), foregroundColor: LineStyle.white),
            "RRE9": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(124, 55, 72), foregroundColor: LineStyle.white),
            "RRB11": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(199, 55, 52), foregroundColor: LineStyle.white),
            "RRB12": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(56, 145, 193), foregroundColor: LineStyle.white),
            "RRB13": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(77, 77, 77), foregroundColor: LineStyle.white),
            "RRB14": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(33, 98, 100), foregroundColor: LineStyle.white),
            "RRB15": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(9, 154, 135), foregroundColor: LineStyle.white),
            "RRB16": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(113, 102, 150), foregroundColor: LineStyle.white),
            "RRB17": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(191, 108, 153), foregroundColor: LineStyle.white),
            "RRB18": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(113, 102, 150), foregroundColor: LineStyle.white),
            "RRB23": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(15, 96, 153), foregroundColor: LineStyle.white),
            "RRB24": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(199, 55, 52), foregroundColor: LineStyle.white),
            "RRB25": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(9, 154, 135), foregroundColor: LineStyle.white),
            "RRB26": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(34, 119, 74), foregroundColor: LineStyle.white),
            "RRB31": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(191, 108, 153), foregroundColor: LineStyle.white),
            "RRB32": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(56, 145, 193), foregroundColor: LineStyle.white)
        ]
    }
    
    override func queryTripsParameters(builder: UrlBuilder, from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions) {
        super.queryTripsParameters(builder: builder, from: from, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions)
        builder.addParameter(key: "inclMOT_11", value: "on")
    }
    
    override func parseLine(id: String?, network: String?, mot: String?, symbol: String?, name: String?, longName: String?, trainType: String?, trainNum: String?, trainName: String?) -> Line {
        if mot == "13" {
            return Line(id: id, network: network, product: .regionalTrain, label: (trainType ?? "") + (trainNum ?? ""))
        } else {
            return super.parseLine(id: id, network: network, mot: mot, symbol: symbol, name: name, longName: longName, trainType: trainType, trainNum: trainNum, trainName: trainName)
        }
    }
    
}
