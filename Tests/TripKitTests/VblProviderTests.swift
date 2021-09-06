import Foundation
@testable import TripKit

class VblProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .VBL }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return VblProvider()
    }
    
}
