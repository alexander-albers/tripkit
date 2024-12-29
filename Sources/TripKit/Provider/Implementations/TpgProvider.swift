import Foundation

/// Transports publics genevois (CH)
public class TpgProvider: AbstractHafasClientInterfaceProvider {
    
    static let API_BASE = "https://tpg.hafas.cloud/bin/"
    static let PRODUCTS_MAP: [Product?] = [.highSpeedTrain, .highSpeedTrain, .regionalTrain, .regionalTrain, .ferry, .suburbanTrain, .bus, .cablecar, .tram, .tram, nil, nil, nil, nil]
    
    public override var supportedLanguages: Set<String> { ["de", "en", "fr", "it"] }
    
    public init(apiAuthorization: [String: Any]) {
        super.init(networkId: .TPG, apiBase: TpgProvider.API_BASE, productsMap: TpgProvider.PRODUCTS_MAP)
        self.apiAuthorization = apiAuthorization
        apiVersion = "1.68"
        apiClient = ["id": "HAFAS", "type": "WEB", "name": "webapp", "l": "vs_webapp"]
        
        styles = [
            // Tram
            "T12": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#f5a300"), foregroundColor: LineStyle.black),
            "T14": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#5a1e82"), foregroundColor: LineStyle.white),
            "T15": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#84471c"), foregroundColor: LineStyle.white),
            "T17": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#06ace7"), foregroundColor: LineStyle.black),
            "T18": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#b72f89"), foregroundColor: LineStyle.white),
            
            // Bus
            "B1": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#5a1e82"), foregroundColor: LineStyle.white),
            "B2": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#d2db4a"), foregroundColor: LineStyle.black),
            "B3": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#b72f89"), foregroundColor: LineStyle.white),
            "B5": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#06ace7"), foregroundColor: LineStyle.white),
            "B6": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#008cbf"), foregroundColor: LineStyle.white),
            "B7": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#05a829"), foregroundColor: LineStyle.white),
            "B8": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#84471c"), foregroundColor: LineStyle.white),
            "B9": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#e2001d"), foregroundColor: LineStyle.white),
            "B10": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#006e3e"), foregroundColor: LineStyle.white),
            "B11": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#83409e"), foregroundColor: LineStyle.white),
            "B19": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#9f5a0a"), foregroundColor: LineStyle.white),
            "B20": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#05a829"), foregroundColor: LineStyle.white),
            "B21": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#79003c"), foregroundColor: LineStyle.white),
            "B22": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#5a1e82"), foregroundColor: LineStyle.white),
            "B23": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#b72f89"), foregroundColor: LineStyle.white),
            "B25": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#9f5a0a"), foregroundColor: LineStyle.white),
            "B28": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#83409e"), foregroundColor: LineStyle.white),
            "B31": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#06b0a4"), foregroundColor: LineStyle.white),
            "B32": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#8acbbe"), foregroundColor: LineStyle.black),
            "B33": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#06b0a4"), foregroundColor: LineStyle.white),
            "B34": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#8acbbe"), foregroundColor: LineStyle.black),
            "B37": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#006061"), foregroundColor: LineStyle.white),
            "B38": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#006061"), foregroundColor: LineStyle.white),
            "B39": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#06b0a4"), foregroundColor: LineStyle.white),
            "B40": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#8acbbe"), foregroundColor: LineStyle.black),
            "B41": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#06b0a4"), foregroundColor: LineStyle.white),
            "B42": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#06b0a4"), foregroundColor: LineStyle.white),
            "B43": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#8acbbe"), foregroundColor: LineStyle.black),
            "B44": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#06b0a4"), foregroundColor: LineStyle.white),
            "B45": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#8acbbe"), foregroundColor: LineStyle.black),
            "B46": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#06b0a4"), foregroundColor: LineStyle.white),
            "B47": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#06b0a4"), foregroundColor: LineStyle.white),
            "B48": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#8acbbe"), foregroundColor: LineStyle.black),
            "B50": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#06b0a4"), foregroundColor: LineStyle.white),
            "B51": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#06b0a4"), foregroundColor: LineStyle.white),
            "B52": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#8acbbe"), foregroundColor: LineStyle.black),
            "B53": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#8acbbe"), foregroundColor: LineStyle.black),
            "B54": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#8acbbe"), foregroundColor: LineStyle.black),
            "B55": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#006061"), foregroundColor: LineStyle.white),
            "B57": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#8acbbe"), foregroundColor: LineStyle.black),
            "B59": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#006061"), foregroundColor: LineStyle.white),
            "B60": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#ec619f"), foregroundColor: LineStyle.white),
            "B61": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#f5b5d2"), foregroundColor: LineStyle.black),
            "B64": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#ec619f"), foregroundColor: LineStyle.white),
            "B66": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#f5b5d2"), foregroundColor: LineStyle.black),
            "B67": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#f5b5d2"), foregroundColor: LineStyle.black),
            "B68": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#ec619f"), foregroundColor: LineStyle.white),
            "B69": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#f5b5d2"), foregroundColor: LineStyle.black),
            "B70": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#06b0a4"), foregroundColor: LineStyle.white),
            "B71": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#006061"), foregroundColor: LineStyle.white),
            "B72": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#8acbbe"), foregroundColor: LineStyle.black),
            "B73": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#006061"), foregroundColor: LineStyle.white),
            "B74": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#8acbbe"), foregroundColor: LineStyle.black),
            "B75": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#006061"), foregroundColor: LineStyle.white),
            "B78": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#006061"), foregroundColor: LineStyle.white),
            "B80": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#f5b5d2"), foregroundColor: LineStyle.black),
            "B82": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#ec619f"), foregroundColor: LineStyle.white),
            "B83": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#ec619f"), foregroundColor: LineStyle.white),
            "B91": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#006061"), foregroundColor: LineStyle.white),
            "B92": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#8acbbe"), foregroundColor: LineStyle.black),
            "BA": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#ff7e00"), foregroundColor: LineStyle.white),
            "BE": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#ff7e00"), foregroundColor: LineStyle.white),
            "BG": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#ff9baa"), foregroundColor: LineStyle.black),
            "BL": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#ff7e00"), foregroundColor: LineStyle.white),
            
            // Léman Express
            "RR L1": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#c3013b"), foregroundColor: LineStyle.white),
            "RR L2": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#0385ca"), foregroundColor: LineStyle.white),
            "RR L3": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#81b13e"), foregroundColor: LineStyle.white),
            "RR L4": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#e7af18"), foregroundColor: LineStyle.white),
            "RR L5": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#a4136d"), foregroundColor: LineStyle.white),
            "RR L6": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#019aaa"), foregroundColor: LineStyle.white),
            
            "RIC 1": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#e42d29"), foregroundColor: LineStyle.white),
            "RIC 5": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#f68710"), foregroundColor: LineStyle.white),
            "RIR 15": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#40be8e"), foregroundColor: LineStyle.white),
            "RIR 90": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#14779f"), foregroundColor: LineStyle.white),
        ]
    }
    
    static let PLACES = ["Genève"]
    
    override func split(stationName: String?) -> (String?, String?) {
        guard let stationName = stationName else { return super.split(stationName: nil) }
        
        for place in BlsProvider.PLACES {
            if stationName.hasPrefix(place + " ") || stationName.hasPrefix(place + ",") {
                return (place, stationName.substring(from: place.count + 1))
            }
        }
        
        if let m = stationName.match(pattern: P_SPLIT_NAME_FIRST_COMMA) {
            return (m[0], m[1])
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
