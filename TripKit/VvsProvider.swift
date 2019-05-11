import Foundation

public class VvsProvider: AbstractEfaProvider {
    
    static let API_BASE = "https://www2.vvs.de/vvs/"
    
    public init() {
        super.init(networkId: .VVS, apiBase: VvsProvider.API_BASE)
        includeRegionId = false
        numTripsRequested = 4
        
        styles = [
            "B": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(180, 46, 45), foregroundColor: LineStyle.white),
            "SS1": LineStyle(shape: .circle, backgroundColor: LineStyle.rgb(109, 165, 79), foregroundColor: LineStyle.white),
            "SS11": LineStyle(shape: .circle, backgroundColor: LineStyle.rgb(109, 165, 79), foregroundColor: LineStyle.white),
            "SS2": LineStyle(shape: .circle, backgroundColor: LineStyle.rgb(199, 55, 55), foregroundColor: LineStyle.white),
            "SS3": LineStyle(shape: .circle, backgroundColor: LineStyle.rgb(216, 127, 63), foregroundColor: LineStyle.white),
            "SS4": LineStyle(shape: .circle, backgroundColor: LineStyle.rgb(23, 90, 151), foregroundColor: LineStyle.white),
            "SS5": LineStyle(shape: .circle, backgroundColor: LineStyle.rgb(19, 159, 195), foregroundColor: LineStyle.white),
            "SS6": LineStyle(shape: .circle, backgroundColor: LineStyle.rgb(109, 72, 34), foregroundColor: LineStyle.white),
            "SS60": LineStyle(shape: .circle, backgroundColor: LineStyle.rgb(124, 130, 50), foregroundColor: LineStyle.white),
            
            // Nachtnetz
            "BN1": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(73, 60, 125), foregroundColor: LineStyle.white),
            "BN2": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(0, 161, 213), foregroundColor: LineStyle.white),
            "BN3": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(132, 199, 227), foregroundColor: LineStyle.rgb(32, 65, 124)),
            "BN4": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(0, 150, 104), foregroundColor: LineStyle.white),
            "BN5": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(234, 179, 74), foregroundColor: LineStyle.rgb(32, 65, 124)),
            "BN6": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(178, 111, 54), foregroundColor: LineStyle.white),
            "BN7": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(200, 55, 55), foregroundColor: LineStyle.white),
            "BN8": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(26, 25, 25), foregroundColor: LineStyle.white),
            "BN9": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(164, 49, 120), foregroundColor: LineStyle.white),
            "BN10": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(220, 140, 149), foregroundColor: LineStyle.rgb(32, 65, 124)),
            
            "UU1": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(203, 164, 119), foregroundColor: LineStyle.black),
            "UU2": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(225, 131, 48), foregroundColor: LineStyle.white),
            "UU3": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(141, 95, 61), foregroundColor: LineStyle.white),
            "UU4": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(125, 101, 164), foregroundColor: LineStyle.white),
            "UU5": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(79, 174, 230), foregroundColor: LineStyle.black),
            "UU6": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(210, 45, 124), foregroundColor: LineStyle.white),
            "UU7": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(75, 167, 134), foregroundColor: LineStyle.white),
            "UU8": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(196, 189, 135), foregroundColor: LineStyle.black),
            "UU9": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(248, 214, 72), foregroundColor: LineStyle.black),
            "UU11": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(157, 157, 156), foregroundColor: LineStyle.white),
            "UU12": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(159, 192, 229), foregroundColor: LineStyle.black),
            "UU13": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(232, 168, 185), foregroundColor: LineStyle.black),
            "UU14": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(127, 180, 80), foregroundColor: LineStyle.black),
            "UU15": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(31, 77, 153), foregroundColor: LineStyle.white),
            "UU19": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(241, 189, 64), foregroundColor: LineStyle.black),
            "UU29": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(248, 214, 72), foregroundColor: LineStyle.black),
            "UU34": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(127, 180, 80), foregroundColor: LineStyle.black),
            
            // Seilbahn
            "T10": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(241, 188, 64), foregroundColor: LineStyle.black),
            "T20": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(241, 188, 64), foregroundColor: LineStyle.black),
            
            // Flughafen-Shuttle
            "BX3": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(217, 34, 42), foregroundColor: LineStyle.white),
            "BX10": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(0, 160, 204), foregroundColor: LineStyle.white),
            "BX60": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(0, 160, 204), foregroundColor: LineStyle.white),
            
            // Busse Esslingen
            "B101": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(199, 55, 55), foregroundColor: LineStyle.white),
            "B102": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(213, 203, 79), foregroundColor: LineStyle.black),
            "B103": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(109, 72, 34), foregroundColor: LineStyle.white),
            "B104": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(186, 151, 114), foregroundColor: LineStyle.white),
            "B105": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(33, 120, 74), foregroundColor: LineStyle.white),
            "B106": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(119, 178, 93), foregroundColor: LineStyle.white),
            "B108": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(112, 96, 150), foregroundColor: LineStyle.white),
            "B109": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(119, 185, 162), foregroundColor: LineStyle.white),
            "B110": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(198, 47, 124), foregroundColor: LineStyle.white),
            "B111": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(233, 181, 74), foregroundColor: LineStyle.black),
            "B112": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(141, 178, 210), foregroundColor: LineStyle.black),
            "B113": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(40, 173, 217), foregroundColor: LineStyle.white),
            "B114": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(172, 137, 161), foregroundColor: LineStyle.black),
            "B115": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(19, 159, 195), foregroundColor: LineStyle.white),
            "B116": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(66, 136, 136), foregroundColor: LineStyle.white),
            "B118": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(158, 100, 68), foregroundColor: LineStyle.white),
            "B119": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(23, 90, 151), foregroundColor: LineStyle.white),
            "B120": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(216, 127, 63), foregroundColor: LineStyle.black),
            "B121": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(66, 84, 96), foregroundColor: LineStyle.white),
            "B122": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(181, 175, 121), foregroundColor: LineStyle.black),
            "B131": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(194, 68, 88), foregroundColor: LineStyle.white),
            "B132": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(124, 130, 50), foregroundColor: LineStyle.white),
            "B138": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(154, 53, 70), foregroundColor: LineStyle.white),
            "B140": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(223, 155, 166), foregroundColor: LineStyle.black)
        ]
    }
    
    override func parseLine(id: String?, network: String?, mot: String?, symbol: String?, name: String?, longName: String?, trainType: String?, trainNum: String?, trainName: String?) -> Line {
        if mot == "0" {
            if trainNum == "IC" {
                return Line(id: id, network: network, product: .highSpeedTrain, label: trainNum)
            }
        }
        return super.parseLine(id: id, network: network, mot: mot == "3" ? "2" : mot, symbol: symbol, name: name, longName: longName, trainType: trainType, trainNum: trainNum, trainName: trainName)
    }
}
