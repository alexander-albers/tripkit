import Foundation
import TestsCommon
@testable import TripKit

class ZvvProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .ZVV }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return ZvvProvider(apiAuthorization: authorizationData.hciAuthorization, requestVerification: authorizationData.hciRequestVerification)
    }
    
}
