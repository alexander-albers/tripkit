import Foundation

/// Verkehrsgemeinschaft Osnabrück (DE)
public class VosProvider: AbstractHafasClientInterfaceProvider {
    
    static let API_BASE = "https://fahrplan.vos.info/bin/"
    static let PRODUCTS_MAP: [Product?] = [.highSpeedTrain, .highSpeedTrain, .highSpeedTrain, .regionalTrain, .suburbanTrain, .bus, .ferry, .subway, .tram, nil, nil, nil, .highSpeedTrain]
    
    public override var supportedLanguages: Set<String> { ["de"] }
    
    public init(apiAuthorization: [String: Any]) {
        super.init(networkId: .VOS, apiBase: VosProvider.API_BASE, productsMap: VosProvider.PRODUCTS_MAP)
        self.apiAuthorization = apiAuthorization
        apiVersion = "1.52"
        apiClient = ["id": "SWO", "type": "WEB", "name": "webapp"]
    }
    
    static let PLACES = ["Osnabrück", "Bad Essen", "Bad Iburg", "Bad Laer", "Glandorf", "Bramsche", "Hagen", "Bissendorf", "Hilter"]
    
    override func split(stationName: String?) -> (String?, String?) {
        guard let stationName = stationName else { return super.split(stationName: nil) }
        for place in VosProvider.PLACES {
            if stationName.hasPrefix(place + " ") {
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
}
