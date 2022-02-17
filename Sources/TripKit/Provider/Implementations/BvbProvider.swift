import Foundation

/// Basler Verkehrs-Betriebe (CH)
public class BvbProvider: AbstractEfaProvider {
    
    static let API_BASE = "https://www.efa-bw.de/bvb3/"
    
    public init() {
        super.init(networkId: .BVB, apiBase: BvbProvider.API_BASE)
        includeRegionId = false
    }

}
