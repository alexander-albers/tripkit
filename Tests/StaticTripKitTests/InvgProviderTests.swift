import Foundation
import TestsCommon
@testable import TripKit

class InvgProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .INVG }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return InvgProvider(apiAuthorization: authorizationData.hciAuthorization, requestVerification: authorizationData.hciRequestVerification)
    }
    
}
