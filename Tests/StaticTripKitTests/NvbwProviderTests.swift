import Foundation
import TestsCommon
@testable import TripKit

class NvbwProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .NVBW }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return NvbwProvider()
    }
    
}
