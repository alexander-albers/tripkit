import Foundation
import TestsCommon
@testable import TripKit

class VbbProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .VBB }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return VbbProvider(apiAuthorization: authorizationData.hciAuthorization)
    }
    
}
