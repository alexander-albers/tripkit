import Foundation
import TestsCommon
@testable import TripKit

class BvgProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .BVG }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return BvgProvider(apiAuthorization: authorizationData.hciAuthorization)
    }
    
}
