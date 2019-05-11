import Foundation

public class HvvProvider: AbstractHafasClientInterfaceProvider {
    
    static let API_BASE = "https://hvv-app.hafas.de/bin/"
    static let PRODUCTS_MAP: [Product?] = [.subway, .suburbanTrain, .suburbanTrain, .regionalTrain, .regionalTrain, .ferry, .highSpeedTrain, .bus, .bus, .highSpeedTrain, .onDemand]
    
    public init(apiAuthorization: [String: Any], requestVerification: AbstractHafasClientInterfaceProvider.RequestVerification) {
        super.init(networkId: .HVV, apiBase: HvvProvider.API_BASE, desktopQueryEndpoint: nil, desktopStboardEndpoint: nil, productsMap: HvvProvider.PRODUCTS_MAP)
        self.apiAuthorization = apiAuthorization
        self.requestVerification = requestVerification
        apiVersion = "1.16"
        apiClient = ["id": "HVV"]
        
        styles = [
            "UU1": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(0, 103, 165), foregroundColor: LineStyle.white),
            "UU2": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(216, 34, 42), foregroundColor: LineStyle.white),
            "UU3": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(245, 218, 48), foregroundColor: LineStyle.white),
            "UU4": LineStyle(shape: .rect, backgroundColor: LineStyle.rgb(58, 160, 155), foregroundColor: LineStyle.white),
            "SS1": LineStyle(backgroundColor: LineStyle.rgb(57, 167, 73), foregroundColor: LineStyle.white),
            "SS11": LineStyle(backgroundColor: LineStyle.white, foregroundColor: LineStyle.rgb(57, 167, 73), borderColor: LineStyle.rgb(57, 167, 73)),
            "SS2": LineStyle(backgroundColor: LineStyle.white, foregroundColor: LineStyle.rgb(162, 41, 73), borderColor: LineStyle.rgb(162, 41, 73)),
            "SS21": LineStyle(backgroundColor: LineStyle.rgb(162, 41, 73), foregroundColor: LineStyle.white),
            "SS3": LineStyle(backgroundColor: LineStyle.rgb(87, 43, 121), foregroundColor: LineStyle.white),
            "SS31": LineStyle(backgroundColor: LineStyle.white, foregroundColor: LineStyle.rgb(87, 43, 121), borderColor: LineStyle.rgb(87, 43, 121)),
            "SA1": LineStyle(backgroundColor: LineStyle.rgb(244, 134, 31), foregroundColor: LineStyle.white),
            "SA2": LineStyle(backgroundColor: LineStyle.rgb(244, 134, 31), foregroundColor: LineStyle.white),
            "SA3": LineStyle(backgroundColor: LineStyle.rgb(244, 134, 31), foregroundColor: LineStyle.white),
            "B600": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B601": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B602": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B603": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B604": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B605": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B606": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B607": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B608": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B609": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B611": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B613": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B616": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B617": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B618": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B619": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B621": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B623": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B626": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B627": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B629": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B638": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B639": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B640": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B641": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B642": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B643": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B644": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B648": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B649": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B658": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B688": LineStyle(backgroundColor: LineStyle.parseColor("#00004F"), foregroundColor: LineStyle.white),
            "B": LineStyle(backgroundColor: LineStyle.rgb(217, 34, 42), foregroundColor: LineStyle.white),
            "F": LineStyle(backgroundColor: LineStyle.rgb(0, 150, 185), foregroundColor: LineStyle.white)
        ]
    }
    
    override func parseJsonTripFare(fareSetName: String, fareSetDescription: String, name: String, currency: String, price: Float) -> Fare? {
        if name == "Single Ticket (Einzelkarte)" {
            return Fare(network: fareSetName, type: .adult, currency: currency, fare: price, unitsName: "Einzelkarte", units: nil)
        } else if name == "Single Ticket Child (Einzelkarte Kind)" {
            return Fare(network: fareSetName, type: .child, currency: currency, fare: price, unitsName: "Einzelkarte Kind", units: nil)
        } else {
            return super.parseJsonTripFare(fareSetName: fareSetName, fareSetDescription: fareSetDescription, name: name, currency: currency, price: price)
        }
    }
    
    override func split(stationName: String?) -> (String?, String?) {
        guard let stationName = stationName else { return super.split(stationName: nil) }
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
