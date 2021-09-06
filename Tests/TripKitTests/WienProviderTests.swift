import Foundation
@testable import TripKit

class WienProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .WIEN }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return WienProvider()
    }
    
    var supportsRefreshTrip: Bool { return false }
    
    var supportsJourneyDetails: Bool { return false }
    
}
