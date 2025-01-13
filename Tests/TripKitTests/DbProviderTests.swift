import Foundation
import TestsCommon
@testable import TripKit

class DbProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .DB }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return DbProvider()
    }
    
}
