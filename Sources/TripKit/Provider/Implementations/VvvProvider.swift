import Foundation

/// Verkehrsverbund Vogtland (DE)
public class VvvProvider: AbstractEfaProvider {
    
    static let API_BASE = "https://vogtlandauskunft.de/vvv2/"
    
    public override var supportedLanguages: Set<String> { ["de", "en"] }
    
    public init() {
        super.init(networkId: .VVV, apiBase: VvvProvider.API_BASE)
    }
    
}
