import Foundation

/// Salzburger Verkehrsverbund (AT)
public class SvvProvider: AbstractHafasClientInterfaceProvider {
    
    static let API_BASE = "https://fahrplan.salzburg-verkehr.at/bin/"
    static let PRODUCTS_MAP: [Product?] = [.highSpeedTrain, .suburbanTrain, .subway, nil, .tram, .regionalTrain, .bus, .bus, .tram, .ferry, .onDemand, .bus, .regionalTrain, nil, nil, nil]
    
    public init(apiAuthorization: [String: Any]) {
        super.init(networkId: .SVV, apiBase: SvvProvider.API_BASE, productsMap: SvvProvider.PRODUCTS_MAP)
        self.apiAuthorization = apiAuthorization
        apiVersion = "1.52"
        apiClient = ["id": "VAO", "type": "WEB", "name": "webapp", "l": "vs_svv"]
        extVersion = "VAO.6"
        
        styles = [
            "SS1": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(149, 53, 64), foregroundColor: LineStyle.white),
            "SS11": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(149, 53, 64), foregroundColor: LineStyle.white),
            "SS2": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(15, 101, 160), foregroundColor: LineStyle.white),
            "SS3": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(77, 164, 84), foregroundColor: LineStyle.white),
            "SS4": LineStyle(shape: .rounded, backgroundColor: LineStyle.rgb(140, 97, 148), foregroundColor: LineStyle.white),
            
            "T1": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(199, 55, 52), foregroundColor: LineStyle.white),
            "T2": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(15, 101, 160), foregroundColor: LineStyle.white),
            "T3": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(129, 106, 64), foregroundColor: LineStyle.white),
            "T4": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(241, 200, 76), foregroundColor: LineStyle.black),
            "T5": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(82, 181, 220), foregroundColor: LineStyle.white),
            "T6": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(136, 184, 84), foregroundColor: LineStyle.white),
            "T7": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(11, 156, 148), foregroundColor: LineStyle.white),
            "T8": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(222, 144, 68), foregroundColor: LineStyle.white),
            "T9": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(97, 55, 115), foregroundColor: LineStyle.white),
            "T10": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(231, 178, 153), foregroundColor: LineStyle.black),
            "T12": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(179, 214, 206), foregroundColor: LineStyle.black),
            "T14": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(198, 217, 156), foregroundColor: LineStyle.black)
        ]
    }
    
    static let PLACES = ["Salzburg", "Wien"]
    
    override func split(stationName: String?) -> (String?, String?) {
        guard let stationName = stationName else { return super.split(stationName: nil) }
        for place in SvvProvider.PLACES {
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
