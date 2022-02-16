import Foundation
import TestsCommon
@testable import TripKit

class VosProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .VOS }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return VosProvider(apiAuthorization: authorizationData.hciAuthorization)
    }
    
}
