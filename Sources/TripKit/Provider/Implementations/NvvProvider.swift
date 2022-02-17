import Foundation

/// Nordhessischer Verkehrsverbund (DE)
public class NvvProvider: AbstractHafasClientInterfaceProvider {
    
    static let API_BASE = "https://auskunft.nvv.de/auskunft/bin/jp/"
    static let PRODUCTS_MAP: [Product?] = [.highSpeedTrain, .highSpeedTrain, .regionalTrain, .suburbanTrain, .subway, .tram, .bus, .bus, .ferry, .onDemand, .regionalTrain, .regionalTrain]
    
    public override var supportedLanguages: Set<String> { ["de"] }
    
    public init(apiAuthorization: [String: Any]) {
        super.init(networkId: .NVV, apiBase: NvvProvider.API_BASE, productsMap: NvvProvider.PRODUCTS_MAP)
        self.apiAuthorization = apiAuthorization
        apiVersion = "1.50"
        apiClient = ["id": "NVV", "type": "WEB", "name": "webapp"]
        
        styles = [
            "R": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(3, 144, 139), foregroundColor: LineStyle.white),
            "RRT 1": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(227, 8, 19), foregroundColor: LineStyle.white),
            "RRT 2": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(227, 8, 19), foregroundColor: LineStyle.white),
            "RRT 3": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(227, 8, 19), foregroundColor: LineStyle.white),
            "RRT 4": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(227, 8, 19), foregroundColor: LineStyle.white),
            "RRT 5": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(227, 8, 19), foregroundColor: LineStyle.white),
        ]
    }
    
    static let places = ["Frankfurt (Main)", "Offenbach (Main)", "Mainz", "Wiesbaden", "Marburg", "Kassel", "Hanau", "Göttingen", "Darmstadt", "Aschaffenburg", "Berlin", "Fulda"]
    
    override func split(stationName: String?) -> (String?, String?) {
        guard let stationName = stationName else { return super.split(stationName: nil) }
        if stationName.hasPrefix("F ") {
            return ("Frankfurt", stationName.substring(from: 2))
        } else if stationName.hasPrefix("OF ") {
            return ("Offenback", stationName.substring(from: 3))
        } else if stationName.hasPrefix("MZ ") {
            return ("Mainz", stationName.substring(from: 3))
        }
        
        for place in NvvProvider.places {
            if stationName.hasPrefix(place + " - ") {
                return (place, stationName.substring(from: place.length + 3))
            } else if stationName.hasPrefix(place + " ") || stationName.hasPrefix(place + "-") {
                return (place, stationName.substring(from: place.length + 1))
            }
        }
        
        return super.split(stationName: stationName)
    }
    
    override func split(address: String?) -> (String?, String?) {
        guard let address = address else { return super.split(address: nil) }
        if let match = address.match(pattern: P_SPLIT_NAME_FIRST_COMMA) {
            return (match[0], match[1])
        }
        return super.split(address: address)
    }
    
}
