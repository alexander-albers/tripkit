import Foundation
import TestsCommon
@testable import TripKit

class LinzProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .LINZ }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return LinzProvider()
    }
    
}
