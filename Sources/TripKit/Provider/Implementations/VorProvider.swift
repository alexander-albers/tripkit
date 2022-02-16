import Foundation

// Verkehrsverbund Ost-Region (Lower Austria and Burgenland, Austria)
public class VorProvider: AbstractHafasClientInterfaceProvider {
    
    static let API_BASE = "https://anachb.vor.at/bin/"
    static let PRODUCTS_MAP: [Product?] = [.highSpeedTrain, .suburbanTrain, .subway, nil, .tram, .regionalTrain, .bus, .bus, .tram, .ferry, .onDemand, .bus, .regionalTrain, nil, nil, nil]
    
    public init(apiAuthorization: [String: Any]) {
        super.init(networkId: .VOR, apiBase: VorProvider.API_BASE, productsMap: VorProvider.PRODUCTS_MAP)
        self.apiAuthorization = apiAuthorization
        apiVersion = "1.52"
        apiClient = ["id": "VAO", "type": "WEB", "name": "webapp", "l": "vs_anachb"]
        extVersion = "VAO.9"
        
        styles = [
            "SS1": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#1e5cb3"), foregroundColor: LineStyle.white),
            "SS2": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#59c594"), foregroundColor: LineStyle.white),
            "SS3": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#c8154c"), foregroundColor: LineStyle.black),
            "SS7": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#dc35a3"), foregroundColor: LineStyle.white),
            "SS40": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#f24d3e"), foregroundColor: LineStyle.white),
            "SS45": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#0f8572"), foregroundColor: LineStyle.white),
            "SS50": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#34b6e5"), foregroundColor: LineStyle.white),
            "SS60": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#82b429"), foregroundColor: LineStyle.white),
            "SS80": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#e96619"), foregroundColor: LineStyle.white),
            "UU1": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#c6292a"), foregroundColor: LineStyle.white),
            "UU2": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#a82783"), foregroundColor: LineStyle.white),
            "UU3": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#f39315"), foregroundColor: LineStyle.white),
            "UU4": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#23a740"), foregroundColor: LineStyle.white),
            "UU6": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#be762c"), foregroundColor: LineStyle.white),
        ]
    }
    
    let P_SPLIT_NAME_ONE_COMMA = try! NSRegularExpression(pattern: "([^,]*), ([^,]*)")
    
    override func split(stationName: String?) -> (String?, String?) {
        guard let name = stationName else { return (nil, nil) }
        if let match = P_SPLIT_NAME_ONE_COMMA.firstMatch(in: name, options: [], range: NSMakeRange(0, name.count)) {
            let substring1 = (name as NSString).substring(with: match.range(at: 1))
            let substring2 = (name as NSString).substring(with: match.range(at: 2))
            return (substring2, substring1)
        }
        return super.split(stationName: name)
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

