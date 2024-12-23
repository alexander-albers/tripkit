
import Foundation
import TestsCommon
@testable import TripKit

class TpgProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .TPG }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return TpgProvider(apiAuthorization: authorizationData.hciAuthorization)
    }
    
}
