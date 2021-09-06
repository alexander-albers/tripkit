import Foundation
@testable import TripKit

class DbProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .DB }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return DbProvider(apiAuthorization: authorizationData.hciAuthorization, requestVerification: authorizationData.hciRequestVerification)
    }
    
}
