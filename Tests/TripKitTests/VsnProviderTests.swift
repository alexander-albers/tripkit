import Foundation
@testable import TripKit

class VsnProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .VSN }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return VsnProvider(apiAuthorization: authorizationData.hciAuthorization, requestVerification: authorizationData.hciRequestVerification)
    }
    
}
