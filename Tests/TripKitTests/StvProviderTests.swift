import Foundation
@testable import TripKit

class StvProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .STV }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return StvProvider(apiAuthorization: authorizationData.hciAuthorization)
    }
    
}
