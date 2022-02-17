import Foundation

/// Freiburger Verkehrs AG (DE)
public class VagfrProvider: AbstractEfaProvider {
    
    static let API_BASE = "https://efa.vagfr.de/vagfr3/"
    
    public override var supportedLanguages: Set<String> { ["de"] }
    
    public init() {
        super.init(networkId: .VAGFR, apiBase: VagfrProvider.API_BASE)
        useRouteIndexAsTripId = false
        
        styles = [
            // Tram
            "T1": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ed1c24"), foregroundColor: LineStyle.white),
            "T2": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#33b540"), foregroundColor: LineStyle.white),
            "T3": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#f79210"), foregroundColor: LineStyle.white),
            "T4": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ef58a1"), foregroundColor: LineStyle.white),
            "T5": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#0994ce"), foregroundColor: LineStyle.white),
            
            // Nachtbus
            "N46": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#28bda5"), foregroundColor: LineStyle.white),
            "N47": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#d6de20"), foregroundColor: LineStyle.white)
        ]
    }
    
    override func parseLine(id: String?, network: String?, mot: String?, symbol: String?, name: String?, longName: String?, trainType: String?, trainNum: String?, trainName: String?) -> Line {
        if mot == "0" {
            if let trainNum = trainNum, trainType == "N" || trainName == "Nahverkehrszug" {
                return Line(id: id, network: network, product: .regionalTrain, label: "N\(trainNum)")
            } else if let longName = longName, longName.hasPrefix("BSB-Zug "), let trainNum = trainNum {
                return Line(id: id, network: network, product: .suburbanTrain, label: "BSB" + trainNum)
            }
        }
        return super.parseLine(id: id, network: network, mot: mot, symbol: symbol, name: name, longName: longName, trainType: trainType, trainNum: trainNum, trainName: trainName)
    }
}
