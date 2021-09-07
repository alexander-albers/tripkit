import Foundation
import TestsCommon
@testable import TripKit

class VvvProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .VVV }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return VvvProvider()
    }
    
}
