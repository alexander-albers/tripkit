import Foundation

/// Linz AG (AT)
public class LinzProvider: AbstractEfaWebProvider {
    
    static let API_BASE = "https://www.linzag.at/linz-efa/"
    
    public override var supportedLanguages: Set<String> { ["de", "en"] }
    
    public init() {
        super.init(networkId: .LINZ, apiBase: LinzProvider.API_BASE)
        useRouteIndexAsTripId = false
        
        styles = [
            // Regular buses
            "B11": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#f5821f"), foregroundColor: LineStyle.white),
            "B12": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#139654"), foregroundColor: LineStyle.white),
            "B17": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#f5821f"), foregroundColor: LineStyle.white),
            "B18": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#008cd1"), foregroundColor: LineStyle.white),
            "B19": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#f287b7"), foregroundColor: LineStyle.white),
            "B25": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#c6912f"), foregroundColor: LineStyle.white),
            "B26": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#008cd1"), foregroundColor: LineStyle.white),
            "B27": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#a4c760"), foregroundColor: LineStyle.white),
            "B33": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#cb96a1"), foregroundColor: LineStyle.white),
            "B33a": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#cb96a1"), foregroundColor: LineStyle.white),
            "B38": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#f5821f"), foregroundColor: LineStyle.white),
            "B41": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#d1232b"), foregroundColor: LineStyle.white),
            "B43": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#40c7f4"), foregroundColor: LineStyle.white),
            "B45": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#d1232b"), foregroundColor: LineStyle.white),
            "B45a": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#d1232b"), foregroundColor: LineStyle.white),
            "B46": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#40c7f4"), foregroundColor: LineStyle.white),
            "BN83": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#0196DA"), foregroundColor: LineStyle.white), // night
            
            // Express buses
            "B70": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#955336"), foregroundColor: LineStyle.white),
            "B71": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#955336"), foregroundColor: LineStyle.white),
            "B72": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#955336"), foregroundColor: LineStyle.white),
            "B73": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#955336"), foregroundColor: LineStyle.white),
            "B77": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#955336"), foregroundColor: LineStyle.white),
            
            // District buses
            "B101": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#dcaf3b"), foregroundColor: LineStyle.white),
            "B102": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#4cb949"), foregroundColor: LineStyle.white),
            "B103": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#4cb949"), foregroundColor: LineStyle.white),
            "B104": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#dcaf3b"), foregroundColor: LineStyle.white),
            "B105": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#4cb949"), foregroundColor: LineStyle.white),
            "B106": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#4cb949"), foregroundColor: LineStyle.white),
            "B107": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#dcaf3b"), foregroundColor: LineStyle.white),
            "B108": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#dcaf3b"), foregroundColor: LineStyle.white),
            "B150": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#dcaf3b"), foregroundColor: LineStyle.white),
            "B191": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#4cb949"), foregroundColor: LineStyle.white),
            "B192": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#dcaf3b"), foregroundColor: LineStyle.white),
            "B194": LineStyle(shape: .rounded, backgroundColor: LineStyle.parseColor("#4cb949"), foregroundColor: LineStyle.white),
            
            // Trams
            "T1": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ef377f"), foregroundColor: LineStyle.white),
            "T2": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#c77db5"), foregroundColor: LineStyle.white),
            "TN82": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#bb74a4"), foregroundColor: LineStyle.white), // night
            "T3": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#a3238f"), foregroundColor: LineStyle.white),
            "T4": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#c40652"), foregroundColor: LineStyle.white),
            "TN84": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#b0174c"), foregroundColor: LineStyle.white), // night
            
            "T50": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#008f4d"), foregroundColor: LineStyle.white) // Pöstlingbergbahn
        ]
    }
    
}
