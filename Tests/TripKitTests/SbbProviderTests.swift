import Foundation
import TestsCommon
@testable import TripKit

class SbbProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .SBB }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return SbbProvider(certAuthorization: authorizationData.certAuthorization)
    }
    
}
