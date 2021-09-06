import Foundation
@testable import TripKit

class VvsProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .VVS }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return VvsProvider()
    }
    
}
