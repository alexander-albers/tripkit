import Foundation
import TestsCommon
@testable import TripKit

class VmsProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .VMS }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return VmsProvider()
    }
    
}
