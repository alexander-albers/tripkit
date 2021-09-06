import Foundation
@testable import TripKit

class VgnProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .VGN }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return VgnProvider()
    }
    
}
