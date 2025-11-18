import Foundation

/// Wiener Linien (AT)
public class WienProvider: AbstractEfaWebProvider {
    
    static let API_BASE = "https://www.wienerlinien.at/ogd_routing/"
    
    public override var supportedLanguages: Set<String> { ["de", "en"] }
    
    public init() {
        super.init(networkId: .WIEN, apiBase: WienProvider.API_BASE)
        includeRegionId = false
        
        styles = [
            // Wien
            "S": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#009fe3"), foregroundColor: LineStyle.white),
            "B": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#0a2a5d"), foregroundColor: LineStyle.white),
            "BN": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#0a2a5d"), foregroundColor: LineStyle.yellow),

            "UU1": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#d8222a"), foregroundColor: LineStyle.white),
            "UU2": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#935e98"), foregroundColor: LineStyle.white),
            "UU3": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#e67a2b"), foregroundColor: LineStyle.white),
            "UU4": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#009460"), foregroundColor: LineStyle.white),
            "UU6": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#8c633c"), foregroundColor: LineStyle.white),
        ]
    }
    
    override func queryTripsParameters(builder: UrlBuilder, from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions) {
        super.queryTripsParameters(builder: builder, from: from, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions)
        if let products = tripOptions.products, products.contains(.bus) {
            builder.addParameter(key: "inclMOT_11", value: "on") // night bus
        }
    }
    
    override func split(directionName: String?) -> (name: String?, place: String?) {
        guard let directionName = directionName else { return (nil, nil) }
        if directionName.hasPrefix("Wien ") {
            return (directionName.substring(from: "Wien ".count), "Wien")
        }
        return super.split(directionName: directionName)
    }
    
}
