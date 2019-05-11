import Foundation

public class VblProvider: AbstractEfaProvider {
    
    static let API_BASE = "http://mobil.vbl.ch/vblmobil/"
    
    public init() {
        super.init(networkId: .VBL, apiBase: VblProvider.API_BASE)
        useRouteIndexAsTripId = false
    }
    
    override func parseLine(id: String?, network: String?, mot: String?, symbol: String?, name: String?, longName: String?, trainType: String?, trainNum: String?, trainName: String?) -> Line {
        if mot == "0" {
            if "BSL" == trainType, let trainNum = trainNum {
                return Line(id: id, network: network, product: .regionalTrain, label: "BLS" + trainNum)
            } else if "ASM" == trainType, let trainNum = trainNum { // Aare Seeland mobil
                return Line(id: id, network: network, product: .regionalTrain, label: "ASM" + trainNum)
            } else if "SOB" == trainType, let trainNum = trainNum { // Schweizerische Südostbahn
                return Line(id: id, network: network, product: .regionalTrain, label: "SOB" + trainNum)
            } else if "RhB" == trainType, let trainNum = trainNum { // Rhätische Bahn
                return Line(id: id, network: network, product: .regionalTrain, label: "RhB" + trainNum)
            } else if "AB-" == trainType, let trainNum = trainNum { // Appenzeller Bahnen
                return Line(id: id, network: network, product: .regionalTrain, label: "AB" + trainNum)
            } else if "BDW" == trainType, let trainNum = trainNum { // BDWM Transport
                return Line(id: id, network: network, product: .regionalTrain, label: "BDW" + trainNum)
            } else if "ZB" == trainType, let trainNum = trainNum { // Zentralbahn
                return Line(id: id, network: network, product: .regionalTrain, label: "ZB" + trainNum)
            } else if "TPF" == trainType, let trainNum = trainNum { // Transports publics fribourgeois
                return Line(id: id, network: network, product: .regionalTrain, label: "TPF" + trainNum)
            } else if "MGB" == trainType, let trainNum = trainNum { // Matterhorn Gotthard Bahn
                return Line(id: id, network: network, product: .regionalTrain, label: "MGB" + trainNum)
            } else if "CJ" == trainType, let trainNum = trainNum { // Chemins de fer du Jura
                return Line(id: id, network: network, product: .regionalTrain, label: "CJ" + trainNum)
            } else if "LEB" == trainType, let trainNum = trainNum { // Lausanne-Echallens-Bercher
                return Line(id: id, network: network, product: .regionalTrain, label: "LEB" + trainNum)
            } else if "FAR" == trainType, let trainNum = trainNum { // Ferrovie Autolinee Regionali Ticinesi
                return Line(id: id, network: network, product: .regionalTrain, label: "FAR" + trainNum)
            } else if "WAB" == trainType, let trainNum = trainNum { // Wengernalpbahn
                return Line(id: id, network: network, product: .regionalTrain, label: "WAB" + trainNum)
            } else if "JB" == trainType, let trainNum = trainNum { // Jungfraubahn
                return Line(id: id, network: network, product: .regionalTrain, label: "JB" + trainNum)
            } else if "NSt" == trainType, let trainNum = trainNum { // Nyon-St-Cergue-Morez
                return Line(id: id, network: network, product: .regionalTrain, label: "NSt" + trainNum)
            } else if "RA" == trainType, let trainNum = trainNum { // Regionalps
                return Line(id: id, network: network, product: .regionalTrain, label: "RA" + trainNum)
            } else if "TRN" == trainType, let trainNum = trainNum { // Transport Publics Neuchâtelois
                return Line(id: id, network: network, product: .regionalTrain, label: "TRN" + trainNum)
            } else if "TPC" == trainType, let trainNum = trainNum { // Transports Publics du Chablais
                return Line(id: id, network: network, product: .regionalTrain, label: "TPC" + trainNum)
            } else if "MVR" == trainType, let trainNum = trainNum { // Montreux-Vevey-Riviera
                return Line(id: id, network: network, product: .regionalTrain, label: "MVR" + trainNum)
            } else if "MOB" == trainType, let trainNum = trainNum { // Montreux-Oberland Bernois
                return Line(id: id, network: network, product: .regionalTrain, label: "MOB" + trainNum)
            } else if "TRA" == trainType, let trainNum = trainNum { // Transports Vallée de Joux-Yverdon-Ste-Croix
                return Line(id: id, network: network, product: .regionalTrain, label: "TRA" + trainNum)
            } else if "TMR" == trainType, let trainNum = trainNum { // Transports de Martigny et Régions
                return Line(id: id, network: network, product: .regionalTrain, label: "TMR" + trainNum)
            } else if "GGB" == trainType, let trainNum = trainNum { // Gornergratbahn
                return Line(id: id, network: network, product: .regionalTrain, label: "GGB" + trainNum)
            } else if "BLM" == trainType, let trainNum = trainNum { // Lauterbrunnen-Mürren
                return Line(id: id, network: network, product: .regionalTrain, label: "BLM" + trainNum)
            }
        }
        return super.parseLine(id: id, network: network, mot: mot, symbol: symbol, name: name, longName: longName, trainType: trainType, trainNum: trainNum, trainName: trainName)
    }
    
}
