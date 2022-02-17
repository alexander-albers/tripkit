import Foundation

/// Deutsche Bahn (DE)
public class DbProvider: AbstractHafasClientInterfaceProvider {
    
    static let API_BASE = "https://reiseauskunft.bahn.de/bin/"
    static let PRODUCTS_MAP: [Product?] = [
        .highSpeedTrain, // ICE-Züge
        .highSpeedTrain, // Intercity- und Eurocityzüge
        .highSpeedTrain, // Interregio- und Schnellzüge
        .regionalTrain, // Nahverkehr, sonstige Züge
        .suburbanTrain, // S-Bahn
        .bus, // Busse
        .ferry, // Schiffe
        .subway, // U-Bahnen
        .tram, // Straßenbahnen
        .onDemand, // Anruf-Sammeltaxi
        nil, nil, nil, nil]
    let format = DateFormatter()
    
    public override var supportedLanguages: Set<String> { ["de", "en", "fr", "es", "it", "nl", "da", "pl", "cs"] }
    
    public init(apiAuthorization: [String: Any], requestVerification: AbstractHafasClientInterfaceProvider.RequestVerification) {
        super.init(networkId: .DB, apiBase: DbProvider.API_BASE, productsMap: DbProvider.PRODUCTS_MAP)
        self.apiAuthorization = apiAuthorization
        self.requestVerification = requestVerification
        apiVersion = "1.46"
        apiClient = ["id": "DB", "type": "IPH", "name": "DB Navigator", "v": "20100000"]
        extVersion = "DB.R21.12.a"
        format.dateFormat = "yyyyMMddHHmm"
        configJson = ["rtMode": "HYBRID"]
    }
    
    let P_SPLIT_NAME_ONE_COMMA = try! NSRegularExpression(pattern: "([^,]*), ([^,]*)")
    
    override func split(stationName: String?) -> (String?, String?) {
        guard let name = stationName else { return (nil, nil) }
        if let match = P_SPLIT_NAME_ONE_COMMA.firstMatch(in: name, options: [], range: NSMakeRange(0, name.count)) {
            let substring1 = (name as NSString).substring(with: match.range(at: 1))
            let substring2 = (name as NSString).substring(with: match.range(at: 2))
            return (substring2, substring1)
        }
        return super.split(stationName: name)
    }
    
    override func split(poi: String?) -> (String?, String?) {
        guard let name = poi else { return (nil, nil) }
        if let match = P_SPLIT_NAME_ONE_COMMA.firstMatch(in: name, options: [], range: NSMakeRange(0, name.count)) {
            let substring1 = (name as NSString).substring(with: match.range(at: 1))
            let substring2 = (name as NSString).substring(with: match.range(at: 2))
            return (substring1, substring2)
        }
        return super.split(poi: name)
    }
    
    override func split(address: String?) -> (String?, String?) {
        guard let name = address else { return (nil, nil) }
        if let match = P_SPLIT_NAME_ONE_COMMA.firstMatch(in: name, options: [], range: NSMakeRange(0, name.count)) {
            let substring1 = (name as NSString).substring(with: match.range(at: 1))
            let substring2 = (name as NSString).substring(with: match.range(at: 2))
            return (substring1, substring2)
        }
        return super.split(address: name)
    }
    
    let P_NORMALIZE_LINE_NAME_TRAM = try! NSRegularExpression(pattern: "str\\s+(.*)", options: .caseInsensitive)
    
    override func getWagonSequenceUrl(number: String, plannedTime: Date) -> URL? {
        return URL(string: "https://fahrkarten.bahn.de/mobile/wr/wr.post?zugnummer=\(number)&zeitstempel=\(format.string(from: plannedTime))&lang=de")
    }
    
}
