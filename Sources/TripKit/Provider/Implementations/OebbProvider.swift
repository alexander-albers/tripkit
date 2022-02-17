import Foundation

/// ÖBB Personalverkehr AG (AT)
public class OebbProvider: AbstractHafasClientInterfaceProvider {
    
    static let API_BASE = "https://fahrplan.oebb.at/bin/"
    static let PRODUCTS_MAP: [Product?] = [.highSpeedTrain, .highSpeedTrain, .highSpeedTrain, .regionalTrain, .regionalTrain, .suburbanTrain, .bus, .ferry, .subway, .tram, .highSpeedTrain, .onDemand, .highSpeedTrain]
    
    public init(apiAuthorization: [String: Any]) {
        super.init(networkId: .OEBB, apiBase: OebbProvider.API_BASE, productsMap: OebbProvider.PRODUCTS_MAP)
        self.apiAuthorization = apiAuthorization
        apiVersion = "1.54"
        apiClient = ["id": "OEBB", "type": "IPH", "name": "oebbADHOC", "v": "6020300"]
    }
    
    static let PLACES = ["Wien", "Graz", "Linz/Donau", "Salzburg", "Innsbruck"]
    
    override func split(stationName: String?) -> (String?, String?) {
        guard let stationName = stationName else { return super.split(stationName: nil) }
        for place in OebbProvider.PLACES {
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
