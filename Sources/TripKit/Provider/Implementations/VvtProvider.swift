import Foundation

/// Verkehrsverbund Tirol (AT)
public class VvtProvider: AbstractHafasClientInterfaceProvider {
    
    static let API_BASE = "https://smartride.vvt.at/bin/"
    static let PRODUCTS_MAP: [Product?] = [.highSpeedTrain, .suburbanTrain, .subway, nil, .tram, .regionalTrain, .bus, .bus, .tram, .ferry, .onDemand, .bus, .regionalTrain, nil, nil, nil]
    
    public override var supportedLanguages: Set<String> { ["de", "en"] }
    
    public init(apiAuthorization: [String: Any]) {
        super.init(networkId: .VVT, apiBase: VvtProvider.API_BASE, productsMap: VvtProvider.PRODUCTS_MAP)
        self.apiAuthorization = apiAuthorization
        apiVersion = "1.52"
        apiClient = ["id": "VAO", "type": "WEB", "name": "webapp", "l": "vs_vvt"]
        extVersion = "VAO.6"
        
        styles = [
            "Innsbrucker Verkehrsbetriebe und Stubaitalbahn GmbH|T1": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#d99796"), foregroundColor: LineStyle.white),
            "Innsbrucker Verkehrsbetriebe und Stubaitalbahn GmbH|T2": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#b84259"), foregroundColor: LineStyle.white),
            "Innsbrucker Verkehrsbetriebe und Stubaitalbahn GmbH|T3": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#bc636a"), foregroundColor: LineStyle.white),
            "Innsbrucker Verkehrsbetriebe und Stubaitalbahn GmbH|T5": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#794251"), foregroundColor: LineStyle.white),
            "Innsbrucker Verkehrsbetriebe und Stubaitalbahn GmbH|T6": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#881830"), foregroundColor: LineStyle.white),
            "Innsbrucker Verkehrsbetriebe und Stubaitalbahn GmbH|TSTB": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#500a1a"), foregroundColor: LineStyle.white),
            "Innsbrucker Verkehrsbetriebe und Stubaitalbahn GmbH|BA": LineStyle(backgroundColor: LineStyle.parseColor("#006691"), foregroundColor: LineStyle.white),
            "Innsbrucker Verkehrsbetriebe und Stubaitalbahn GmbH|BB": LineStyle(backgroundColor: LineStyle.parseColor("#9c9a28"), foregroundColor: LineStyle.white),
            "Innsbrucker Verkehrsbetriebe und Stubaitalbahn GmbH|BC": LineStyle(backgroundColor: LineStyle.parseColor("#60c4e5"), foregroundColor: LineStyle.white),
            "Innsbrucker Verkehrsbetriebe und Stubaitalbahn GmbH|BF": LineStyle(backgroundColor: LineStyle.parseColor("#70297a"), foregroundColor: LineStyle.white),
            "Innsbrucker Verkehrsbetriebe und Stubaitalbahn GmbH|BH": LineStyle(backgroundColor: LineStyle.parseColor("#6d9a90"), foregroundColor: LineStyle.white),
            "Innsbrucker Verkehrsbetriebe und Stubaitalbahn GmbH|BJ": LineStyle(backgroundColor: LineStyle.parseColor("#95548c"), foregroundColor: LineStyle.white),
            "Innsbrucker Verkehrsbetriebe und Stubaitalbahn GmbH|BK": LineStyle(backgroundColor: LineStyle.parseColor("#bb9ebc"), foregroundColor: LineStyle.white),
            "Innsbrucker Verkehrsbetriebe und Stubaitalbahn GmbH|BM": LineStyle(backgroundColor: LineStyle.parseColor("#cd7f4c"), foregroundColor: LineStyle.white),
            "Innsbrucker Verkehrsbetriebe und Stubaitalbahn GmbH|BR": LineStyle(backgroundColor: LineStyle.parseColor("#e3672a"), foregroundColor: LineStyle.white),
            "Innsbrucker Verkehrsbetriebe und Stubaitalbahn GmbH|BT": LineStyle(backgroundColor: LineStyle.parseColor("#6db743"), foregroundColor: LineStyle.white),
            "Innsbrucker Verkehrsbetriebe und Stubaitalbahn GmbH|BW": LineStyle(backgroundColor: LineStyle.parseColor("#009949"), foregroundColor: LineStyle.white),
            "Innbus Regionalverkehr GmbH|B": LineStyle(backgroundColor: LineStyle.parseColor("#fff005"), foregroundColor: LineStyle.black),
            "Innsbrucker Verkehrsbetriebe und Stubaitalbahn GmbH|CHBB": LineStyle(backgroundColor: LineStyle.parseColor("#e780a9"), foregroundColor: LineStyle.white),
            
            "SS1": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#81a433"), foregroundColor: LineStyle.white),
            "SS2": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#e6778e"), foregroundColor: LineStyle.white),
            "SS3": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#abb0bb"), foregroundColor: LineStyle.black),
            "SS4": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#45214d"), foregroundColor: LineStyle.white),
            "SS5": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#4d9266"), foregroundColor: LineStyle.white),
            "SS6": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#9c1d23"), foregroundColor: LineStyle.white),
            "SS7": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#c4a3ae"), foregroundColor: LineStyle.black),
        ]
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
    
    override func newLine(id: String?, network: String?, product: Product?, name: String?, shortName: String?, number: String?, vehicleNumber: String?) -> Line {
        if product == .tram && name == "HBB" {
            return Line(id: id, network: network, product: .cablecar, label: name, name: "Hungerburgbahn", number: number, vehicleNumber: vehicleNumber, style: lineStyle(network: network, product: .cablecar, label: name), attr: [], message: nil)
        } else {
            return super.newLine(id: id, network: network, product: product, name: name, shortName: shortName, number: number, vehicleNumber: vehicleNumber)
        }
    }
    
}

