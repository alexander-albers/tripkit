import Foundation
import TestsCommon
@testable import TripKit

class SearchChProviderTests: TripKitProviderTestCase, TripKitProviderTestsDelegate {
    
    override var delegate: TripKitProviderTestsDelegate! { return self }
    
    var networkId: NetworkId { return .SEARCHCH }
    
    func initProvider(from authorizationData: AuthorizationData) -> NetworkProvider {
        return SearchChProvider()
    }
    
    var supportsJourneyDetails: Bool { false }
    
}
