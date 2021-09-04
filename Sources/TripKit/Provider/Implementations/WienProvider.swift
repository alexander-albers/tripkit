import Foundation

public class WienProvider: AbstractEfaProvider {
    
    static let API_BASE = "https://www.wienerlinien.at/ogd_routing/"
    
    public init() {
        super.init(networkId: .WIEN, apiBase: WienProvider.API_BASE)
        includeRegionId = false
        
        styles = [
            // Wien
            "SS1": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#1e5cb3"), foregroundColor: LineStyle.white),
            "SS2": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#59c594"), foregroundColor: LineStyle.white),
            "SS3": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#c8154c"), foregroundColor: LineStyle.white),
            "SS7": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#dc35a3"), foregroundColor: LineStyle.white),
            "SS40": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#f24d3e"), foregroundColor: LineStyle.white),
            "SS45": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#0f8572"), foregroundColor: LineStyle.white),
            "SS50": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#34b6e5"), foregroundColor: LineStyle.white),
            "SS60": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#82b429"), foregroundColor: LineStyle.white),
            "SS80": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#e96619"), foregroundColor: LineStyle.white),
            
            "UU1": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#c6292a"), foregroundColor: LineStyle.white),
            "UU2": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#a82783"), foregroundColor: LineStyle.white),
            "UU3": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#f39315"), foregroundColor: LineStyle.white),
            "UU4": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#23a740"), foregroundColor: LineStyle.white),
            "UU6": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#be762c"), foregroundColor: LineStyle.white)
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
