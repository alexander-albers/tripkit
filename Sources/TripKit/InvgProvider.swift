import Foundation

public class InvgProvider: AbstractHafasClientInterfaceProvider {
    
    static let API_BASE = "https://fpa.invg.de/bin/"
    static let PRODUCTS_MAP: [Product?] = [.bus, .highSpeedTrain, .regionalTrain, .regionalTrain, .suburbanTrain, .bus, .ferry, .subway, .tram, .onDemand]
    
    public init(apiAuthorization: [String: Any], requestVerification: AbstractHafasClientInterfaceProvider.RequestVerification) {
        super.init(networkId: .INVG, apiBase: InvgProvider.API_BASE, productsMap: InvgProvider.PRODUCTS_MAP)
        self.apiAuthorization = apiAuthorization
        self.requestVerification = requestVerification
        apiVersion = "1.16"
        apiClient = ["id": "INVG"]
        
        styles = [
            "B10": LineStyle(backgroundColor: LineStyle.parseColor("#DA2510"), foregroundColor: LineStyle.white),
            "B11": LineStyle(backgroundColor: LineStyle.parseColor("#EE9B78"), foregroundColor: LineStyle.black),
            "B15": LineStyle(backgroundColor: LineStyle.parseColor("#84C326"), foregroundColor: LineStyle.black),
            "B16": LineStyle(backgroundColor: LineStyle.parseColor("#5D452E"), foregroundColor: LineStyle.white),
            "B17": LineStyle(backgroundColor: LineStyle.parseColor("#E81100"), foregroundColor: LineStyle.black),
            "B18": LineStyle(backgroundColor: LineStyle.parseColor("#79316C"), foregroundColor: LineStyle.white),
            "B20": LineStyle(backgroundColor: LineStyle.parseColor("#EA891C"), foregroundColor: LineStyle.black),
            "B21": LineStyle(backgroundColor: LineStyle.parseColor("#31B2EA"), foregroundColor: LineStyle.black),
            "B25": LineStyle(backgroundColor: LineStyle.parseColor("#7F65A0"), foregroundColor: LineStyle.white),
            "B26": LineStyle(backgroundColor: LineStyle.parseColor("#00BF73"), foregroundColor: LineStyle.white),
            "B30": LineStyle(backgroundColor: LineStyle.parseColor("#901E78"), foregroundColor: LineStyle.white),
            "B31": LineStyle(backgroundColor: LineStyle.parseColor("#DCE722"), foregroundColor: LineStyle.black),
            "B40": LineStyle(backgroundColor: LineStyle.parseColor("#009240"), foregroundColor: LineStyle.white),
            "B41": LineStyle(backgroundColor: LineStyle.parseColor("#7BC5B1"), foregroundColor: LineStyle.black),
            "B44": LineStyle(backgroundColor: LineStyle.parseColor("#EA77A6"), foregroundColor: LineStyle.white),
            "B50": LineStyle(backgroundColor: LineStyle.parseColor("#FACF00"), foregroundColor: LineStyle.black),
            "B51": LineStyle(backgroundColor: LineStyle.parseColor("#C13C00"), foregroundColor: LineStyle.white),
            "B52": LineStyle(backgroundColor: LineStyle.parseColor("#94F0D4"), foregroundColor: LineStyle.black),
            "B53": LineStyle(backgroundColor: LineStyle.parseColor("#BEB405"), foregroundColor: LineStyle.black),
            "B55": LineStyle(backgroundColor: LineStyle.parseColor("#FFF500"), foregroundColor: LineStyle.black),
            "B58": LineStyle(backgroundColor: LineStyle.rgb(209, 191, 201), foregroundColor: LineStyle.black),
            "B60": LineStyle(backgroundColor: LineStyle.parseColor("#0072B7"), foregroundColor: LineStyle.white),
            "B61": LineStyle(backgroundColor: LineStyle.rgb(204, 184, 122), foregroundColor: LineStyle.black), //
            "B62": LineStyle(backgroundColor: LineStyle.rgb(204, 184, 122), foregroundColor: LineStyle.black), //
            "B65": LineStyle(backgroundColor: LineStyle.parseColor("#B7DDD2"), foregroundColor: LineStyle.black),
            "B70": LineStyle(backgroundColor: LineStyle.parseColor("#D49016"), foregroundColor: LineStyle.black),
            "B71": LineStyle(backgroundColor: LineStyle.parseColor("#996600"), foregroundColor: LineStyle.black),
            "B85": LineStyle(backgroundColor: LineStyle.parseColor("#F6BAD3"), foregroundColor: LineStyle.black),
            "B111": LineStyle(backgroundColor: LineStyle.parseColor("#EE9B78"), foregroundColor: LineStyle.black),
            
            "B9221": LineStyle(backgroundColor: LineStyle.rgb(217, 217, 255), foregroundColor: LineStyle.black),
            "B9226": LineStyle(backgroundColor: LineStyle.rgb(191, 255, 255), foregroundColor: LineStyle.black),
            
            "BN1": LineStyle(backgroundColor: LineStyle.parseColor("#00116C"), foregroundColor: LineStyle.white),
            "BN2": LineStyle(backgroundColor: LineStyle.parseColor("#00116C"), foregroundColor: LineStyle.white),
            "BN3": LineStyle(backgroundColor: LineStyle.parseColor("#00116C"), foregroundColor: LineStyle.white),
            "BN4": LineStyle(backgroundColor: LineStyle.parseColor("#00116C"), foregroundColor: LineStyle.white),
            "BN5": LineStyle(backgroundColor: LineStyle.parseColor("#00116C"), foregroundColor: LineStyle.white),
            "BN6": LineStyle(backgroundColor: LineStyle.parseColor("#00116C"), foregroundColor: LineStyle.white),
            "BN7": LineStyle(backgroundColor: LineStyle.parseColor("#00116C"), foregroundColor: LineStyle.white),
            "BN8": LineStyle(backgroundColor: LineStyle.parseColor("#00116C"), foregroundColor: LineStyle.white),
            "BN9": LineStyle(backgroundColor: LineStyle.parseColor("#00116C"), foregroundColor: LineStyle.white),
            "BN10": LineStyle(backgroundColor: LineStyle.parseColor("#00116C"), foregroundColor: LineStyle.white),
            "BN11": LineStyle(backgroundColor: LineStyle.parseColor("#00116C"), foregroundColor: LineStyle.white),
            "BN12": LineStyle(backgroundColor: LineStyle.parseColor("#00116C"), foregroundColor: LineStyle.white),
            "BN13": LineStyle(backgroundColor: LineStyle.parseColor("#00116C"), foregroundColor: LineStyle.white),
            "BN14": LineStyle(backgroundColor: LineStyle.parseColor("#00116C"), foregroundColor: LineStyle.white),
            "BN15": LineStyle(backgroundColor: LineStyle.parseColor("#00116C"), foregroundColor: LineStyle.white),
            "BN16": LineStyle(backgroundColor: LineStyle.parseColor("#00116C"), foregroundColor: LineStyle.white),
            "BN17": LineStyle(backgroundColor: LineStyle.parseColor("#00116C"), foregroundColor: LineStyle.white),
            "BN18": LineStyle(backgroundColor: LineStyle.parseColor("#00116C"), foregroundColor: LineStyle.white),
            "BN19": LineStyle(backgroundColor: LineStyle.parseColor("#00116C"), foregroundColor: LineStyle.white),
            
            "BS1": LineStyle(backgroundColor: LineStyle.rgb(178, 25, 0), foregroundColor: LineStyle.white),
            "BS2": LineStyle(backgroundColor: LineStyle.rgb(178, 25, 0), foregroundColor: LineStyle.white),
            "BS3": LineStyle(backgroundColor: LineStyle.rgb(178, 25, 0), foregroundColor: LineStyle.white),
            "BS4": LineStyle(backgroundColor: LineStyle.rgb(178, 25, 0), foregroundColor: LineStyle.white),
            "BS5": LineStyle(backgroundColor: LineStyle.rgb(178, 25, 0), foregroundColor: LineStyle.white),
            "BS6": LineStyle(backgroundColor: LineStyle.rgb(178, 25, 0), foregroundColor: LineStyle.white),
            "BS7": LineStyle(backgroundColor: LineStyle.rgb(178, 25, 0), foregroundColor: LineStyle.white),
            "BS8": LineStyle(backgroundColor: LineStyle.rgb(178, 25, 0), foregroundColor: LineStyle.white),
            "BS9": LineStyle(backgroundColor: LineStyle.rgb(178, 25, 0), foregroundColor: LineStyle.white),
            
            "BX11": LineStyle(backgroundColor: LineStyle.parseColor("#EE9B78"), foregroundColor: LineStyle.black),
            "BX12": LineStyle(backgroundColor: LineStyle.parseColor("#B11839"), foregroundColor: LineStyle.black),
            "BX80": LineStyle(backgroundColor: LineStyle.parseColor("#FFFF40"), foregroundColor: LineStyle.black),
            "BX109": LineStyle(backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.black)
        ]
    }
    
    static let PLACES = ["Ingolstadt", "München"]
    
    override func split(stationName: String?) -> (String?, String?) {
        guard let stationName = stationName else { return super.split(stationName: nil) }
        for place in ShProvider.PLACES {
            if stationName.hasPrefix(place + " ") || stationName.hasPrefix(place + "-") {
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
