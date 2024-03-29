import Foundation
import TestsCommon
@testable import TripKit

class HvvProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var supportsRefreshTrip: Bool { false }
    
    var networkId: NetworkId { return .HVV }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return HvvProvider(apiAuthorization: authorizationData.hciAuthorization)
    }
    
}
