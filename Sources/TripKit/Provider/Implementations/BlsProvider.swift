import Foundation

/// Bern-Lötschberg-Simplon (CH)
public class BlsProvider: AbstractHafasClientInterfaceProvider {
    
    static let API_BASE = "https://bls.hafas.de/gate"
    static let PRODUCTS_MAP: [Product?] = [.highSpeedTrain, .highSpeedTrain, .regionalTrain, .regionalTrain, .ferry, .suburbanTrain, .bus, .cablecar, nil, .tram]
    
    public override var supportedLanguages: Set<String> { ["de", "en", "fr", "it"] }
    
    public init(apiAuthorization: [String: Any]) {
        super.init(networkId: .BLS, apiBase: BlsProvider.API_BASE, productsMap: BlsProvider.PRODUCTS_MAP)
        self.mgateEndpoint = BlsProvider.API_BASE
        self.apiAuthorization = apiAuthorization
        apiVersion = "1.68"
        apiClient = ["id": "HAFAS", "type": "WEB", "name": "webapp", "l": "vs_webapp"]
        
        styles = [
            // Tram
            "T3": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#98bbc5"), foregroundColor: LineStyle.white),
            "T6": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#0090d3"), foregroundColor: LineStyle.white),
            "T7": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ff2e18"), foregroundColor: LineStyle.white),
            "T8": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#fc72b6"), foregroundColor: LineStyle.white),
            "T9": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ffbe33"), foregroundColor: LineStyle.white),
            
            // Bus
            "B10": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#02ab4f"), foregroundColor: LineStyle.white),
            "B11": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#34ccf7"), foregroundColor: LineStyle.white),
            "B12": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#ff9127"), foregroundColor: LineStyle.white),
            "B16": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#50c8b1"), foregroundColor: LineStyle.white),
            "B17": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#ada430"), foregroundColor: LineStyle.white),
            "B19": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#821041"), foregroundColor: LineStyle.white),
            "B20": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#821041"), foregroundColor: LineStyle.white),
            "B21": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#f7cd35"), foregroundColor: LineStyle.white),
            "B22": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#98bbc5"), foregroundColor: LineStyle.white),
            "B26": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#ff9a33"), foregroundColor: LineStyle.white),
            "B27": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#5c5515"), foregroundColor: LineStyle.white),
            "B28": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#ada430"), foregroundColor: LineStyle.white),
            "B29": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#fc5757"), foregroundColor: LineStyle.white),
            "B30": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#98bbc5"), foregroundColor: LineStyle.white),
            "B31": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#a3cf44"), foregroundColor: LineStyle.white),
            "B32": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#50c8b1"), foregroundColor: LineStyle.white),
            "B33": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#5c5515"), foregroundColor: LineStyle.white),
            "B34": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#42140e"), foregroundColor: LineStyle.white),
            "B36": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#50c8b1"), foregroundColor: LineStyle.white),
            "B40": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#50c8b1"), foregroundColor: LineStyle.white),
            "B41": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#fc5757"), foregroundColor: LineStyle.white),
            "B43": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#98bbc5"), foregroundColor: LineStyle.white),
            "B44": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#5c5515"), foregroundColor: LineStyle.white),
            "B46": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#ada430"), foregroundColor: LineStyle.white),
            "B47": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#fc5757"), foregroundColor: LineStyle.white),
            
            "B100": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#50c8b1"), foregroundColor: LineStyle.white),
            "B101": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#42140e"), foregroundColor: LineStyle.white),
            "B102": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#5c5515"), foregroundColor: LineStyle.white),
            "B103": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#ff9a33"), foregroundColor: LineStyle.white),
            "B104": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#821041"), foregroundColor: LineStyle.white),
            "B105": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#ada430"), foregroundColor: LineStyle.white),
            "B106": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#ef451a"), foregroundColor: LineStyle.white),
            "B107": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#98bbc5"), foregroundColor: LineStyle.white),
            
            "B340": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#ada430"), foregroundColor: LineStyle.white),
            "B451": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#821041"), foregroundColor: LineStyle.white),
            "B570": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#ada430"), foregroundColor: LineStyle.white),
            "B631": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#5c5515"), foregroundColor: LineStyle.white),
            
            // S-Bahn
            "SS1": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#50bc4a"), foregroundColor: LineStyle.white),
            "SS2": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#1cb7ea"), foregroundColor: LineStyle.white),
            "SS20": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#fc5757"), foregroundColor: LineStyle.white),
            "SS21": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ada430"), foregroundColor: LineStyle.white),
            "SS3": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#7e6bb6"), foregroundColor: LineStyle.white),
            "SS31": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ada430"), foregroundColor: LineStyle.white),
            "SS35": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ff9a33"), foregroundColor: LineStyle.white),
            "SS36": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#1cb7ea"), foregroundColor: LineStyle.white),
            "SS37": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#5d5615"), foregroundColor: LineStyle.white),
            "SS4": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#50c8b1"), foregroundColor: LineStyle.white),
            "SS41": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ff9a33"), foregroundColor: LineStyle.white),
            "SS42": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#fc5757"), foregroundColor: LineStyle.white),
            "SS44": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#5d5615"), foregroundColor: LineStyle.white),
            "SS45": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ada430"), foregroundColor: LineStyle.white),
            "SS5": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#821041"), foregroundColor: LineStyle.white),
            "SS51": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#96cb45"), foregroundColor: LineStyle.white),
            "SS52": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#f7cd35"), foregroundColor: LineStyle.white),
            "SS6": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#fc5757"), foregroundColor: LineStyle.white),
            "SS7": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ff863a"), foregroundColor: LineStyle.white),
            "SS8": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#2c2e35"), foregroundColor: LineStyle.white),
            "SS9": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ff2e18"), foregroundColor: LineStyle.white),
            
            // RE
            "RRE1": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#f7cd35"), foregroundColor: LineStyle.white),
            "RRE2": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#98bbc5"), foregroundColor: LineStyle.white),
            "RRE3": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#821041"), foregroundColor: LineStyle.white),
            "RRE5": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#821041"), foregroundColor: LineStyle.white),
            "RRE7": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#821041"), foregroundColor: LineStyle.white),
        ]
    }
    
    override func newLine(id: String?, network: String?, product: Product?, name: String?, shortName: String?, number: String?, vehicleNumber: String?) -> Line {
        let newName: String?
        if product == .suburbanTrain, let number = number {
            newName = "S\(number)"
        } else if product == .regionalTrain, let number = number, let name = name, name.hasPrefix("RE") {
            newName = "RE\(number)"
        } else {
            newName = name
        }
        return super.newLine(id: id, network: network, product: product, name: newName, shortName: number, number: number, vehicleNumber: vehicleNumber)
    }
    
    static let PLACES = ["Bern"]
    
    override func split(stationName: String?) -> (String?, String?) {
        guard let stationName = stationName else { return super.split(stationName: nil) }
        
        for place in BlsProvider.PLACES {
            if stationName.hasPrefix(place + " ") || stationName.hasPrefix(place + ",") {
                return (place, stationName.substring(from: place.count + 1))
            }
        }
        
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
