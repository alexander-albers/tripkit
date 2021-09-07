import Foundation
import TestsCommon
@testable import TripKit

class VagfrProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .VAGFR }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return VagfrProvider()
    }
    
}
