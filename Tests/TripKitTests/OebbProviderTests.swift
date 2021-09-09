import Foundation
import TestsCommon
@testable import TripKit
import os.log
import XCTest

class OebbProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .OEBB }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return OebbProvider(apiAuthorization: authorizationData.hciAuthorization)
    }
    
}
