import Foundation

/// Verkehrsverbund Großraum Nürnberg (DE)
public class VgnProvider: AbstractEfaProvider {
    
    static let API_BASE = "https://vgn.defas-fgi.de/vgnExt/"
    static let DEPARTURE_MONITOR_ENDPOINT = "XML_DM_REQUEST"
    static let TRIP_ENDPOINT = "XML_TRIP_REQUEST2"
    
    public override var supportedLanguages: Set<String> { ["de"] }
    
    public init() {
        super.init(networkId: .VGN, apiBase: VgnProvider.API_BASE, departureMonitorEndpoint: VgnProvider.DEPARTURE_MONITOR_ENDPOINT, tripEndpoint: VgnProvider.TRIP_ENDPOINT, stopFinderEndpoint: nil, coordEndpoint: nil, tripStopTimesEndpoint: nil)
        styles = [
            "SS1": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(119, 53, 53), foregroundColor: LineStyle.white),
            "SS2": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(104, 171, 84), foregroundColor: LineStyle.white),
            "SS3": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(207, 93, 56), foregroundColor: LineStyle.white),
            "SS4": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(41, 50, 120), foregroundColor: LineStyle.white),
            
            "RR1": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(199, 55, 52), foregroundColor: LineStyle.white),
            "RR11": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(210, 104, 81), foregroundColor: LineStyle.white),
            "RR12": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(222, 148, 121), foregroundColor: LineStyle.white),
            "RR15": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(237, 198, 176), foregroundColor: LineStyle.white),
            "RR2": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(2, 115, 66), foregroundColor: LineStyle.white),
            "RR21": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(3, 150, 81), foregroundColor: LineStyle.white),
            "RR22": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(85, 169, 115), foregroundColor: LineStyle.white),
            "RR24": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(139, 192, 150), foregroundColor: LineStyle.white),
            "RR25": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(197, 221, 195), foregroundColor: LineStyle.white),
            "RR26": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(219, 229, 216), foregroundColor: LineStyle.white),
            "RR3": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(168, 78, 48), foregroundColor: LineStyle.white),
            "RR31": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(185, 112, 78), foregroundColor: LineStyle.white),
            "RR32": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(197, 134, 101), foregroundColor: LineStyle.white),
            "RR33": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(210, 161, 129), foregroundColor: LineStyle.white),
            "RR34": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(224, 189, 162), foregroundColor: LineStyle.white),
            "RR35": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(240, 217, 199), foregroundColor: LineStyle.white),
            "RR4": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(199, 54, 86), foregroundColor: LineStyle.white),
            "RR41": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(210, 104, 116), foregroundColor: LineStyle.white),
            "RR43": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(221, 148, 149), foregroundColor: LineStyle.white),
            "RR5": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(93, 88, 146), foregroundColor: LineStyle.white),
            "RR6": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(113, 47, 103), foregroundColor: LineStyle.white),
            "RR61": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(142, 50, 122), foregroundColor: LineStyle.white),
            "RR62": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(155, 91, 144), foregroundColor: LineStyle.white),
            "RR63": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(168, 118, 160), foregroundColor: LineStyle.white),
            "RR64": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(184, 153, 184), foregroundColor: LineStyle.white),
            "RR7": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(16, 157, 177), foregroundColor: LineStyle.white),
            "RR71": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(137, 197, 205), foregroundColor: LineStyle.white),
            "RR8": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(47, 103, 160), foregroundColor: LineStyle.white),
            "RR81": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(102, 135, 180), foregroundColor: LineStyle.white),
            "RR82": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(139, 161, 197), foregroundColor: LineStyle.white),
            "RR9": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(97, 185, 221), foregroundColor: LineStyle.white),
            
            "UU1": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(24, 90, 154), foregroundColor: LineStyle.white),
            "UU2": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(207, 44, 35), foregroundColor: LineStyle.white),
            "UU3": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(93, 181, 184), foregroundColor: LineStyle.white),
            
            "TT4": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(225, 137, 147), foregroundColor: LineStyle.white),
            "TT5": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(140, 77, 147), foregroundColor: LineStyle.white),
            "TT6": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(247, 215, 72), foregroundColor: LineStyle.black),
            "TT7": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(168, 173, 214), foregroundColor: LineStyle.black),
            "TT8": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(78, 173, 230), foregroundColor: LineStyle.white),
            
            "U": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(24, 90, 154), foregroundColor: LineStyle.white),
            "T": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(119, 52, 120), foregroundColor: LineStyle.white),
            "B": LineStyle(shape: .circle, backgroundColor: LineStyle.rgb(210, 68, 57), foregroundColor: LineStyle.white)
        ]
    }
    
    override func parseLine(id: String?, network: String?, mot: String?, symbol: String?, name: String?, longName: String?, trainType: String?, trainNum: String?, trainName: String?) -> Line {
        if mot == "0" {
            if trainNum == "R5(z)" || trainNum == "R7(z)" || trainNum == "R8(z)" {
                return Line(id: id, network: network, product: .regionalTrain, label: trainNum)
            }
        }
        return super.parseLine(id: id, network: network, mot: mot, symbol: symbol, name: name, longName: longName, trainType: trainType, trainNum: trainNum, trainName: trainName)
    }
    
    override func stopFinderRequestParameters(builder: UrlBuilder, constraint: String, types: [LocationType]?, maxLocations: Int, outputFormat: String) {
        super.stopFinderRequestParameters(builder: builder, constraint: constraint, types: types, maxLocations: maxLocations, outputFormat: outputFormat)
        builder.addParameter(key: "itdLPxx_showTariffLevel", value: 1)
    }
    
}
