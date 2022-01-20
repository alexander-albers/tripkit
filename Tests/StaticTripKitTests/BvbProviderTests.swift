import Foundation
import TestsCommon
@testable import TripKit

class BvbProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .BVB }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return BvbProvider()
    }
    
}
