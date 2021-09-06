import Foundation
@testable import TripKit

class NvvProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .NVV }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return NvvProvider(apiAuthorization: authorizationData.hciAuthorization, requestVerification: authorizationData.hciRequestVerification)
    }
    
}
