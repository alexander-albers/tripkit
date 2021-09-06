import Foundation
@testable import TripKit

class VvmProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .VVM }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return VvmProvider()
    }
    
    var supportsQueryMoreTrips: Bool { return false }
    
}
