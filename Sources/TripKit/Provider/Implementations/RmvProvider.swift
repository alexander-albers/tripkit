import Foundation

/// Rhein-Main-Verkehrsverbund (DE)
public class RmvProvider: AbstractHafasClientInterfaceProvider {
    
    static let API_BASE = "https://www.rmv.de/auskunft/bin/jp/"
    
    static let PRODUCTS_MAP: [Product?] = [.highSpeedTrain, .highSpeedTrain, .regionalTrain, .suburbanTrain, .subway, .tram, .bus, .bus, .ferry, .onDemand, .tram, nil, nil]
    
    public override var supportedLanguages: Set<String> { ["de", "en"] }
    
    public init(apiAuthorization: [String: Any]) {
        super.init(networkId: .RMV, apiBase: RmvProvider.API_BASE, productsMap: RmvProvider.PRODUCTS_MAP)
        self.apiAuthorization = apiAuthorization
        apiVersion = "1.66"
        apiClient = ["id": "RMV", "type": "WEB", "name": "webapp", "l": "vs_webapp"]
        
        styles = [
            "UU1": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(184, 41, 47), foregroundColor: LineStyle.white),
            "UU2": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(0, 166, 81), foregroundColor: LineStyle.white),
            "UU3": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(75, 93, 170), foregroundColor: LineStyle.white),
            "UU4": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(240, 92, 161), foregroundColor: LineStyle.white),
            "UU5": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(1, 122, 67), foregroundColor: LineStyle.white),
            "UU6": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(1, 125, 198), foregroundColor: LineStyle.white),
            "UU7": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(228, 161, 35), foregroundColor: LineStyle.white),
            "UU8": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(199, 125, 181), foregroundColor: LineStyle.white),
            "UU9": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(255, 222, 1), foregroundColor: LineStyle.black),
            
            "SS1": LineStyle(shape: .circle, backgroundColor: LineStyle.rgb(0, 136, 195), foregroundColor: LineStyle.white),
            "SS2": LineStyle(shape: .circle, backgroundColor: LineStyle.rgb(210, 33, 41), foregroundColor: LineStyle.white),
            "SS3": LineStyle(shape: .circle, backgroundColor: LineStyle.rgb(0, 157, 135), foregroundColor: LineStyle.white),
            "SS4": LineStyle(shape: .circle, backgroundColor: LineStyle.rgb(255, 222, 1), foregroundColor: LineStyle.black, borderColor: LineStyle.black),
            "SS5": LineStyle(shape: .circle, backgroundColor: LineStyle.rgb(133, 84, 55), foregroundColor: LineStyle.white),
            "SS6": LineStyle(shape: .circle, backgroundColor: LineStyle.rgb(229, 113, 42), foregroundColor: LineStyle.white),
            "SS7": LineStyle(shape: .circle, backgroundColor: LineStyle.rgb(37, 75, 58), foregroundColor: LineStyle.white),
            "SS8": LineStyle(shape: .circle, backgroundColor: LineStyle.rgb(131, 191, 66), foregroundColor: LineStyle.white),
            "SS9": LineStyle(shape: .circle, backgroundColor: LineStyle.rgb(129, 43, 124), foregroundColor: LineStyle.white),
            
            "T11": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(136, 129, 189), foregroundColor: LineStyle.white),
            "T12": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(231, 185, 9), foregroundColor: LineStyle.white),
            "T14": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(0, 166, 222), foregroundColor: LineStyle.white),
            "T15": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(245, 130, 32), foregroundColor: LineStyle.white),
            "T16": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(81, 184, 72), foregroundColor: LineStyle.white),
            "T17": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(237, 29, 37), foregroundColor: LineStyle.white),
            "T18": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(22, 71, 158), foregroundColor: LineStyle.white),
            "T19": LineStyle(shape: .rect, backgroundColor: LineStyle.white, foregroundColor: LineStyle.rgb(120, 205, 208), borderColor: LineStyle.rgb(120, 205, 208)),
            "T20": LineStyle(shape: .rect, backgroundColor: LineStyle.white, foregroundColor: LineStyle.rgb(148, 149, 152), borderColor: LineStyle.rgb(148, 149, 152)),
            "T21": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(242, 135, 183), foregroundColor: LineStyle.white),
            
            "RRB2": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(100, 183, 117), foregroundColor: LineStyle.white),
            "RRB5": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(0, 115, 176), foregroundColor: LineStyle.white),
            "RRB6": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(187, 117, 163), foregroundColor: LineStyle.white),
            "RRB7": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(0, 115, 176), foregroundColor: LineStyle.white),
            "RRB10": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(216, 154, 47), foregroundColor: LineStyle.white),
            "RRB11": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(0, 115, 176), foregroundColor: LineStyle.white),
            "RRB12": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(133, 84, 55), foregroundColor: LineStyle.white),
            "RRB15": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(216, 154, 47), foregroundColor: LineStyle.white),
            "RRB16": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(0, 115, 176), foregroundColor: LineStyle.white),
            "RRB17": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(187, 117, 163), foregroundColor: LineStyle.white),
            "RRB21": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(0, 115, 176), foregroundColor: LineStyle.white),
            "RRB22": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(217, 34, 42), foregroundColor: LineStyle.white),
            "RRB23": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(0, 184, 224), foregroundColor: LineStyle.white),
            "RRB26": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(0, 115, 176), foregroundColor: LineStyle.white),
            "RRB29": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(187, 117, 163), foregroundColor: LineStyle.white),
            "RRB31": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(0, 184, 224), foregroundColor: LineStyle.white),
            "RRB33": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(133, 84, 55), foregroundColor: LineStyle.white),
            "RRB34": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(0, 115, 176), foregroundColor: LineStyle.white),
            "RRB35": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(129, 43, 124), foregroundColor: LineStyle.white),
            "RRB38": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(216, 154, 47), foregroundColor: LineStyle.white),
            "RRB39": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(0, 183, 223), foregroundColor: LineStyle.white),
            "RRB40": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(129, 43, 124), foregroundColor: LineStyle.white),
            "RRB41": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(129, 43, 124), foregroundColor: LineStyle.white),
            "RRB42": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(133, 84, 55), foregroundColor: LineStyle.white),
            "RRB44": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(129, 43, 124), foregroundColor: LineStyle.white),
            "RRB45": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(0, 115, 176), foregroundColor: LineStyle.white),
            "RRB46": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(133, 84, 55), foregroundColor: LineStyle.white),
            "RRB47": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(187, 117, 163), foregroundColor: LineStyle.white),
            "RRB48": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(216, 154, 47), foregroundColor: LineStyle.white),
            "RRB49": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(0, 115, 176), foregroundColor: LineStyle.white),
            "RRB50": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(217, 34, 42), foregroundColor: LineStyle.white),
            "RRB51": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(217, 34, 42), foregroundColor: LineStyle.white),
            "RRB52": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(216, 154, 47), foregroundColor: LineStyle.white),
            "RRB53": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(216, 154, 47), foregroundColor: LineStyle.white),
            "RRB56": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(0, 115, 176), foregroundColor: LineStyle.white),
            "RRB58": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(129, 43, 124), foregroundColor: LineStyle.white),
            "RRB60": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(216, 154, 47), foregroundColor: LineStyle.white),
            "RRB61": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(0, 115, 176), foregroundColor: LineStyle.white),
            "RRB62": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(187, 117, 163), foregroundColor: LineStyle.white),
            "RRB63": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(0, 184, 224), foregroundColor: LineStyle.white),
            "RRB65": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(187, 117, 163), foregroundColor: LineStyle.white),
            "RRB66": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(0, 115, 176), foregroundColor: LineStyle.white),
            "RRB67": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(216, 154, 47), foregroundColor: LineStyle.white),
            "RRB68": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(216, 154, 47), foregroundColor: LineStyle.white),
            "RRB69": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(0, 184, 224), foregroundColor: LineStyle.white),
            "RRB75": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(0, 115, 176), foregroundColor: LineStyle.white),
            "RRB81": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(217, 34, 42), foregroundColor: LineStyle.white),
            "RRB82": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(217, 34, 42), foregroundColor: LineStyle.white),
            "RRB85": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(216, 154, 47), foregroundColor: LineStyle.white),
            "RRB86": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(216, 154, 47), foregroundColor: LineStyle.white),
            "RRB90": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(129, 43, 124), foregroundColor: LineStyle.white),
            "RRB94": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(0, 115, 176), foregroundColor: LineStyle.white),
            "RRB95": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(217, 34, 42), foregroundColor: LineStyle.white),
            "RRB96": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(0, 115, 176), foregroundColor: LineStyle.white),
            
            "RRE2": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(216, 154, 47), foregroundColor: LineStyle.white),
            "RRE3": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(216, 154, 47), foregroundColor: LineStyle.white),
            "RRE4": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(217, 34, 42), foregroundColor: LineStyle.white),
            "RRE12": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(133, 84, 55), foregroundColor: LineStyle.white),
            "RRE13": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(0, 184, 224), foregroundColor: LineStyle.white),
            "RRE14": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(217, 34, 42), foregroundColor: LineStyle.white),
            "RRE15": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(216, 154, 47), foregroundColor: LineStyle.white),
            "RRE17": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(187, 117, 163), foregroundColor: LineStyle.white),
            "RRE20": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(217, 34, 42), foregroundColor: LineStyle.white),
            "RRE25": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(0, 115, 176), foregroundColor: LineStyle.white),
            "RRE30": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(217, 34, 42), foregroundColor: LineStyle.white),
            "RRE31": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(0, 184, 224), foregroundColor: LineStyle.white),
            "RRE50": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(217, 34, 42), foregroundColor: LineStyle.white),
            "RRE51": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(217, 34, 42), foregroundColor: LineStyle.white),
            "RRE54": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(129, 43, 124), foregroundColor: LineStyle.white),
            "RRE55": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(129, 43, 124), foregroundColor: LineStyle.white),
            "RRE59": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(129, 43, 124), foregroundColor: LineStyle.white),
            "RRE60": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(216, 154, 47), foregroundColor: LineStyle.white),
            "RRE70": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(217, 34, 42), foregroundColor: LineStyle.white),
            "RRE80": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(217, 34, 42), foregroundColor: LineStyle.white),
            "RRE85": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(216, 154, 47), foregroundColor: LineStyle.white),
            "RRE98": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(216, 154, 47), foregroundColor: LineStyle.white),
            "RRE99": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(216, 154, 47), foregroundColor: LineStyle.white)
        ]
    }
    
    static let places = ["Frankfurt (Main)", "Offenbach (Main)", "Mainz", "Wiesbaden", "Marburg", "Kassel", "Hanau", "Göttingen", "Darmstadt", "Aschaffenburg", "Berlin", "Fulda"]
    
    override func split(stationName: String?) -> (String?, String?) {
        guard let stationName = stationName else { return super.split(stationName: nil) }
        if stationName.hasPrefix("F ") {
            return ("Frankfurt", stationName.substring(from: 2))
        } else if stationName.hasPrefix("OF ") {
            return ("Offenback", stationName.substring(from: 3))
        } else if stationName.hasPrefix("MZ ") {
            return ("Mainz", stationName.substring(from: 3))
        }
        
        for place in RmvProvider.places {
            if stationName.hasPrefix(place + " - ") {
                return (place, stationName.substring(from: place.count + 3))
            } else if stationName.hasPrefix(place + " ") || stationName.hasPrefix(place + "-") {
                return (place, stationName.substring(from: place.count + 1))
            }
        }
        
        return super.split(stationName: stationName)
    }
    
    override func split(poi: String?) -> (String?, String?) {
        guard let poi = poi else { return super.split(poi: nil) }
        if let m = poi.match(pattern: P_SPLIT_NAME_FIRST_COMMA) {
            return (m[0], m[1])
        }
        return super.split(poi: poi)
    }
    
    override func split(address: String?) -> (String?, String?) {
        guard let address = address else { return super.split(address: nil) }
        if let m = address.match(pattern: P_SPLIT_NAME_FIRST_COMMA) {
            return (m[0], m[1])
        }
        return super.split(address: address)
    }
    
    override func parse(fareName: String?, ticketName: String?) -> String {
        if fareName != "0" {
            return super.parse(fareName: nil, ticketName: ticketName) + " with changes"
        }
        return super.parse(fareName: nil, ticketName: ticketName)
    }
    
    override func hideFare(_ fare: Fare) -> Bool {
        if fare.name?.hasSuffix(" with changes") ?? false {
            return true
        }
        return super.hideFare(fare)
    }
    
}
