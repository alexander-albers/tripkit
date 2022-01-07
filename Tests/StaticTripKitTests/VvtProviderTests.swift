import Foundation
import TestsCommon
@testable import TripKit

class VvtProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .VVT }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return VvtProvider(apiAuthorization: authorizationData.hciAuthorization)
    }
    
}
