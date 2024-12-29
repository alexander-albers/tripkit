import Foundation
import TestsCommon
@testable import TripKit

class KvbProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .KVB }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return KvbProvider(apiAuthorization: authorizationData.hciAuthorization)
    }
    
}
