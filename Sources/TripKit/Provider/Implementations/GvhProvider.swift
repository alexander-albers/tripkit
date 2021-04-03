import Foundation

public class GvhProvider: AbstractEfaProvider {
    
    static let API_BASE = "https://app.efa.de/mdv_server/app_gvh/"

    public init() {
        super.init(networkId: .GVH, apiBase: GvhProvider.API_BASE)
        includeRegionId = false
        
        styles = [
            // Hannover
            "SS1": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#816ba8"), foregroundColor: LineStyle.white),
            "SS2": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#007a3b"), foregroundColor: LineStyle.white),
            "SS21": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#007a3b"), foregroundColor: LineStyle.white),
            "SS3": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#cc68a6"), foregroundColor: LineStyle.white),
            "SS4": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#9b2a48"), foregroundColor: LineStyle.white),
            "SS5": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#f18700"), foregroundColor: LineStyle.white),
            "SS51": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#f18700"), foregroundColor: LineStyle.white),
            "SS6": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#004e9e"), foregroundColor: LineStyle.white),
            "SS7": LineStyle(shape: .circle, backgroundColor: LineStyle.parseColor("#afcb25"), foregroundColor: LineStyle.white),
            
            "T1": LineStyle(shape: .rect, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#e40039")),
            "T2": LineStyle(shape: .rect, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#e40039")),
            "T3": LineStyle(shape: .rect, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#0069b4")),
            "T4": LineStyle(shape: .rect, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#f9b000")),
            "T5": LineStyle(shape: .rect, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#f9b000")),
            "T6": LineStyle(shape: .rect, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#f9b000")),
            "T16": LineStyle(shape: .rect, backgroundColor: LineStyle.white, foregroundColor: LineStyle.gray, borderColor: LineStyle.parseColor("#f9b000")),
            "T7": LineStyle(shape: .rect, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#0069b4")),
            "T8": LineStyle(shape: .rect, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#e40039")),
            "T18": LineStyle(shape: .rect, backgroundColor: LineStyle.white, foregroundColor: LineStyle.gray, borderColor: LineStyle.parseColor("#e40039")),
            "T9": LineStyle(shape: .rect, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#0069b4")),
            "T10": LineStyle(shape: .rect, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#76b828")),
            "T11": LineStyle(shape: .rect, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#f9b000")),
            "T17": LineStyle(shape: .rect, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#76b828")),
            
            "B100": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#1eb5ea")),
            "B120": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#2eab5c")),
            "B121": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#2eab5c")),
            "B122": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#e3001f")),
            "B123": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#2eab5c")),
            "B124": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#e3001f")),
            "B125": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#1eb5ea")),
            "B126": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#a2c613")),
            "B127": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#1a70b8")),
            "B128": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#9e348b")),
            "B129": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#1a70b8")),
            "B130": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#a2c613")),
            "B133": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#a2c613")),
            "B134": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#e21f34")),
            "B135": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#2eab5c")),
            "B136": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#1eb5ea")),
            "B137": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#9e348b")),
            "B200": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#1a70b8")),
            "B300": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#a2c613")),
            "B330": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#fbba00")),
            "B340": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#f39100")),
            "B341": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#f39100")),
            "B350": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#1a70b8")),
            "B360": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#e3001f")),
            "B363": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#1a70b8")),
            "B365": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#1eb5ea")),
            "B366": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#fbba00")),
            "B370": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#f39100")),
            "B420": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#1eb5ea")),
            "B440": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#f39100")),
            "B450": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#2eab5c")),
            "B460": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#a2c613")),
            "B461": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#e3001f")),
            "B470": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#1a70b8")),
            "B490": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#fbba00")),
            "B491": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#9e348b")),
            "B500": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#fbba00")),
            "B570": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#9e348b")),
            "B571": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#a2c613")),
            "B574": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#fbba00")),
            "B580": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#fbba00")),
            "B581": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#e3001f")),
            "B620": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#fbba00")),
            "B631": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#f39100")),
            "B700": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.black, borderColor: LineStyle.parseColor("#f39100")),
            "BN31": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.parseColor("#9e348b")),
            "BN41": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.parseColor("#1a70b8")),
            "BN43": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.parseColor("#1a70b8")),
            "BN56": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.parseColor("#2eab5c")),
            "BN57": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.parseColor("#1eb5ea")),
            "BN70": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.parseColor("#1a70b8")),
            "BN62": LineStyle(shape: .circle, backgroundColor: LineStyle.white, foregroundColor: LineStyle.parseColor("#1a70b8")),
            
            // Hamburg
            "UU1": LineStyle(backgroundColor: LineStyle.parseColor("#044895"), foregroundColor: LineStyle.white),
            "UU2": LineStyle(backgroundColor: LineStyle.parseColor("#DC2B19"), foregroundColor: LineStyle.white),
            "UU3": LineStyle(backgroundColor: LineStyle.parseColor("#EE9D16"), foregroundColor: LineStyle.white),
            "UU4": LineStyle(backgroundColor: LineStyle.parseColor("#13A59D"), foregroundColor: LineStyle.white)
        ]
    }
    
}
