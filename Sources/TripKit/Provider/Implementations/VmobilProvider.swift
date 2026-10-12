import Foundation

/// Vorarlberger Verkehrsverbund (AT)
public class VmobilProvider: AbstractHafasClientInterfaceProvider {
    
    static let API_BASE = "https://fahrplan.vmobil.at/bin/"
    static let PRODUCTS_MAP: [Product?] = [.highSpeedTrain, .suburbanTrain, .subway, nil, .tram, .regionalTrain, .bus, .bus, .tram, .ferry, .onDemand, .bus, .regionalTrain, nil, nil, nil]
    
    public override var supportedLanguages: Set<String> { ["de"] }
    
    public init(apiAuthorization: [String: Any]) {
        super.init(networkId: .VMOBIL, apiBase: VmobilProvider.API_BASE, productsMap: VmobilProvider.PRODUCTS_MAP)
        self.apiAuthorization = apiAuthorization
        apiVersion = "1.52"
        apiClient = ["id": "VAO", "type": "WEB", "name": "webapp", "l": "vs_vvv"]
        extVersion = "VAO.6"
    }
    
    let P_SPLIT_NAME_ONE_COMMA = try! NSRegularExpression(pattern: "([^,]*), ([^,]*)")
    
    override func split(stationName: String?) -> (String?, String?) {
        guard let stationName = stationName else { return super.split(poi: nil) }
        if let m = stationName.match(pattern: P_SPLIT_NAME_ONE_COMMA) {
            return (m[1], m[0])
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
