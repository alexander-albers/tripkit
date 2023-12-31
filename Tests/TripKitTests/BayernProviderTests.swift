import Foundation
import TestsCommon
@testable import TripKit

class BayernProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .BAYERN }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return BayernProvider()
    }
    
    var supportsRefreshTrip: Bool { return false }
    
}
