import Foundation

/// Nahverkehrsservice Sachsen-Anhalt (DE)
public class NasaProvider: AbstractHafasClientInterfaceProvider {
    
    static let API_BASE = "https://reiseauskunft.insa.de/bin/"
    static let PRODUCTS_MAP: [Product?] = [.highSpeedTrain, .highSpeedTrain, .highSpeedTrain, .regionalTrain, .suburbanTrain, .tram, .bus, .bus, .onDemand, .ferry]
    
    public override var supportedLanguages: Set<String> { ["de", "en"] }
    
    public init(apiAuthorization: [String: Any]) {
        super.init(networkId: .NASA, apiBase: NasaProvider.API_BASE, productsMap: NasaProvider.PRODUCTS_MAP)
        self.apiAuthorization = apiAuthorization
        apiVersion = "1.48"
        apiClient = ["id": "NASA", "type": "WEB", "name": "webapp", "l": "vs_webapp_nasa"]
        
        styles = [
            "RRE1": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(197, 53, 63), foregroundColor: LineStyle.white),
            "RRE2": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(254, 218, 47), foregroundColor: LineStyle.white),
            "RRE3": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(39, 77, 144), foregroundColor: LineStyle.white),
            "RRE4": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(195, 118, 130), foregroundColor: LineStyle.white),
            "RHEX4": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(91, 69, 45), foregroundColor: LineStyle.white),
            "RRE6": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(86, 40, 96), foregroundColor: LineStyle.white),
            "RRE7": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(0, 100, 56), foregroundColor: LineStyle.white),
            "RRE9": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(0, 100, 56), foregroundColor: LineStyle.white),
            "RRE10": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(86, 40, 96), foregroundColor: LineStyle.white),
            "RHEX11": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(39, 77, 144), foregroundColor: LineStyle.white),
            "REBx12": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(39, 77, 144), foregroundColor: LineStyle.white),
            "RRE13": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(39, 77, 144), foregroundColor: LineStyle.white),
            "RRE14": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(27, 25, 25), foregroundColor: LineStyle.white),
            "RSE15": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(54, 160, 205), foregroundColor: LineStyle.white),
            "RRE16": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(86, 40, 96), foregroundColor: LineStyle.white),
            "RRE17": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(54, 160, 205), foregroundColor: LineStyle.white),
            "RRE18": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(195, 118, 130), foregroundColor: LineStyle.white),
            "RRE19": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(132, 190, 66), foregroundColor: LineStyle.white),
            "RRE20": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(91, 69, 45), foregroundColor: LineStyle.white),
            "RRB20": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(39, 77, 144), foregroundColor: LineStyle.white),
            "RHEX21": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(39, 77, 144), foregroundColor: LineStyle.white),
            "REB22": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(39, 77, 144), foregroundColor: LineStyle.white),
            "RRB24": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(197, 53, 63), foregroundColor: LineStyle.white),
            "RHEX24": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(157, 116, 78), foregroundColor: LineStyle.white),
            "RRB27": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(157, 116, 78), foregroundColor: LineStyle.white),
            "RRE30": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(27, 25, 25), foregroundColor: LineStyle.white),
            "RHEX31": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(39, 77, 144), foregroundColor: LineStyle.white),
            "RRB32": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(132, 190, 66), foregroundColor: LineStyle.white),
            "RRB33": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(217, 34, 42), foregroundColor: LineStyle.white),
            "RRB34": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(54, 160, 205), foregroundColor: LineStyle.white),
            "RRB35": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(40, 51, 120), foregroundColor: LineStyle.white),
            "RRB36": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(195, 118, 130), foregroundColor: LineStyle.white),
            "RRB40": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(132, 190, 66), foregroundColor: LineStyle.white),
            "RRB41": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(195, 118, 130), foregroundColor: LineStyle.white),
            "RRB42": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(157, 116, 78), foregroundColor: LineStyle.white),
            "RHEX43": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(54, 160, 205), foregroundColor: LineStyle.white),
            "RHEX44": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(195, 118, 130), foregroundColor: LineStyle.white),
            "RHEX47": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(255, 219, 48), foregroundColor: LineStyle.black),
            "RRB48": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(52, 127, 116), foregroundColor: LineStyle.white),
            "RRB50": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(197, 53, 63), foregroundColor: LineStyle.white),
            "RRB51": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(195, 118, 130), foregroundColor: LineStyle.white),
            "RRB59": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(132, 190, 66), foregroundColor: LineStyle.white),
            "RRB75": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(157, 116, 78), foregroundColor: LineStyle.white),
            "RRB76": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(91, 69, 45), foregroundColor: LineStyle.white),
            "RRB77": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(91, 69, 45), foregroundColor: LineStyle.white),
            "RRB78": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(91, 69, 45), foregroundColor: LineStyle.white),
            "SS1": LineStyle(shape: .circle, backgroundColor: LineStyle.rgb(0, 100, 56), foregroundColor: LineStyle.white),
            "SS2": LineStyle(shape: .circle, backgroundColor: LineStyle.rgb(54, 160, 205), foregroundColor: LineStyle.white),
            "SS3": LineStyle(shape: .circle, backgroundColor: LineStyle.rgb(196, 35, 42), foregroundColor: LineStyle.white),
            "SS30": LineStyle(shape: .circle, backgroundColor: LineStyle.rgb(196, 35, 42), foregroundColor: LineStyle.white),
            "SS4": LineStyle(shape: .circle, backgroundColor: LineStyle.rgb(0, 136, 88), foregroundColor: LineStyle.white),
            "SS5": LineStyle(shape: .circle, backgroundColor: LineStyle.rgb(216, 102, 43), foregroundColor: LineStyle.white),
            "SS5x": LineStyle(shape: .circle, backgroundColor: LineStyle.rgb(243, 179, 63), foregroundColor: LineStyle.white),
            "SS6": LineStyle(shape: .circle, backgroundColor: LineStyle.rgb(65, 19, 45), foregroundColor: LineStyle.white),
            "SS7": LineStyle(shape: .circle, backgroundColor: LineStyle.rgb(0, 84, 142), foregroundColor: LineStyle.white),
            "SS8": LineStyle(shape: .circle, backgroundColor: LineStyle.rgb(95, 42, 121), foregroundColor: LineStyle.white),
            "SS9": LineStyle(shape: .circle, backgroundColor: LineStyle.rgb(173, 25, 100), foregroundColor: LineStyle.white),
        ]
    }
    
    override func jsonLocation(from location: Location) -> [String: Any] {
        if let id = location.id {
            // Workaround: drop type=S field
            if id.hasSuffix("@") {
                return ["lid": id]
            } else {
                return ["extId": id]
            }
        }
        return super.jsonLocation(from: location)
    }
    
    override func hideFare(_ fare: Fare) -> Bool {
        switch fare.name?.lowercased() ?? "" {
        case let x where x.contains("abo"): return true
        case let x where x.contains("4-fahrten"): return true
        case let x where x.contains("24-stunden"): return true
        case let x where x.contains("24-std"): return true
        case let x where x.contains("wochen"): return true
        case let x where x.contains("monat"): return true
        case let x where x.contains("abo flex"): return true
        case let x where x.contains("flexpreis"): return true
        case let x where x.contains("extrakarte"): return true
        case let x where x.contains("hopperticket"): return true
        default: return false
        }
    }
    
    override func split(stationName: String?) -> (String?, String?) {
        guard let stationName = stationName else { return super.split(stationName: nil) }
        if let m = stationName.match(pattern: P_SPLIT_NAME_FIRST_COMMA) {
            return (m[0], m[1])
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
    
}
