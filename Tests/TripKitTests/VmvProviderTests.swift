import Foundation
@testable import TripKit

class VmvProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .VMV }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return VmvProvider()
    }
    
}
