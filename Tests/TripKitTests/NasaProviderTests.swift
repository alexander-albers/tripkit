import Foundation
@testable import TripKit

class NasaProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .NASA }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return NasaProvider(apiAuthorization: authorizationData.hciAuthorization)
    }
    
}
