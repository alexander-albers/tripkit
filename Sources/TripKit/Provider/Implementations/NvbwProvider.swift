import Foundation

/// Nahverkehrsgesellschaft Baden-Württemberg (DE)
public class NvbwProvider: AbstractEfaWebProvider {
    
    static let API_BASE = "https://www.efa-bw.de/nvbw/"
    
    public override var supportedLanguages: Set<String> { ["de", "en"] }
    
    public init() {
        super.init(networkId: .NVBW, apiBase: NvbwProvider.API_BASE)
        
        includeRegionId = false
    }
    
    let P_LINE_S_AVG_VBK = try! NSRegularExpression(pattern: "(S\\d+) \\((?:AVG|VBK)\\)")
    
    override func parseLine(id: String?, network: String?, mot: String?, symbol: String?, name: String?, longName: String?, trainType: String?, trainNum: String?, trainName: String?) -> Line {
        if mot == "0" {
            if (trainName == "ICE" || trainName == "InterCityExpress") && trainNum == nil {
                return Line(id: id, network: network, product: .highSpeedTrain, label: "ICE")
            } else if trainName == "InterCity" && trainNum == nil {
                return Line(id: id, network: network, product: .highSpeedTrain, label: "IC")
            } else if trainName == "Fernreisezug externer EU" && trainNum == nil {
                return Line(id: id, network: network, product: .highSpeedTrain, label: nil)
            } else if trainName == "SuperCity" && trainNum == nil {
                return Line(id: id, network: network, product: .highSpeedTrain, label: "SC")
            } else if longName == "InterRegio" && symbol == nil {
                return Line(id: id, network: network, product: .regionalTrain, label: "IR")
            } else if trainName == "REGIOBAHN" && trainNum == nil {
                return Line(id: id, network: network, product: .regionalTrain, label: nil)
            } else if trainName == "Meridian" && symbol != nil {
                return Line(id: id, network: network, product: .regionalTrain, label: symbol)
            } else if trainName == "CityBahn" && trainNum == nil {
                return Line(id: id, network: network, product: .regionalTrain, label: "CB")
            } else if trainName == "Trilex" && trainNum == nil {
                return Line(id: id, network: network, product: .regionalTrain, label: "TLX")
            } else if trainName == "Bay. Seenschifffahrt" && symbol != nil {
                return Line(id: id, network: network, product: .regionalTrain, label: symbol)
            } else if trainName == "Nahverkehrszug von Dritten" && trainNum == nil {
                return Line(id: id, network: network, product: nil, label: "Zug")
            } else if trainName == "DB" && trainNum == nil {
                return Line(id: id, network: network, product: nil, label: "DB")
            }
        } else if mot == "1" {
            if let symbol = symbol, name == symbol, let match = symbol.match(pattern: P_LINE_S_AVG_VBK) {
                return Line(id: id, network: network, product: .suburbanTrain, label: match[0])
            }
        }
        
        return super.parseLine(id: id, network: network, mot: mot, symbol: symbol, name: name, longName: longName, trainType: trainType, trainNum: trainNum, trainName: trainName)
    }

}
