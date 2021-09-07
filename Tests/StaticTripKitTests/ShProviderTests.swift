import Foundation
import TestsCommon
@testable import TripKit

class ShProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .SH }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return ShProvider(apiAuthorization: authorizationData.hciAuthorization)
    }
    
}
