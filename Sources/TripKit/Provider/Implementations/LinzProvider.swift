import Foundation

/// Linz AG (AT)
public class LinzProvider: AbstractEfaProvider {
    
    static let API_BASE = "https://www.linzag.at/linz2/"
    
    public init() {
        super.init(networkId: .LINZ, apiBase: LinzProvider.API_BASE)
        useRouteIndexAsTripId = false
        requestUrlEncoding = .isoLatin1
        
        styles = [
            "B11": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#f27b02"), foregroundColor: LineStyle.white),
            "B12": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#00863a"), foregroundColor: LineStyle.white),
            "B17": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#f47a00"), foregroundColor: LineStyle.white),
            "B18": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#0066b5"), foregroundColor: LineStyle.white),
            "B19": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#f36aa8"), foregroundColor: LineStyle.white),
            "B25": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#d29f08"), foregroundColor: LineStyle.white),
            "B26": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#0070b6"), foregroundColor: LineStyle.white),
            "B27": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#96c41c"), foregroundColor: LineStyle.white),
            "B33": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#6d1f82"), foregroundColor: LineStyle.white),
            "B38": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#ef7b02"), foregroundColor: LineStyle.white),
            "B43": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#00ace3"), foregroundColor: LineStyle.white),
            "B45": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#db0c10"), foregroundColor: LineStyle.white),
            "B46": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#00acea"), foregroundColor: LineStyle.white),
            "B101": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#fdba00"), foregroundColor: LineStyle.white),
            "B102": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#9d701f"), foregroundColor: LineStyle.white),
            "B103": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#019793"), foregroundColor: LineStyle.white),
            "B104": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#699c23"), foregroundColor: LineStyle.white),
            "B105": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#004b9e"), foregroundColor: LineStyle.white),
            "B191": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#1293a8"), foregroundColor: LineStyle.white),
            "B192": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#947ab7"), foregroundColor: LineStyle.white),
            "BN2": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#005aac"), foregroundColor: LineStyle.white), // night
            "BN3": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#b80178"), foregroundColor: LineStyle.white), // night
            "BN4": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#93be01"), foregroundColor: LineStyle.white), // night
            
            "T1": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#dd0b12"), foregroundColor: LineStyle.white),
            "TN1": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#db0e16"), foregroundColor: LineStyle.white), // night
            "T2": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#dd0b12"), foregroundColor: LineStyle.white),
            "T3": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#dd0b12"), foregroundColor: LineStyle.white),
            
            "C50": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#4eae2c"), foregroundColor: LineStyle.white) // Pöstlingbergbahn
        ]
    }
    
}
