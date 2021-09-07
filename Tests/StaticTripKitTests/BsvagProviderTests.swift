import Foundation
import TestsCommon
@testable import TripKit

class BsvagProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .BSVAG }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return BsvagProvider()
    }
    
}
