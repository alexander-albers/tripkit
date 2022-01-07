import Foundation
import TestsCommon
@testable import TripKit

class VorProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .VOR }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return VorProvider(apiAuthorization: authorizationData.hciAuthorization)
    }
    
}
