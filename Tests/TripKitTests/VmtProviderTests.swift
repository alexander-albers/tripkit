import Foundation
@testable import TripKit

class VmtProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .VMT }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return VmtProvider(apiAuthorization: authorizationData.hciAuthorization)
    }
    
}
