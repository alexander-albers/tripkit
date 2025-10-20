import Foundation

/// Nahverkehrsverbund Schleswig-Holstein (DE)
public class ShProvider: AbstractHafasClientInterfaceProvider {
    
    static let API_BASE = "https://nahsh.hafas.cloud/gate"
    static let PRODUCTS_MAP: [Product?] = [.highSpeedTrain, .highSpeedTrain, .highSpeedTrain, .regionalTrain, .suburbanTrain, .bus, .ferry, .subway, .tram, .onDemand]
    
    public override var supportedLanguages: Set<String> { ["de"] }
    
    public init(apiAuthorization: [String: Any]) {
        super.init(networkId: .SH, apiBase: ShProvider.API_BASE, productsMap: ShProvider.PRODUCTS_MAP)
        self.apiAuthorization = apiAuthorization
        self.mgateEndpoint = ShProvider.API_BASE
        apiVersion = "1.44"
        apiClient = ["id": "NAHSH", "type": "WEB", "name": "webapp"]
        
        styles = [
            "RRE6": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(3, 150, 81), foregroundColor: LineStyle.white),
            "RRB61": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(36, 67, 133), foregroundColor: LineStyle.black),
            "RRB62": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(59, 172, 186), foregroundColor: LineStyle.black),
            "RRB63": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(249, 219, 79), foregroundColor: LineStyle.black),
            "RRB64": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(179, 193, 216), foregroundColor: LineStyle.black),
            "RRB65": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(211, 219, 84), foregroundColor: LineStyle.black),
            "RRB66": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(102, 126, 54), foregroundColor: LineStyle.white),
            
            "RRE7": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(216, 127, 63), foregroundColor: LineStyle.black),
            "RRE70": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(161, 44, 60), foregroundColor: LineStyle.white),
            "RRB71": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(18, 134, 191), foregroundColor: LineStyle.white),
            "RRE72": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(163, 199, 125), foregroundColor: LineStyle.black),
            "RRB73": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(5, 139, 96), foregroundColor: LineStyle.white),
            "RRE74": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(15, 101, 160), foregroundColor: LineStyle.white),
            "RRB75": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(158, 105, 56), foregroundColor: LineStyle.white),
            "RRB76": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(249, 219, 79), foregroundColor: LineStyle.black),
            
            "RRE8": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(158, 208, 221), foregroundColor: LineStyle.black),
            "RRE80": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(182, 68, 130), foregroundColor: LineStyle.white),
            "RRB81": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(102, 126, 54), foregroundColor: LineStyle.white),
            "RRB82": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(138, 139, 138), foregroundColor: LineStyle.white),
            "RRE83": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(52, 81, 143), foregroundColor: LineStyle.white),
            "RRB84": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(204, 161, 188), foregroundColor: LineStyle.black),
            "RRB85": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(233, 181, 81), foregroundColor: LineStyle.black),
            "RRB86": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(199, 55, 52), foregroundColor: LineStyle.white),
            "RRE4": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(119, 49, 120), foregroundColor: LineStyle.white),
            "RRE1": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(249, 219, 79), foregroundColor: LineStyle.black),
            
            "RA1": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(203, 75, 54), foregroundColor: LineStyle.white),
            "RA2": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(77, 164, 84), foregroundColor: LineStyle.black),
            "RA3": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(16, 124, 181), foregroundColor: LineStyle.white),
            "SS1": LineStyle(shape: .circle, backgroundColor: LineStyle.rgb(144, 190, 85), foregroundColor: LineStyle.black),
            "SS21": LineStyle(shape: .circle, backgroundColor: LineStyle.rgb(158, 105, 56), foregroundColor: LineStyle.white),
            "SS3": LineStyle(shape: .circle, backgroundColor: LineStyle.rgb(157, 100, 150), foregroundColor: LineStyle.white)
        ]
        putStyle("1", LineStyle(backgroundColor: LineStyle.parseColor("#7288af"), foregroundColor: LineStyle.white))
        putStyle("2", LineStyle(backgroundColor: LineStyle.parseColor("#50bbb4"), foregroundColor: LineStyle.white))
        putStyle("5", LineStyle(backgroundColor: LineStyle.parseColor("#f39222"), foregroundColor: LineStyle.white))
        putStyle("6", LineStyle(backgroundColor: LineStyle.parseColor("#aec436"), foregroundColor: LineStyle.white))
        putStyle("8", LineStyle(backgroundColor: LineStyle.parseColor("#bcb261"), foregroundColor: LineStyle.white))
        putStyle("9", LineStyle(backgroundColor: LineStyle.parseColor("#c99c7d"), foregroundColor: LineStyle.white))
        putStyle("11", LineStyle(backgroundColor: LineStyle.parseColor("#f9b000"), foregroundColor: LineStyle.white))
        putStyle("22", LineStyle(backgroundColor: LineStyle.parseColor("#8ea48a"), foregroundColor: LineStyle.white))
        putStyle("31", LineStyle(backgroundColor: LineStyle.parseColor("#009ee3"), foregroundColor: LineStyle.white))
        putStyle("32", LineStyle(backgroundColor: LineStyle.parseColor("#009ee3"), foregroundColor: LineStyle.white))
        putStyle("33", LineStyle(backgroundColor: LineStyle.parseColor("#009ee3"), foregroundColor: LineStyle.white))
        putStyle("34", LineStyle(backgroundColor: LineStyle.parseColor("#009ee3"), foregroundColor: LineStyle.white))
        putStyle("41", LineStyle(backgroundColor: LineStyle.parseColor("#8ba5d6"), foregroundColor: LineStyle.white))
        putStyle("42", LineStyle(backgroundColor: LineStyle.parseColor("#8ba5d6"), foregroundColor: LineStyle.white))
        putStyle("50", LineStyle(backgroundColor: LineStyle.parseColor("#00a138"), foregroundColor: LineStyle.white))
        putStyle("51", LineStyle(backgroundColor: LineStyle.parseColor("#00a138"), foregroundColor: LineStyle.white))
        putStyle("52", LineStyle(backgroundColor: LineStyle.parseColor("#00a138"), foregroundColor: LineStyle.white))
        putStyle("60S", LineStyle(backgroundColor: LineStyle.parseColor("#92b4af"), foregroundColor: LineStyle.white))
        putStyle("60", LineStyle(backgroundColor: LineStyle.parseColor("#92b4af"), foregroundColor: LineStyle.white))
        putStyle("61", LineStyle(backgroundColor: LineStyle.parseColor("#9d1380"), foregroundColor: LineStyle.white))
        putStyle("62", LineStyle(backgroundColor: LineStyle.parseColor("#9d1380"), foregroundColor: LineStyle.white))
        putStyle("71", LineStyle(backgroundColor: LineStyle.parseColor("#777e6f"), foregroundColor: LineStyle.white))
        putStyle("72", LineStyle(backgroundColor: LineStyle.parseColor("#777e6f"), foregroundColor: LineStyle.white))
        putStyle("81", LineStyle(backgroundColor: LineStyle.parseColor("#00836e"), foregroundColor: LineStyle.white))
        putStyle("91", LineStyle(backgroundColor: LineStyle.parseColor("#947e62"), foregroundColor: LineStyle.white))
        putStyle("92", LineStyle(backgroundColor: LineStyle.parseColor("#947e62"), foregroundColor: LineStyle.white))
        putStyle("100", LineStyle(backgroundColor: LineStyle.parseColor("#d40a11"), foregroundColor: LineStyle.white))
        putStyle("101", LineStyle(backgroundColor: LineStyle.parseColor("#d40a11"), foregroundColor: LineStyle.white))
        putStyle("300", LineStyle(backgroundColor: LineStyle.parseColor("#cf94c2"), foregroundColor: LineStyle.white))
        putStyle("501", LineStyle(backgroundColor: LineStyle.parseColor("#0f3f93"), foregroundColor: LineStyle.white))
        putStyle("502", LineStyle(backgroundColor: LineStyle.parseColor("#0f3f93"), foregroundColor: LineStyle.white))
        putStyle("503", LineStyle(backgroundColor: LineStyle.parseColor("#0f3f93"), foregroundColor: LineStyle.white))
        putStyle("503S", LineStyle(backgroundColor: LineStyle.parseColor("#0f3f93"), foregroundColor: LineStyle.white))
        putStyle("512", LineStyle(backgroundColor: LineStyle.parseColor("#0f3f93"), foregroundColor: LineStyle.white))
        putStyle("512S", LineStyle(backgroundColor: LineStyle.parseColor("#0f3f93"), foregroundColor: LineStyle.white))
    }
    
    func putStyle(_ name: String, _ style: LineStyle) {
        styles["Autokraft Kiel GmbH|B" + name] = style
        styles["Kieler Verkehrsgesellschaft mbH|B" + name] = style
    }
    
    static let PLACES = ["Hamburg", "Kiel", "Lübeck", "Flensburg", "Neumünster"]
    
    override func split(stationName: String?) -> (String?, String?) {
        guard let stationName = stationName else { return super.split(stationName: nil) }
        for place in ShProvider.PLACES {
            if stationName.hasPrefix(place + " ") || stationName.hasPrefix(place + "-") {
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
