import Foundation
import TestsCommon
@testable import TripKit

class NrwProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var supportsQueryMoreTrips: Bool { return false }
    
    var networkId: NetworkId { return .NRW }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return NrwProvider()
    }
    
}
