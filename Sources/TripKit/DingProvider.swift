import Foundation

public class DingProvider: AbstractEfaProvider {
    
    static let API_BASE = "https://www.ding.eu/ding3/"
    
    public init() {
        super.init(networkId: .DING, apiBase: DingProvider.API_BASE)
    }
    
}
