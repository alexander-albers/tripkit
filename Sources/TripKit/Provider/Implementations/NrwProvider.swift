import Foundation

public class NrwProvider: AbstractHafasClientInterfaceProvider {
    
    static let API_BASE = "https://nrw.hafas.de/bin/"
    static let PRODUCTS_MAP: [Product?] = [.highSpeedTrain, .highSpeedTrain, .highSpeedTrain, .regionalTrain, .suburbanTrain, .bus, nil, .subway, .tram, .onDemand, nil, nil, nil]
    
    public init(apiAuthorization: [String: Any]) {
        super.init(networkId: .NRW, apiBase: NrwProvider.API_BASE, productsMap: NrwProvider.PRODUCTS_MAP)
        self.apiAuthorization = apiAuthorization
        apiVersion = "1.46"
        apiClient = ["id": "DB-REGIO-NRW", "type": "WEB", "name": "webapp"]
        extVersion = "DB.R19.04.a"
        
        styles = [
            "RRE 1": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#d7242a"), foregroundColor: LineStyle.white),
            "RRE 2": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#00a3db"), foregroundColor: LineStyle.white),
            "RRE 3": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#c66c2f"), foregroundColor: LineStyle.white),
            "RRE 4": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#cb8b26"), foregroundColor: LineStyle.white),
            "RRE 5": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#0273a2"), foregroundColor: LineStyle.white),
            "RRE 6": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#912a7d"), foregroundColor: LineStyle.white),
            "RRE 7": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#0c2954"), foregroundColor: LineStyle.white),
            "RRE 8": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#0062a2"), foregroundColor: LineStyle.white),
            "RRE 9": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#39143a"), foregroundColor: LineStyle.white),
            "RRE 10": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#cd5c91"), foregroundColor: LineStyle.white),
            "RRE 11": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#5ebcb1"), foregroundColor: LineStyle.white),
            "RRE 12": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#952b4b"), foregroundColor: LineStyle.white),
            "RRE 13": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#6d5525"), foregroundColor: LineStyle.white),
            "RRE 14": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#013929"), foregroundColor: LineStyle.white),
            "RRE 15": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#805492"), foregroundColor: LineStyle.white),
            "RRE 16": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#005368"), foregroundColor: LineStyle.white),
            "RRE 17": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#488d42"), foregroundColor: LineStyle.white),
            "RRE 18": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#15aba2"), foregroundColor: LineStyle.white),
            "RRE 19": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#1d5828"), foregroundColor: LineStyle.white),
            "RRE 22": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#efa940"), foregroundColor: LineStyle.white),
            "RRE 29": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#c788b1"), foregroundColor: LineStyle.white),
            "RRE 42": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#cab631"), foregroundColor: LineStyle.white),
            "RRE 44": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#628da0"), foregroundColor: LineStyle.white),
            "RRE 49": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#b78970"), foregroundColor: LineStyle.white),
            "RRE 57": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#3c6390"), foregroundColor: LineStyle.white),
            "RRE 60": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#005129"), foregroundColor: LineStyle.white),
            "RRE 70": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#8883b0"), foregroundColor: LineStyle.white),
            "RRE 78": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#56a9b9"), foregroundColor: LineStyle.white),
            "RRE 82": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#488d42"), foregroundColor: LineStyle.white),
            "RRE 99": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#01a249"), foregroundColor: LineStyle.white),
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
