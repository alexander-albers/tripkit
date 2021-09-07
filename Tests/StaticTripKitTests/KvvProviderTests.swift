import Foundation
import TestsCommon
@testable import TripKit

class KvvProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .KVV }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return KvvProvider()
    }
    
}
