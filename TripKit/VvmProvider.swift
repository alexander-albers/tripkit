import Foundation

public class VvmProvider: AbstractEfaProvider {
    
    static let API_BASE = "http://efa.mobilitaetsverbund.de/web/"
    
    public init() {
        super.init(networkId: .VVM, apiBase: VvmProvider.API_BASE)
        needsSpEncId = true
        requestUrlEncoding = .isoLatin1
    }
    
}
