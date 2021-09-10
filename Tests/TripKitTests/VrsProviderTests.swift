import Foundation
import TestsCommon
@testable import TripKit

class VrsProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .VRS }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return VrsProvider(certAuthorization: authorizationData.certAuthorization)
    }
    
}
