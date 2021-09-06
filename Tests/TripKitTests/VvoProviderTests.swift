import Foundation
@testable import TripKit

class VvoProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .VVO }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return VvoProvider()
    }
    
}
