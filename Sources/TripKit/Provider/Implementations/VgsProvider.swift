import Foundation

public class VgsProvider: AbstractHafasClientInterfaceProvider {
    
    static let API_BASE = "https://saarfahrplan.de/bin/"
    static let PRODUCTS_MAP: [Product?] = [.highSpeedTrain, .highSpeedTrain, .highSpeedTrain, .regionalTrain, .suburbanTrain, .subway, .tram, .bus, .cablecar, .onDemand, .bus]
    
    public init(apiAuthorization: [String: Any]) {
        super.init(networkId: .VGS, apiBase: VgsProvider.API_BASE, productsMap: VgsProvider.PRODUCTS_MAP)
        self.apiAuthorization = apiAuthorization
        self.requestVerification = .rnd
        apiVersion = "1.54"
        apiClient = ["id": "ZPS-SAAR", "type": "WEB", "name": "webapp"]
    }
    
    override func split(stationName: String?) -> (String?, String?) {
        guard let stationName = stationName else { return super.split(stationName: nil) }
        if let m = stationName.match(pattern: P_SPLIT_NAME_FIRST_COMMA), m[0] != nil {
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
