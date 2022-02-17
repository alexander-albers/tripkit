import Foundation

/// Steirischer Verkehrsverbund (AT)
public class StvProvider: AbstractHafasClientInterfaceProvider {
    
    static let API_BASE = "https://verkehrsauskunft.verbundlinie.at/bin/"
    static let PRODUCTS_MAP: [Product?] = [.regionalTrain, .suburbanTrain, .subway, nil, .tram, .bus, .bus, .bus, .cablecar, .ferry, .onDemand, nil, nil]
    
    public override var supportedLanguages: Set<String> { ["de", "en"] }
    
    public init(apiAuthorization: [String: Any]) {
        super.init(networkId: .STV, apiBase: StvProvider.API_BASE, productsMap: StvProvider.PRODUCTS_MAP)
        self.apiAuthorization = apiAuthorization
        apiVersion = "1.52"
        apiClient = ["id": "VAO", "type": "WEB", "name": "webapp", "l": "vs_stv"]
        extVersion = "VAO.13"
    }
    
    static let PLACES = ["Wien", "Graz", "Linz/Donau", "Salzburg", "Innsbruck"]
    
    override func split(stationName: String?) -> (String?, String?) {
        guard let stationName = stationName else { return super.split(stationName: nil) }
        for place in StvProvider.PLACES {
            if stationName.hasPrefix(place + " ") {
                return (place, stationName.substring(from: place.length + 1))
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
