import Foundation

/// Sudtiroler Transportstrukturen AG (IT)
public class StaProvider: AbstractEfaWebProvider {
    
    static let API_BASE = "https://efa.sta.bz.it/app/"
    
    public override var supportedLanguages: Set<String> { ["de", "en", "it", "ld1", "ld2"] }
    
    public init() {
        super.init(networkId: .STA, apiBase: StaProvider.API_BASE)
        
        styles = [
            "B": LineStyle(backgroundColor: LineStyle.parseColor("#005980"), foregroundColor: LineStyle.white),
            "BN1": LineStyle(backgroundColor: LineStyle.parseColor("#5e5971"), foregroundColor: LineStyle.white),
            "BN13": LineStyle(backgroundColor: LineStyle.parseColor("#5e5971"), foregroundColor: LineStyle.white),
            "BN35": LineStyle(backgroundColor: LineStyle.parseColor("#5e5971"), foregroundColor: LineStyle.white),
            "B110": LineStyle(backgroundColor: LineStyle.parseColor("#26b5e2"), foregroundColor: LineStyle.white),
            "B111": LineStyle(backgroundColor: LineStyle.parseColor("#656cb0"), foregroundColor: LineStyle.white),
            "B111a": LineStyle(backgroundColor: LineStyle.parseColor("#a49ba4"), foregroundColor: LineStyle.white),
            "B112": LineStyle(backgroundColor: LineStyle.parseColor("#24426e"), foregroundColor: LineStyle.white),
            "B183": LineStyle(backgroundColor: LineStyle.parseColor("#d0aad1"), foregroundColor: LineStyle.white),
            "B210": LineStyle(backgroundColor: LineStyle.parseColor("#61a375"), foregroundColor: LineStyle.white),
            "B211": LineStyle(backgroundColor: LineStyle.parseColor("#e21e23"), foregroundColor: LineStyle.white),
            "B212": LineStyle(backgroundColor: LineStyle.parseColor("#656cb0"), foregroundColor: LineStyle.white),
            "B213": LineStyle(backgroundColor: LineStyle.parseColor("#008294"), foregroundColor: LineStyle.white),
            "B217": LineStyle(backgroundColor: LineStyle.parseColor("#a79ecd"), foregroundColor: LineStyle.white),
            "B221": LineStyle(backgroundColor: LineStyle.parseColor("#b0cb1f"), foregroundColor: LineStyle.white),
        ]
    }
    
}
