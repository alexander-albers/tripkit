import Foundation

public class OoevvProvider: AbstractHafasClientInterfaceProvider {
    
    static let API_BASE = "https://app.verkehrsauskunft.at/bin/"
    static let PRODUCTS_MAP: [Product?] = [.highSpeedTrain, .suburbanTrain, .subway, nil, .tram, .regionalTrain, .bus, .bus, .tram, .ferry, .onDemand, .bus, .regionalTrain, nil, nil, nil]
    
    public init(apiAuthorization: [String: Any], requestVerification: AbstractHafasClientInterfaceProvider.RequestVerification) {
        super.init(networkId: .OOEVV, apiBase: OoevvProvider.API_BASE, productsMap: OoevvProvider.PRODUCTS_MAP)
        self.apiAuthorization = apiAuthorization
        self.requestVerification = requestVerification
        apiVersion = "1.15"
        apiClient = ["id": "VAO", "l": "vs_ooevv", "type": "AND"]
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
        guard let name = poi else { return (nil, nil) }
        if let match = P_SPLIT_NAME_ONE_COMMA.firstMatch(in: name, options: [], range: NSMakeRange(0, name.count)) {
            let substring1 = (name as NSString).substring(with: match.range(at: 1))
            let substring2 = (name as NSString).substring(with: match.range(at: 2))
            return (substring1, substring2)
        }
        return super.split(poi: name)
    }
    
    override func split(address: String?) -> (String?, String?) {
        guard let name = address else { return (nil, nil) }
        if let match = P_SPLIT_NAME_ONE_COMMA.firstMatch(in: name, options: [], range: NSMakeRange(0, name.count)) {
            let substring1 = (name as NSString).substring(with: match.range(at: 1))
            let substring2 = (name as NSString).substring(with: match.range(at: 2))
            return (substring1, substring2)
        }
        return super.split(address: name)
    }
    
}
