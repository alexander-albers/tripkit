import Foundation
import TestsCommon
@testable import TripKit

class AvvAugsburgProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .AVV }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return AvvAugsburgProvider()
    }
    
    var supportsRefreshTrip: Bool { return false }
}
