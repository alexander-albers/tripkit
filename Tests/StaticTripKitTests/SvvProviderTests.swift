import Foundation
import TestsCommon
@testable import TripKit

class SvvProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .SVV }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return SvvProvider(apiAuthorization: authorizationData.hciAuthorization)
    }
    
}
