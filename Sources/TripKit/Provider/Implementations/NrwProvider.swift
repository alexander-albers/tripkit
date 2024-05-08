import Foundation

/// Nordrhein-Westfalen (DE)
public class NrwProvider: AbstractEfaWebProvider {
    
    static let API_BASE = "https://ticketshop.mobil.nrw/MS_EFA/"
    
    public override var supportedLanguages: Set<String> { ["de"] }
    
    public init() {
        super.init(networkId: .NRW, apiBase: NrwProvider.API_BASE)
        
        styles = [
            "RRE1": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#d7242a"), foregroundColor: LineStyle.white),
            "RRE2": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#00a3db"), foregroundColor: LineStyle.white),
            "RRE3": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#c66c2f"), foregroundColor: LineStyle.white),
            "RRE4": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#cb8b26"), foregroundColor: LineStyle.white),
            "RRE5": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#0273a2"), foregroundColor: LineStyle.white),
            "RRE6": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#912a7d"), foregroundColor: LineStyle.white),
            "RRE7": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#0c2954"), foregroundColor: LineStyle.white),
            "RRE8": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#0062a2"), foregroundColor: LineStyle.white),
            "RRE9": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#39143a"), foregroundColor: LineStyle.white),
            "RRE10": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#cd5c91"), foregroundColor: LineStyle.white),
            "RRE11": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#5ebcb1"), foregroundColor: LineStyle.white),
            "RRE12": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#952b4b"), foregroundColor: LineStyle.white),
            "RRE13": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#6d5525"), foregroundColor: LineStyle.white),
            "RRE14": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#013929"), foregroundColor: LineStyle.white),
            "RRE15": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#805492"), foregroundColor: LineStyle.white),
            "RRE16": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#005368"), foregroundColor: LineStyle.white),
            "RRE17": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#488d42"), foregroundColor: LineStyle.white),
            "RRE18": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#15aba2"), foregroundColor: LineStyle.white),
            "RRE19": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#1d5828"), foregroundColor: LineStyle.white),
            "RRE22": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#efa940"), foregroundColor: LineStyle.white),
            "RRE29": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#c788b1"), foregroundColor: LineStyle.white),
            "RRE42": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#cab631"), foregroundColor: LineStyle.white),
            "RRE44": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#628da0"), foregroundColor: LineStyle.white),
            "RRE49": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#b78970"), foregroundColor: LineStyle.white),
            "RRE57": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#3c6390"), foregroundColor: LineStyle.white),
            "RRE60": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#005129"), foregroundColor: LineStyle.white),
            "RRE70": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#8883b0"), foregroundColor: LineStyle.white),
            "RRE78": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#56a9b9"), foregroundColor: LineStyle.white),
            "RRE82": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#488d42"), foregroundColor: LineStyle.white),
            "RRE99": LineStyle(shape: .rect, backgroundColor: LineStyle.parseColor("#01a249"), foregroundColor: LineStyle.white),
        ]
    }

}
