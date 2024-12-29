import Foundation

/// Kölner Verkehrs-Betriebe (DE)
public class KvbProvider: AbstractHafasClientInterfaceProvider {
    
    static let API_BASE = "https://auskunft.kvb.koeln/gate"
    
    static let PRODUCTS_MAP: [Product?] = [.suburbanTrain, .tram, nil, .bus, .regionalTrain, .highSpeedTrain, nil, nil, nil, nil]
    
    public override var supportedLanguages: Set<String> { ["de", "en"] }
    
    public init(apiAuthorization: [String: Any]) {
        super.init(networkId: .KVB, apiBase: KvbProvider.API_BASE, productsMap: KvbProvider.PRODUCTS_MAP)
        self.mgateEndpoint = KvbProvider.API_BASE
        self.apiAuthorization = apiAuthorization
        apiVersion = "1.58"
        apiClient = ["id": "HAFAS", "type": "WEB", "name": "webapp", "l": "vs_webapp", "v": "154"]
        
        styles = [
            // Stadtbahn Köln-Bonn
            "T1": LineStyle(backgroundColor: LineStyle.parseColor("#ed1c24"), foregroundColor: LineStyle.white),
            "T3": LineStyle(backgroundColor: LineStyle.parseColor("#f680c5"), foregroundColor: LineStyle.white),
            "T4": LineStyle(backgroundColor: LineStyle.parseColor("#f24dae"), foregroundColor: LineStyle.white),
            "T5": LineStyle(backgroundColor: LineStyle.parseColor("#9c8dce"), foregroundColor: LineStyle.white),
            "T7": LineStyle(backgroundColor: LineStyle.parseColor("#f57947"), foregroundColor: LineStyle.white),
            "T9": LineStyle(backgroundColor: LineStyle.parseColor("#f5777b"), foregroundColor: LineStyle.white),
            "T12": LineStyle(backgroundColor: LineStyle.parseColor("#80cc28"), foregroundColor: LineStyle.white),
            "T13": LineStyle(backgroundColor: LineStyle.parseColor("#9e7b65"), foregroundColor: LineStyle.white),
            "T15": LineStyle(backgroundColor: LineStyle.parseColor("#4dbd38"), foregroundColor: LineStyle.white),
            "T16": LineStyle(backgroundColor: LineStyle.parseColor("#33baab"), foregroundColor: LineStyle.white),
            "T18": LineStyle(backgroundColor: LineStyle.parseColor("#05a1e6"), foregroundColor: LineStyle.white),
            "T61": LineStyle(backgroundColor: LineStyle.parseColor("#80cc28"), foregroundColor: LineStyle.white),
            "T62": LineStyle(backgroundColor: LineStyle.parseColor("#4dbd38"), foregroundColor: LineStyle.white),
            "T63": LineStyle(backgroundColor: LineStyle.parseColor("#73d2f6"), foregroundColor: LineStyle.white),
            "T65": LineStyle(backgroundColor: LineStyle.parseColor("#b3db18"), foregroundColor: LineStyle.white),
            "T66": LineStyle(backgroundColor: LineStyle.parseColor("#ec008c"), foregroundColor: LineStyle.white),
            "T67": LineStyle(backgroundColor: LineStyle.parseColor("#f680c5"), foregroundColor: LineStyle.white),
            "T68": LineStyle(backgroundColor: LineStyle.parseColor("#ca93d0"), foregroundColor: LineStyle.white),
            
            // Busse Köln
            "BSB40": LineStyle(backgroundColor: LineStyle.parseColor("#FF0000"), foregroundColor: LineStyle.white),
            "B106": LineStyle(backgroundColor: LineStyle.parseColor("#0994dd"), foregroundColor: LineStyle.white),
            "B120": LineStyle(backgroundColor: LineStyle.parseColor("#24C6E8"), foregroundColor: LineStyle.white),
            "B121": LineStyle(backgroundColor: LineStyle.parseColor("#89E82D"), foregroundColor: LineStyle.white),
            "B122": LineStyle(backgroundColor: LineStyle.parseColor("#4D44FF"), foregroundColor: LineStyle.white),
            "B125": LineStyle(backgroundColor: LineStyle.parseColor("#FF9A2E"), foregroundColor: LineStyle.white),
            "B126": LineStyle(backgroundColor: LineStyle.parseColor("#FF8EE5"), foregroundColor: LineStyle.white),
            "B127": LineStyle(backgroundColor: LineStyle.parseColor("#D164A4"), foregroundColor: LineStyle.white),
            "B130": LineStyle(backgroundColor: LineStyle.parseColor("#5AC0E8"), foregroundColor: LineStyle.white),
            "B131": LineStyle(backgroundColor: LineStyle.parseColor("#8cd024"), foregroundColor: LineStyle.white),
            "B132": LineStyle(backgroundColor: LineStyle.parseColor("#E8840C"), foregroundColor: LineStyle.white),
            "B133": LineStyle(backgroundColor: LineStyle.parseColor("#FF9EEE"), foregroundColor: LineStyle.white),
            "B135": LineStyle(backgroundColor: LineStyle.parseColor("#f24caf"), foregroundColor: LineStyle.white),
            "B136": LineStyle(backgroundColor: LineStyle.parseColor("#C96C44"), foregroundColor: LineStyle.white),
            "B138": LineStyle(backgroundColor: LineStyle.parseColor("#ef269d"), foregroundColor: LineStyle.white),
            "B139": LineStyle(backgroundColor: LineStyle.parseColor("#D13D1E"), foregroundColor: LineStyle.white),
            "B140": LineStyle(backgroundColor: LineStyle.parseColor("#FFD239"), foregroundColor: LineStyle.white),
            "B141": LineStyle(backgroundColor: LineStyle.parseColor("#2CE8D0"), foregroundColor: LineStyle.white),
            "B142": LineStyle(backgroundColor: LineStyle.parseColor("#9E54FF"), foregroundColor: LineStyle.white),
            "B143": LineStyle(backgroundColor: LineStyle.parseColor("#82E827"), foregroundColor: LineStyle.white),
            "B144": LineStyle(backgroundColor: LineStyle.parseColor("#FF8930"), foregroundColor: LineStyle.white),
            "B145": LineStyle(backgroundColor: LineStyle.parseColor("#24C6E8"), foregroundColor: LineStyle.white),
            "B146": LineStyle(backgroundColor: LineStyle.parseColor("#F25006"), foregroundColor: LineStyle.white),
            "B147": LineStyle(backgroundColor: LineStyle.parseColor("#FF8EE5"), foregroundColor: LineStyle.white),
            "B149": LineStyle(backgroundColor: LineStyle.parseColor("#176fc1"), foregroundColor: LineStyle.white),
            "B150": LineStyle(backgroundColor: LineStyle.parseColor("#f68712"), foregroundColor: LineStyle.white),
            "B151": LineStyle(backgroundColor: LineStyle.parseColor("#ECB43A"), foregroundColor: LineStyle.white),
            "B152": LineStyle(backgroundColor: LineStyle.parseColor("#FFDE44"), foregroundColor: LineStyle.white),
            "B153": LineStyle(backgroundColor: LineStyle.parseColor("#C069FF"), foregroundColor: LineStyle.white),
            "B154": LineStyle(backgroundColor: LineStyle.parseColor("#E85D25"), foregroundColor: LineStyle.white),
            "B155": LineStyle(backgroundColor: LineStyle.parseColor("#0994dd"), foregroundColor: LineStyle.white),
            "B156": LineStyle(backgroundColor: LineStyle.parseColor("#4B69EC"), foregroundColor: LineStyle.white),
            "B157": LineStyle(backgroundColor: LineStyle.parseColor("#5CC3F9"), foregroundColor: LineStyle.white),
            "B158": LineStyle(backgroundColor: LineStyle.parseColor("#66c530"), foregroundColor: LineStyle.white),
            "B159": LineStyle(backgroundColor: LineStyle.parseColor("#FF00CC"), foregroundColor: LineStyle.white),
            "B160": LineStyle(backgroundColor: LineStyle.parseColor("#66c530"), foregroundColor: LineStyle.white),
            "B161": LineStyle(backgroundColor: LineStyle.parseColor("#33bef3"), foregroundColor: LineStyle.white),
            "B162": LineStyle(backgroundColor: LineStyle.parseColor("#f033a3"), foregroundColor: LineStyle.white),
            "B163": LineStyle(backgroundColor: LineStyle.parseColor("#00adef"), foregroundColor: LineStyle.white),
            "B163/550": LineStyle(backgroundColor: LineStyle.parseColor("#00adef"), foregroundColor: LineStyle.white),
            "B164": LineStyle(backgroundColor: LineStyle.parseColor("#885bb4"), foregroundColor: LineStyle.white),
            "B164/501": LineStyle(backgroundColor: LineStyle.parseColor("#885bb4"), foregroundColor: LineStyle.white),
            "B165": LineStyle(backgroundColor: LineStyle.parseColor("#7b7979"), foregroundColor: LineStyle.white),
            "B166": LineStyle(backgroundColor: LineStyle.parseColor("#7b7979"), foregroundColor: LineStyle.white),
            "B167": LineStyle(backgroundColor: LineStyle.parseColor("#7b7979"), foregroundColor: LineStyle.white),
            "B180": LineStyle(backgroundColor: LineStyle.parseColor("#918f90"), foregroundColor: LineStyle.white),
            "B181": LineStyle(backgroundColor: LineStyle.parseColor("#918f90"), foregroundColor: LineStyle.white),
            "B182": LineStyle(backgroundColor: LineStyle.parseColor("#918f90"), foregroundColor: LineStyle.white),
            "B183": LineStyle(backgroundColor: LineStyle.parseColor("#918f90"), foregroundColor: LineStyle.white),
            "B184": LineStyle(backgroundColor: LineStyle.parseColor("#918f90"), foregroundColor: LineStyle.white),
            "B185": LineStyle(backgroundColor: LineStyle.parseColor("#D3D2D2"), foregroundColor: LineStyle.white),
            "B186": LineStyle(backgroundColor: LineStyle.parseColor("#D3D2D2"), foregroundColor: LineStyle.white),
            "B187": LineStyle(backgroundColor: LineStyle.parseColor("#D3D2D2"), foregroundColor: LineStyle.white),
            "B188": LineStyle(backgroundColor: LineStyle.parseColor("#918f90"), foregroundColor: LineStyle.white),
            "B190": LineStyle(backgroundColor: LineStyle.parseColor("#4D44FF"), foregroundColor: LineStyle.white),
            "B191": LineStyle(backgroundColor: LineStyle.parseColor("#00a998"), foregroundColor: LineStyle.white),
            
            // Busse Bonn
            "B16": LineStyle(backgroundColor: LineStyle.parseColor("#33baab"), foregroundColor: LineStyle.white),
            "B18": LineStyle(backgroundColor: LineStyle.parseColor("#05a1e6"), foregroundColor: LineStyle.white),
            "B61": LineStyle(backgroundColor: LineStyle.parseColor("#80cc28"), foregroundColor: LineStyle.white),
            "B62": LineStyle(backgroundColor: LineStyle.parseColor("#4dbd38"), foregroundColor: LineStyle.white),
            "B63": LineStyle(backgroundColor: LineStyle.parseColor("#73d2f6"), foregroundColor: LineStyle.white),
            "B65": LineStyle(backgroundColor: LineStyle.parseColor("#b3db18"), foregroundColor: LineStyle.white),
            "B66": LineStyle(backgroundColor: LineStyle.parseColor("#ec008c"), foregroundColor: LineStyle.white),
            "B67": LineStyle(backgroundColor: LineStyle.parseColor("#f680c5"), foregroundColor: LineStyle.white),
            "B68": LineStyle(backgroundColor: LineStyle.parseColor("#ca93d0"), foregroundColor: LineStyle.white),
            "BSB55": LineStyle(backgroundColor: LineStyle.parseColor("#00919e"), foregroundColor: LineStyle.white),
            "BSB60": LineStyle(backgroundColor: LineStyle.parseColor("#8f9867"), foregroundColor: LineStyle.white),
            "BSB69": LineStyle(backgroundColor: LineStyle.parseColor("#db5f1f"), foregroundColor: LineStyle.white),
            "B529": LineStyle(backgroundColor: LineStyle.parseColor("#2e2383"), foregroundColor: LineStyle.white),
            "B537": LineStyle(backgroundColor: LineStyle.parseColor("#2e2383"), foregroundColor: LineStyle.white),
            "B541": LineStyle(backgroundColor: LineStyle.parseColor("#2e2383"), foregroundColor: LineStyle.white),
            "B551": LineStyle(backgroundColor: LineStyle.parseColor("#2e2383"), foregroundColor: LineStyle.white),
            "B600": LineStyle(backgroundColor: LineStyle.parseColor("#817db7"), foregroundColor: LineStyle.white),
            "B601": LineStyle(backgroundColor: LineStyle.parseColor("#831b82"), foregroundColor: LineStyle.white),
            "B602": LineStyle(backgroundColor: LineStyle.parseColor("#dd6ba6"), foregroundColor: LineStyle.white),
            "B603": LineStyle(backgroundColor: LineStyle.parseColor("#e6007d"), foregroundColor: LineStyle.white),
            "B604": LineStyle(backgroundColor: LineStyle.parseColor("#009f5d"), foregroundColor: LineStyle.white),
            "B605": LineStyle(backgroundColor: LineStyle.parseColor("#007b3b"), foregroundColor: LineStyle.white),
            "B606": LineStyle(backgroundColor: LineStyle.parseColor("#9cbf11"), foregroundColor: LineStyle.white),
            "B607": LineStyle(backgroundColor: LineStyle.parseColor("#60ad2a"), foregroundColor: LineStyle.white),
            "B608": LineStyle(backgroundColor: LineStyle.parseColor("#f8a600"), foregroundColor: LineStyle.white),
            "B609": LineStyle(backgroundColor: LineStyle.parseColor("#ef7100"), foregroundColor: LineStyle.white),
            "B610": LineStyle(backgroundColor: LineStyle.parseColor("#3ec1f1"), foregroundColor: LineStyle.white),
            "B611": LineStyle(backgroundColor: LineStyle.parseColor("#0099db"), foregroundColor: LineStyle.white),
            "B612": LineStyle(backgroundColor: LineStyle.parseColor("#ce9d53"), foregroundColor: LineStyle.white),
            "B613": LineStyle(backgroundColor: LineStyle.parseColor("#7b3600"), foregroundColor: LineStyle.white),
            "B614": LineStyle(backgroundColor: LineStyle.parseColor("#806839"), foregroundColor: LineStyle.white),
            "B615": LineStyle(backgroundColor: LineStyle.parseColor("#532700"), foregroundColor: LineStyle.white),
            "B630": LineStyle(backgroundColor: LineStyle.parseColor("#c41950"), foregroundColor: LineStyle.white),
            "B631": LineStyle(backgroundColor: LineStyle.parseColor("#9b1c44"), foregroundColor: LineStyle.white),
            "B633": LineStyle(backgroundColor: LineStyle.parseColor("#88cdc7"), foregroundColor: LineStyle.white),
            "B635": LineStyle(backgroundColor: LineStyle.parseColor("#cec800"), foregroundColor: LineStyle.white),
            "B636": LineStyle(backgroundColor: LineStyle.parseColor("#af0223"), foregroundColor: LineStyle.white),
            "B637": LineStyle(backgroundColor: LineStyle.parseColor("#e3572a"), foregroundColor: LineStyle.white),
            "B638": LineStyle(backgroundColor: LineStyle.parseColor("#af5836"), foregroundColor: LineStyle.white),
            "B640": LineStyle(backgroundColor: LineStyle.parseColor("#004f81"), foregroundColor: LineStyle.white),
            "BT650": LineStyle(backgroundColor: LineStyle.parseColor("#54baa2"), foregroundColor: LineStyle.white),
            "BT651": LineStyle(backgroundColor: LineStyle.parseColor("#005738"), foregroundColor: LineStyle.white),
            "BT680": LineStyle(backgroundColor: LineStyle.parseColor("#4e6578"), foregroundColor: LineStyle.white),
            "B800": LineStyle(backgroundColor: LineStyle.parseColor("#4e6578"), foregroundColor: LineStyle.white),
            "B812": LineStyle(backgroundColor: LineStyle.parseColor("#4e6578"), foregroundColor: LineStyle.white),
            "B843": LineStyle(backgroundColor: LineStyle.parseColor("#4e6578"), foregroundColor: LineStyle.white),
            "B845": LineStyle(backgroundColor: LineStyle.parseColor("#4e6578"), foregroundColor: LineStyle.white),
            "B852": LineStyle(backgroundColor: LineStyle.parseColor("#4e6578"), foregroundColor: LineStyle.white),
            "B855": LineStyle(backgroundColor: LineStyle.parseColor("#4e6578"), foregroundColor: LineStyle.white),
            "B856": LineStyle(backgroundColor: LineStyle.parseColor("#4e6578"), foregroundColor: LineStyle.white),
            "B857": LineStyle(backgroundColor: LineStyle.parseColor("#4e6578"), foregroundColor: LineStyle.white),
            
            // andere Busse
            "B250": LineStyle(backgroundColor: LineStyle.parseColor("#8FE84B"), foregroundColor: LineStyle.white),
            "B260": LineStyle(backgroundColor: LineStyle.parseColor("#FF8365"), foregroundColor: LineStyle.white),
            "B423": LineStyle(backgroundColor: LineStyle.parseColor("#D3D2D2"), foregroundColor: LineStyle.white),
            "B434": LineStyle(backgroundColor: LineStyle.parseColor("#14E80B"), foregroundColor: LineStyle.white),
            "B436": LineStyle(backgroundColor: LineStyle.parseColor("#BEEC49"), foregroundColor: LineStyle.white),
            "B481": LineStyle(backgroundColor: LineStyle.parseColor("#D3D2D2"), foregroundColor: LineStyle.white),
            "B504": LineStyle(backgroundColor: LineStyle.parseColor("#8cd024"), foregroundColor: LineStyle.white),
            "B505": LineStyle(backgroundColor: LineStyle.parseColor("#0994dd"), foregroundColor: LineStyle.white),
            "B885": LineStyle(backgroundColor: LineStyle.parseColor("#40bb6a"), foregroundColor: LineStyle.white),
            "B935": LineStyle(backgroundColor: LineStyle.parseColor("#bf7e71"), foregroundColor: LineStyle.white),
            "B961": LineStyle(backgroundColor: LineStyle.parseColor("#f140a9"), foregroundColor: LineStyle.white),
            "B962": LineStyle(backgroundColor: LineStyle.parseColor("#9c83c9"), foregroundColor: LineStyle.white),
            "B963": LineStyle(backgroundColor: LineStyle.parseColor("#f46c68"), foregroundColor: LineStyle.white),
            "B965": LineStyle(backgroundColor: LineStyle.parseColor("#FF0000"), foregroundColor: LineStyle.white),
            "B970": LineStyle(backgroundColor: LineStyle.parseColor("#f68712"), foregroundColor: LineStyle.white),
            "B980": LineStyle(backgroundColor: LineStyle.parseColor("#c38bcc"), foregroundColor: LineStyle.white),
            
            "BN": LineStyle(backgroundColor: LineStyle.parseColor("#000000"), foregroundColor: LineStyle.white),
            "BNE1": LineStyle(backgroundColor: LineStyle.parseColor("#993399"), foregroundColor: LineStyle.white), // default
            
            "S": LineStyle(backgroundColor: LineStyle.parseColor("#f18e00"), foregroundColor: LineStyle.white),
            "R": LineStyle(backgroundColor: LineStyle.parseColor("#009d81"), foregroundColor: LineStyle.white),
        ]
    }
    
    static let PLACES = ["Köln", "Bonn", "Leverkusen"]
        
    override func split(stationName: String?) -> (String?, String?) {
        guard let stationName = stationName else { return super.split(stationName: nil) }
        
        for place in KvbProvider.PLACES {
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
