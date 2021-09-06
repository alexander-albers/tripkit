import Foundation
@testable import TripKit

class VrnProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .VRN }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return VrnProvider()
    }
    
}
