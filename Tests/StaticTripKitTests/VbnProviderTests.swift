import Foundation
import TestsCommon
@testable import TripKit

class VbnProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .VBN }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return VbnProvider(apiAuthorization: authorizationData.hciAuthorization)
    }
    
}
