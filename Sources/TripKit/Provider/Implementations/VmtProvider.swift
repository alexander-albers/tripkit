import Foundation

/// Verkehrsverbund Mittelthüringen (DE)
public class VmtProvider: AbstractHafasClientInterfaceProvider {
    
    static let API_BASE = "https://vmt.hafas.de/bin/"
    static let PRODUCTS_MAP: [Product?] = [.highSpeedTrain, .highSpeedTrain, .highSpeedTrain, .regionalTrain, .suburbanTrain, .tram, .ferry, .bus, .bus, nil]
    
    public override var supportedLanguages: Set<String> { ["de"] }
    
    public init(apiAuthorization: [String: Any]) {
        super.init(networkId: .VMT, apiBase: VmtProvider.API_BASE, productsMap: VmtProvider.PRODUCTS_MAP)
        self.apiAuthorization = apiAuthorization
        apiVersion = "1.54"
        apiClient = ["name": "VMT", "type": "WEB"]
    }
    
    static let PLACES = ["Erfurt", "Jena", "Gera", "Weimar", "Gotha"]
    
    override func split(stationName: String?) -> (String?, String?) {
        guard var stationName = stationName else { return super.split(stationName: nil) }
        if stationName.hasSuffix(" [Zug]") {
            stationName = stationName.substring(to: stationName.count - 6)
        }
        for place in VmtProvider.PLACES {
            if stationName.hasPrefix(place + ", ") {
                return (place, stationName.substring(from: place.count + 2))
            } else if stationName.hasPrefix(place + " ") || stationName.hasPrefix(place + "-") {
                return (place, stationName.substring(from: place.count + 1))
            }
        }
        return super.split(stationName: stationName)
    }
    
    override func split(address: String?) -> (String?, String?) {
        guard let address = address else { return super.split(address: nil) }
        if let m = address.match(pattern: P_SPLIT_NAME_FIRST_COMMA) {
            return (m[0], m[1])
        }
        return super.split(address: address)
    }
    
}
