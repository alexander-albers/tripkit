import Foundation

/// Donau-Iller-Nahverkehrsverbund (DE)
public class DingProvider: AbstractEfaWebProvider {
    
    static let API_BASE = "https://www.ding.eu/ding3/"
    
    public override var supportedLanguages: Set<String> { ["de"] }
    
    public init() {
        super.init(networkId: .DING, apiBase: DingProvider.API_BASE)
    }
    
}
