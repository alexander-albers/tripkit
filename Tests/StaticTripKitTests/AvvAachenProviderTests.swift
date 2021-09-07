import Foundation
import TestsCommon
@testable import TripKit

class AvvAachenProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .AVV2 }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return AvvAachenProvider(apiAuthorization: authorizationData.hciAuthorization)
    }
    
}
