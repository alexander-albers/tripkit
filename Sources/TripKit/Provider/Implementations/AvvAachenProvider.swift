import Foundation

public class AvvAachenProvider: AbstractHafasClientInterfaceProvider {
    
    static let API_BASE = "https://auskunft.avv.de/bin/"
    static let PRODUCTS_MAP: [Product?] = [.regionalTrain, .highSpeedTrain, .highSpeedTrain, .bus, .suburbanTrain, .subway, .tram, .bus, .bus, .onDemand, .ferry]
    
    public init(apiAuthorization: [String: Any]) {
        super.init(networkId: .AVV2, apiBase: AvvAachenProvider.API_BASE, productsMap: AvvAachenProvider.PRODUCTS_MAP)
        self.apiAuthorization = apiAuthorization
        apiVersion = "1.18"
        apiClient = ["id": "AVV_AACHEN","type": "WEB",
                     "name": "webapp",
                     "l": "vs_avv"]
    }
    
    override func split(stationName: String?) -> (String?, String?) {
        guard let stationName = stationName else { return super.split(stationName: nil) }
        if let m = stationName.match(pattern: P_SPLIT_NAME_FIRST_COMMA) {
            if m[1] == "AC" {
                return ("Aachen", m[0])
            } else {
                return (m[0], m[1])
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
    
    override func hideFare(_ fare: Fare) -> Bool {
        let fareNameLc = fare.name?.lowercased() ?? ""
        switch fareNameLc {
        case let name where name.contains("einzel-ticket"): return false
        default: return true
        }
    }
    
}
