import Foundation

public class MvgProvider: AbstractEfaProvider {
    
    static let API_BASE = "https://westfalenfahrplan.de/std3/"
    
    public init() {
        super.init(networkId: .MVG, apiBase: MvgProvider.API_BASE)
    }
    
    override func parsePosition(position: String?) -> String? {
        guard let position = position else { return super.parsePosition(position: nil) }
        if position.hasPrefix(" - ") {
            return super.parsePosition(position: position.substring(from: 3))
        } else {
            return super.parsePosition(position: position)
        }
    }

}
