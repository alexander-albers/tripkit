
import Foundation
import TestsCommon
@testable import TripKit

class BlsProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .BLS }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return BlsProvider(apiAuthorization: authorizationData.hciAuthorization)
    }
    
}
