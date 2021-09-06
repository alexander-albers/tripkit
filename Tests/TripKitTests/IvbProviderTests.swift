import Foundation
@testable import TripKit

class IvbProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .IVB }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return IvbProvider(apiAuthorization: authorizationData.hciAuthorization)
    }
    
}
