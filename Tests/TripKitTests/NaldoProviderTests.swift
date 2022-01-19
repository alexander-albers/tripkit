import Foundation
import TestsCommon
@testable import TripKit

class NaldoProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .NALDO }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return NaldoProvider()
    }
    
}
