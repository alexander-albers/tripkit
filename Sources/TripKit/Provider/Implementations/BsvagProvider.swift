import Foundation

/// Braunschweiger Verkehrs-GmbH (DE)
public class BsvagProvider: AbstractEfaWebProvider {
    
    static let API_BASE = "https://fahrplanauskunft.bsvg.net/efa/"
    
    public override var supportedLanguages: Set<String> { ["de", "en", "tr"] }
    
    public init() {
        super.init(networkId: .BSVAG, apiBase: BsvagProvider.API_BASE)
        useRouteIndexAsTripId = false
        includeRegionId = false
        
        styles = [
            // Braunschweig
            "TM1": LineStyle(backgroundColor: LineStyle.parseColor("#62c2a2"), foregroundColor: LineStyle.white),
            "TM2": LineStyle(backgroundColor: LineStyle.parseColor("#b35e89"), foregroundColor: LineStyle.white),
            "TM3": LineStyle(backgroundColor: LineStyle.parseColor("#f9b5b9"), foregroundColor: LineStyle.white),
            "TM4": LineStyle(backgroundColor: LineStyle.parseColor("#811114"), foregroundColor: LineStyle.white),
            "TM5": LineStyle(backgroundColor: LineStyle.parseColor("#ffd00b"), foregroundColor: LineStyle.white),
            
            "BM11": LineStyle(backgroundColor: LineStyle.parseColor("#88891e"), foregroundColor: LineStyle.white),
            "BM13": LineStyle(backgroundColor: LineStyle.parseColor("#24a06d"), foregroundColor: LineStyle.white),
            "BM16": LineStyle(backgroundColor: LineStyle.parseColor("#f8991b"), foregroundColor: LineStyle.white),
            "BM19": LineStyle(backgroundColor: LineStyle.parseColor("#2c2768"), foregroundColor: LineStyle.white),
            "BM29": LineStyle(backgroundColor: LineStyle.parseColor("#2c2768"), foregroundColor: LineStyle.white),
            
            "B412": LineStyle(backgroundColor: LineStyle.parseColor("#094f34"), foregroundColor: LineStyle.white),
            "B414": LineStyle(backgroundColor: LineStyle.parseColor("#00bce4"), foregroundColor: LineStyle.white),
            "B415": LineStyle(backgroundColor: LineStyle.parseColor("#b82837"), foregroundColor: LineStyle.white),
            "B417": LineStyle(backgroundColor: LineStyle.parseColor("#2a2768"), foregroundColor: LineStyle.white),
            "B418": LineStyle(backgroundColor: LineStyle.parseColor("#c12056"), foregroundColor: LineStyle.white),
            "B420": LineStyle(backgroundColor: LineStyle.parseColor("#b7d55b"), foregroundColor: LineStyle.white),
            "B422": LineStyle(backgroundColor: LineStyle.parseColor("#16bce4"), foregroundColor: LineStyle.white),
            "B424": LineStyle(backgroundColor: LineStyle.parseColor("#ffdf65"), foregroundColor: LineStyle.white),
            "B427": LineStyle(backgroundColor: LineStyle.parseColor("#b5d55b"), foregroundColor: LineStyle.white),
            "B431": LineStyle(backgroundColor: LineStyle.parseColor("#fddb62"), foregroundColor: LineStyle.white),
            "B433": LineStyle(backgroundColor: LineStyle.parseColor("#ed0e65"), foregroundColor: LineStyle.white),
            "B434": LineStyle(backgroundColor: LineStyle.parseColor("#bf2555"), foregroundColor: LineStyle.white),
            "B436": LineStyle(backgroundColor: LineStyle.parseColor("#0080a2"), foregroundColor: LineStyle.white),
            "B437": LineStyle(backgroundColor: LineStyle.parseColor("#fdd11a"), foregroundColor: LineStyle.white),
            "B442": LineStyle(backgroundColor: LineStyle.parseColor("#cc3f68"), foregroundColor: LineStyle.white),
            "B443": LineStyle(backgroundColor: LineStyle.parseColor("#405a80"), foregroundColor: LineStyle.white),
            "B445": LineStyle(backgroundColor: LineStyle.parseColor("#3ca14a"), foregroundColor: LineStyle.white),
            "B450": LineStyle(backgroundColor: LineStyle.parseColor("#f2635a"), foregroundColor: LineStyle.white),
            "B451": LineStyle(backgroundColor: LineStyle.parseColor("#f5791e"), foregroundColor: LineStyle.white),
            "B452": LineStyle(backgroundColor: LineStyle.parseColor("#f0a3ca"), foregroundColor: LineStyle.white),
            "B455": LineStyle(backgroundColor: LineStyle.parseColor("#395f95"), foregroundColor: LineStyle.white),
            "B461": LineStyle(backgroundColor: LineStyle.parseColor("#00b8a0"), foregroundColor: LineStyle.white),
            "B464": LineStyle(backgroundColor: LineStyle.parseColor("#00a14b"), foregroundColor: LineStyle.white),
            "B465": LineStyle(backgroundColor: LineStyle.parseColor("#77234b"), foregroundColor: LineStyle.white),
            "B471": LineStyle(backgroundColor: LineStyle.parseColor("#380559"), foregroundColor: LineStyle.white),
            "B480": LineStyle(backgroundColor: LineStyle.parseColor("#2c2768"), foregroundColor: LineStyle.white),
            "B481": LineStyle(backgroundColor: LineStyle.parseColor("#007ec1"), foregroundColor: LineStyle.white),
            "B484": LineStyle(backgroundColor: LineStyle.parseColor("#dc8998"), foregroundColor: LineStyle.white),
            "B485": LineStyle(backgroundColor: LineStyle.parseColor("#ea8d52"), foregroundColor: LineStyle.white),
            "B493": LineStyle(backgroundColor: LineStyle.parseColor("#f24825"), foregroundColor: LineStyle.white),
            "B560": LineStyle(backgroundColor: LineStyle.parseColor("#9f6fb0"), foregroundColor: LineStyle.white),
            
            // Wolfsburg
            "B201": LineStyle(backgroundColor: LineStyle.parseColor("#f1471c"), foregroundColor: LineStyle.white),
            "B202": LineStyle(backgroundColor: LineStyle.parseColor("#127bca"), foregroundColor: LineStyle.white),
            "B203": LineStyle(backgroundColor: LineStyle.parseColor("#f35c95"), foregroundColor: LineStyle.white),
            "B204": LineStyle(backgroundColor: LineStyle.parseColor("#00a650"), foregroundColor: LineStyle.white),
            "B205": LineStyle(backgroundColor: LineStyle.parseColor("#f67c13"), foregroundColor: LineStyle.white),
            "B206": LineStyle(backgroundColor: LineStyle.white, foregroundColor: LineStyle.parseColor("#00adef"), borderColor: LineStyle.parseColor("#00adef")),
            "B207": LineStyle(backgroundColor: LineStyle.parseColor("#94d221"), foregroundColor: LineStyle.white),
            "B208": LineStyle(backgroundColor: LineStyle.parseColor("#00adef"), foregroundColor: LineStyle.white),
            "B209": LineStyle(backgroundColor: LineStyle.parseColor("#bf7f50"), foregroundColor: LineStyle.white),
            "B211": LineStyle(backgroundColor: LineStyle.parseColor("#be65ba"), foregroundColor: LineStyle.white),
            "B212": LineStyle(backgroundColor: LineStyle.parseColor("#be65ba"), foregroundColor: LineStyle.white),
            "B213": LineStyle(backgroundColor: LineStyle.parseColor("#918f90"), foregroundColor: LineStyle.white),
            "B218": LineStyle(backgroundColor: LineStyle.parseColor("#a950ae"), foregroundColor: LineStyle.white),
            "B219": LineStyle(backgroundColor: LineStyle.parseColor("#bf7f50"), foregroundColor: LineStyle.white),
            "B230": LineStyle(backgroundColor: LineStyle.parseColor("#ca93d0"), foregroundColor: LineStyle.white),
            "B231": LineStyle(backgroundColor: LineStyle.white, foregroundColor: LineStyle.parseColor("#fab20a"), borderColor: LineStyle.parseColor("#fab20a")),
            "B244": LineStyle(backgroundColor: LineStyle.parseColor("#66cef6"), foregroundColor: LineStyle.white),
            "B267": LineStyle(backgroundColor: LineStyle.parseColor("#918f90"), foregroundColor: LineStyle.white)
        ]
    }
    
    override func queryTripsParameters(builder: UrlBuilder, from: Location, via: Location?, to: Location, date: Date, departure: Bool, tripOptions: TripOptions) {
        super.queryTripsParameters(builder: builder, from: from, via: via, to: to, date: date, departure: departure, tripOptions: tripOptions)
        builder.addParameter(key: "inclMOT_11", value: "on")
    }
    
}

