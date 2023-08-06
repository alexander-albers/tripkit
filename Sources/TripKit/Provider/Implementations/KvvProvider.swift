import Foundation

/// Karlsruher Verkehrsverbund (DE)
public class KvvProvider: AbstractEfaWebProvider {
    
    static let API_BASE = "https://projekte.kvv-efa.de/sl3/"
    static let DEPARTURE_MONITOR_ENDPOINT = "XSLT_DM_REQUEST"
    static let TRIP_ENDPOINT = "XSLT_TRIP_REQUEST2"
    static let STOPFINDER_ENDPOINT = "XML_STOPFINDER_REQUEST"
    static let COORD_ENDPOINT = "XML_COORD_REQUEST"
    
    public override var supportedLanguages: Set<String> { ["de", "en", "fr"] }
    
    public init() {
        super.init(networkId: .KVV, apiBase: KvvProvider.API_BASE, departureMonitorEndpoint: KvvProvider.DEPARTURE_MONITOR_ENDPOINT, tripEndpoint: KvvProvider.TRIP_ENDPOINT, stopFinderEndpoint: KvvProvider.STOPFINDER_ENDPOINT, coordEndpoint: KvvProvider.COORD_ENDPOINT)
        
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
    
    override func parseLine(id: String?, network: String?, mot: String?, symbol: String?, name: String?, longName: String?, trainType: String?, trainNum: String?, trainName: String?) -> Line {
        if mot == "0" {
            if trainNum == "IRE1" && trainName == nil {
                return Line(id: id, network: network, product: .regionalTrain, label: trainNum)
            } else if let trainName = trainName, trainName.hasPrefix("TRILEX") {
                return Line(id: id, network: network, product: .regionalTrain, label: trainName)
            }
        }
        
        return super.parseLine(id: id, network: network, mot: mot, symbol: symbol, name: name, longName: longName, trainType: trainType, trainNum: trainNum, trainName: trainName)
    }
    
}
