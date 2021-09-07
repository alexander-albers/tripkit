import Foundation
import TestsCommon
@testable import TripKit

class MvgProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .MVG }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return MvgProvider()
    }
    
}
