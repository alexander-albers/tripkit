import Foundation
import TestsCommon
@testable import TripKit

class StaProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .STA }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return StaProvider()
    }
    
}
