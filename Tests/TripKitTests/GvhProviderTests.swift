import Foundation
import TestsCommon
@testable import TripKit

class GvhProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .GVH }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return GvhProvider(apiAuthorization: authorizationData.hciAuthorization)
    }
    
}
