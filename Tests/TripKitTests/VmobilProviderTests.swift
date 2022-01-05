import Foundation
import TestsCommon
@testable import TripKit

class VmobilProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .VMOBIL }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return VmobilProvider(apiAuthorization: authorizationData.hciAuthorization)
    }
    
}
