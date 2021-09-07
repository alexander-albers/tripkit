import Foundation
import TestsCommon
@testable import TripKit

class DingProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .DING }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return DingProvider()
    }
    
}
