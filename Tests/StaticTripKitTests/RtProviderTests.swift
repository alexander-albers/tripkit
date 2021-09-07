import Foundation
import TestsCommon
@testable import TripKit

class RtProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .RT }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return RtProvider()
    }
    
    var supportsJourneyDetails: Bool { return false }
    
}
