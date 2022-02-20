import Foundation

/// Basler Verkehrs-Betriebe (CH)
public class BvbProvider: AbstractEfaWebProvider {
    
    static let API_BASE = "https://www.efa-bw.de/bvb3/"
    
    public override var supportedLanguages: Set<String> { ["de", "en", "fr"] }
    
    public init() {
        super.init(networkId: .BVB, apiBase: BvbProvider.API_BASE)
        includeRegionId = false
    }

}
