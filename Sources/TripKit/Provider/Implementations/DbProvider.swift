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
    public override var supportedQueryTraits: Set<QueryTrait> { Set(Array(super.supportedQueryTraits) + [.tariffTravelerType, .tariffReductions]) }
    /// See https://reiseauskunft.bahn.de/addons/fachkonfig-utf8.cfg
    public override var tariffReductionTypes: [TariffReduction] {
        [
            TariffReduction(title: "Keine Ermäßigung", tariffClass: nil, code: 0),
            TariffReduction(title: "BahnCard 25 1. Kl.", tariffClass: 1, code: 1),
            TariffReduction(title: "BahnCard 25 2. Kl.", tariffClass: 2, code: 2),
            TariffReduction(title: "BahnCard 50 1. Kl.", tariffClass: 1, code: 3),
            TariffReduction(title: "BahnCard 50 2. Kl.", tariffClass: 2, code: 4),
            TariffReduction(title: "BahnCard 100 1. Kl.", tariffClass: 1, code: 16),
            TariffReduction(title: "BahnCard 100 2. Kl.", tariffClass: 2, code: 17),
            TariffReduction(title: "SH-Card", tariffClass: nil, code: 14),
            TariffReduction(title: "AT - VORTEILScard", tariffClass: nil, code: 9),
            TariffReduction(title: "CH - General-Abonnement", tariffClass: nil, code: 15),
            TariffReduction(title: "CH - HalbtaxAbo", tariffClass: nil, code: 10),
            TariffReduction(title: "CH - HalbtaxAbo (ohne RAILPLUS)", tariffClass: nil, code: 11),
            TariffReduction(title: "NL - 40%", tariffClass: nil, code: 12),
            TariffReduction(title: "NL - 40% (ohne RAILPLUS)", tariffClass: nil, code: 13),
        ]
    }
    
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
