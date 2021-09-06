import XCTest
@testable import TripKit
import os.log

class RmvProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .RMV }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return RmvProvider(apiAuthorization: authorizationData.hciAuthorization)
    }
    
}
