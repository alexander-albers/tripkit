import Foundation
import TestsCommon
@testable import TripKit

class VgsProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .VGS }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return VgsProvider(apiAuthorization: authorizationData.hciAuthorization)
    }
    
}
