import Foundation

/// Augsburger Verkehrs- und Tarifverbund (DE)
public class AvvAugsburgProvider: AbstractEfaWebProvider {
    
    static let API_BASE = "https://fahrtauskunft.avv-augsburg.de/efa/"
    static let DEPARTURE_MONITOR_ENDPOINT = "XML_DM_REQUEST"
    static let TRIP_ENDPOINT = "XML_TRIP_REQUEST2"
    
    public override var supportedLanguages: Set<String> { ["de", "en"] }
    
    public init() {
        super.init(networkId: .AVV, apiBase: AvvAugsburgProvider.API_BASE, departureMonitorEndpoint: AvvAugsburgProvider.DEPARTURE_MONITOR_ENDPOINT, tripEndpoint: AvvAugsburgProvider.TRIP_ENDPOINT)
        
        useRouteIndexAsTripId = false
        useStatelessTripContexts = true
        styles = [
            "B": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#abb1b1"), foregroundColor: LineStyle.black),
            "BB1": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#93117e"), foregroundColor: LineStyle.white),
            "BB3": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#ee7f00"), foregroundColor: LineStyle.white),
            "B21": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#00896b"), foregroundColor: LineStyle.white),
            "B22": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#eb6b59"), foregroundColor: LineStyle.white),
            "B23": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#97bf0d"), foregroundColor: LineStyle.parseColor("#d10019")),
            "B27": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#74b57e"), foregroundColor: LineStyle.white),
            "B29": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#5f689f"), foregroundColor: LineStyle.white),
            "B30": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#829ac3"), foregroundColor: LineStyle.white),
            "B31": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#a3cdb0"), foregroundColor: LineStyle.parseColor("#006835")),
            "B32": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#45a477"), foregroundColor: LineStyle.white),
            "B33": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#a0ca82"), foregroundColor: LineStyle.white),
            "B35": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#0085c5"), foregroundColor: LineStyle.white),
            "B36": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#b1c2e1"), foregroundColor: LineStyle.parseColor("#006ab3")),
            "B37": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#eac26b"), foregroundColor: LineStyle.black),
            "B38": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#c3655a"), foregroundColor: LineStyle.white),
            "B41": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#d26110"), foregroundColor: LineStyle.white),
            "B42": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#d57642"), foregroundColor: LineStyle.white),
            "B43": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#e29241"), foregroundColor: LineStyle.white),
            "B44": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#d0aacc"), foregroundColor: LineStyle.parseColor("#6d1f80")),
            "B45": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#a76da7"), foregroundColor: LineStyle.white),
            "B46": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#52bcc2"), foregroundColor: LineStyle.white),
            "B48": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#a6d7d2"), foregroundColor: LineStyle.parseColor("#079098")),
            "B51": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#ee7f00"), foregroundColor: LineStyle.white),
            "B52": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#ee7f00"), foregroundColor: LineStyle.white),
            "B54": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#ee7f00"), foregroundColor: LineStyle.white),
            "B56": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#a86853"), foregroundColor: LineStyle.white),
            "B57": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#a76da7"), foregroundColor: LineStyle.white),
            "B58": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#d0aacc"), foregroundColor: LineStyle.parseColor("#6d1f80")),
            "B59": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#b1c2e1"), foregroundColor: LineStyle.parseColor("#00519e")),
            "B70": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#a99990"), foregroundColor: LineStyle.white),
            "B71": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#a99990"), foregroundColor: LineStyle.white),
            "B72": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#a99990"), foregroundColor: LineStyle.white),
            "B76": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#c3655a"), foregroundColor: LineStyle.white),
            
            "T1": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#e30010"), foregroundColor: LineStyle.white),
            "T2": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#006ab3"), foregroundColor: LineStyle.white),
            "T3": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ef7c01"), foregroundColor: LineStyle.white),
            "T4": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#951781"), foregroundColor: LineStyle.white),
            "T6": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#94c11c"), foregroundColor: LineStyle.white),
            "T13": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#e2001a"), foregroundColor: LineStyle.white),
            "T64": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#97bf0d"), foregroundColor: LineStyle.white),
            
            "RR1": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#1bbbea"), foregroundColor: LineStyle.white),
            "RR2": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#003a80"), foregroundColor: LineStyle.white),
            "RR4": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#bd5619"), foregroundColor: LineStyle.white),
            "RR6": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#0098a1"), foregroundColor: LineStyle.white),
            "RR7": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#80191c"), foregroundColor: LineStyle.white),
            "RR8": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#007d40"), foregroundColor: LineStyle.white),
            "RR11": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#e6a300"), foregroundColor: LineStyle.white)
        ]
    }
    
    override func stopFinderRequestParameters(builder: UrlBuilder, constraint: String, types: [LocationType]?, maxLocations: Int, outputFormat: String) {
        super.stopFinderRequestParameters(builder: builder, constraint: constraint, types: types, maxLocations: maxLocations, outputFormat: outputFormat)
        builder.addParameter(key: "avvStopFinderMacro", value: 1)
    }
    
    override func queryTripsParameters(builder: UrlBuilder, from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions) {
        super.queryTripsParameters(builder: builder, from: from, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions)
        
        for product in tripOptions.products ?? [] {
            switch product {
            case .bus: builder.addParameter(key: "inclMOT_11", value: "on") // night bus
            case .regionalTrain: builder.addParameter(key: "inclMOT_13", value: "on") // regional train
            default: break
            }
        }
    }
    
    override func parseLine(id: String?, network: String?, mot: String?, symbol: String?, name: String?, longName: String?, trainType: String?, trainNum: String?, trainName: String?) -> Line {
        if mot == "0" {
            if trainName == "Regionalbahn", let symbol = symbol {
                return Line(id: id, network: network, product: .regionalTrain, label: symbol)
            } else if trainNum == "Staudenbahn SVG" && trainType == nil && trainName == nil {
                return Line(id: id, network: network, product: .regionalTrain, label: "SVG")
            }
            
            // Streikfahrplan
            if symbol == "R1S" || symbol == "R4S" || symbol == "R6S" || symbol == "R7S" || symbol == "R8S" {
                return Line(id: id, network: network, product: .regionalTrain, label: symbol)
            }
        }
        return super.parseLine(id: id, network: network, mot: mot, symbol: symbol, name: name, longName: longName, trainType: trainType, trainNum: trainNum, trainName: trainName)
    }
    
}
