import Foundation
@testable import TripKit

class OoevvProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .OOEVV }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return OoevvProvider(apiAuthorization: authorizationData.hciAuthorization, requestVerification: authorizationData.hciRequestVerification)
    }
    
}
