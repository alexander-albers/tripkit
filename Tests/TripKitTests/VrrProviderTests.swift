import Foundation
@testable import TripKit

class VrrProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .VRR }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return VrrProvider()
    }
    
}
