import Foundation

/// Verkehrsverbund Süd-Niedersachsen (DE)
public class VsnProvider: AbstractHafasClientInterfaceProvider {
    
    static let API_BASE = "https://fahrplaner.vsninfo.de/hafas/"
    static let PRODUCTS_MAP: [Product?] = [.highSpeedTrain, .highSpeedTrain, .regionalTrain, .regionalTrain, .suburbanTrain, .bus, .ferry, .subway, .tram, .onDemand]
    
    public override var supportedLanguages: Set<String> { ["de"] }
    
    public init(apiAuthorization: [String: Any]) {
        super.init(networkId: .VSN, apiBase: VsnProvider.API_BASE, productsMap: VsnProvider.PRODUCTS_MAP)
        self.apiAuthorization = apiAuthorization
        apiVersion = "1.52"
        apiClient = ["id": "VSN", "type": "WEB", "name": "webapp"]
        
        styles = [
            "B11": LineStyle(shape: .rounded, backgroundColor: LineStyle.white, foregroundColor: LineStyle.rgb(231, 155, 55), borderColor: LineStyle.rgb(231, 155, 55)),
            "B12": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(231, 155, 55), foregroundColor: LineStyle.white),
            "B21": LineStyle(shape: .rounded, backgroundColor: LineStyle.white, foregroundColor: LineStyle.rgb(186, 42, 33), borderColor: LineStyle.rgb(186, 42, 33)),
            "B22": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(186, 42, 33), foregroundColor: LineStyle.white),
            "B23": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(218, 152, 126), foregroundColor: LineStyle.white, borderColor: LineStyle.rgb(186, 42, 33)),
            "B31": LineStyle(shape: .rounded, backgroundColor: LineStyle.white, foregroundColor: LineStyle.rgb(157, 192, 65), borderColor: LineStyle.rgb(157, 192, 65)),
            "B32": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(157, 192, 65), foregroundColor: LineStyle.white),
            "B33": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(112, 151, 63), foregroundColor: LineStyle.white),
            "B41": LineStyle(shape: .rounded, backgroundColor: LineStyle.white, foregroundColor: LineStyle.rgb(70, 156, 221), borderColor: LineStyle.rgb(70, 156, 221)),
            "B42": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(70, 156, 221), foregroundColor: LineStyle.white),
            "B50": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(42, 101, 55), foregroundColor: LineStyle.white),
            "B61": LineStyle(shape: .rounded, backgroundColor: LineStyle.white, foregroundColor: LineStyle.rgb(139, 36, 101), borderColor: LineStyle.rgb(139, 36, 101)),
            "B62": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(139, 36, 101), foregroundColor: LineStyle.white),
            "B71": LineStyle(shape: .rounded, backgroundColor: LineStyle.white, foregroundColor: LineStyle.rgb(50, 54, 136), borderColor: LineStyle.rgb(50, 54, 136)),
            "B72": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(50, 54, 136), foregroundColor: LineStyle.white),
            "B73": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(149, 145, 194), foregroundColor: LineStyle.white, borderColor: LineStyle.rgb(50, 54, 136)),
            "B80": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(247, 206, 70), foregroundColor: LineStyle.black),
            "B91": LineStyle(shape: .rounded, backgroundColor: LineStyle.white, foregroundColor: LineStyle.rgb(145, 103, 149), borderColor: LineStyle.rgb(145, 103, 149)),
            "B92": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(145, 103, 149), foregroundColor: LineStyle.white),
            "BLT61": LineStyle(shape: .rounded, backgroundColor: LineStyle.white, foregroundColor: LineStyle.rgb(139, 36, 101), borderColor: LineStyle.rgb(139, 36, 101)),
        ]
    }
    
    static let PLACES = ["Göttingen", "Northeim"]
    
    override func split(stationName: String?) -> (String?, String?) {
        guard let stationName = stationName else { return super.split(stationName: nil) }
        for place in VsnProvider.PLACES {
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

