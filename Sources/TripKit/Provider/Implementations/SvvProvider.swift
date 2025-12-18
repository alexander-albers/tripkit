import Foundation

/// Salzburger Verkehrsverbund (AT)
public class SvvProvider: AbstractHafasClientInterfaceProvider {
    
    static let API_BASE = "https://fahrplan.salzburg-verkehr.at/bin/"
    static let PRODUCTS_MAP: [Product?] = [.highSpeedTrain, .suburbanTrain, .subway, nil, .tram, .regionalTrain, .bus, .bus, .tram, .ferry, .onDemand, .bus, .regionalTrain, nil, nil, nil]
    
    public override var supportedLanguages: Set<String> { ["de", "en", "it"] }
    
    public init(apiAuthorization: [String: Any]) {
        super.init(networkId: .SVV, apiBase: SvvProvider.API_BASE, productsMap: SvvProvider.PRODUCTS_MAP)
        self.apiAuthorization = apiAuthorization
        apiVersion = "1.52"
        apiClient = ["id": "VAO", "type": "WEB", "name": "webapp", "l": "vs_svv"]
        extVersion = "VAO.6"
        
        styles = [
            "SS1": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#a01e39"), foregroundColor: LineStyle.white),
            "SS11": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#a01e39"), foregroundColor: LineStyle.white),
            "SS2": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#006aa0"), foregroundColor: LineStyle.white),
            "SS3": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#2ba246"), foregroundColor: LineStyle.white),
            "SS4": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#915e93"), foregroundColor: LineStyle.white),
            
            "B1": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#d82231"), foregroundColor: LineStyle.white),
            "B2": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#006aa0"), foregroundColor: LineStyle.white),
            "B3": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#7e5d2c"), foregroundColor: LineStyle.white),
            "B4": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#fac923"), foregroundColor: LineStyle.black),
            "B5": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#1bb8d9"), foregroundColor: LineStyle.white),
            "B6": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#7db93f"), foregroundColor: LineStyle.white),
            "B7": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#009a92"), foregroundColor: LineStyle.white),
            "B8": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#eb902d"), foregroundColor: LineStyle.white),
            "B9": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#69297a"), foregroundColor: LineStyle.white),
            "B10": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#f1b193"), foregroundColor: LineStyle.black),
            "B11": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#d5842b"), foregroundColor: LineStyle.white),
            "B12": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#aed8cd"), foregroundColor: LineStyle.black),
            "B14": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#c3db94"), foregroundColor: LineStyle.black),
            "B17": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#593713"), foregroundColor: LineStyle.white),
            "B21": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#378134"), foregroundColor: LineStyle.white),
            "B22": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#e680a9"), foregroundColor: LineStyle.white),
            "B23": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#e05329"), foregroundColor: LineStyle.white),
            "B24": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#00a8ab"), foregroundColor: LineStyle.white),
            "B25": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#67609b"), foregroundColor: LineStyle.white),
            "B27": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#005d79"), foregroundColor: LineStyle.white),
            "B28": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#2e5a23"), foregroundColor: LineStyle.white),
            "B31": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#db3e50"), foregroundColor: LineStyle.white),
            "B32": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#db3e50"), foregroundColor: LineStyle.white),
            "B34": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#599396"), foregroundColor: LineStyle.white),
            "B36": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#db3e50"), foregroundColor: LineStyle.white),
        ]
    }
    
    static let PLACES = ["Salzburg", "Wien", "Linz/Donau", "Innsbruck", "Graz", "Klagenfurt"]
    
    override func split(stationName: String?) -> (String?, String?) {
        guard let stationName = stationName else { return super.split(stationName: nil) }
        for place in SvvProvider.PLACES {
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
