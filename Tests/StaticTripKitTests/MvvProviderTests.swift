import Foundation
import TestsCommon
@testable import TripKit

class MvvProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .MVV }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return MvvProvider()
    }
    
    var supportsRefreshTrip: Bool { return false }
    var supportsJourneyDetails: Bool { return false }
    
}
