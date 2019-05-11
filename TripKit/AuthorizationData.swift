import Foundation

public struct AuthorizationData {
    public var hciAuthorization: [String: Any]
    public var hciRequestVerification: AbstractHafasClientInterfaceProvider.RequestVerification
    
    public init(hciAuthorization: [String: Any], hciRequestVerification: AbstractHafasClientInterfaceProvider.RequestVerification) {
        self.hciAuthorization = hciAuthorization
        self.hciRequestVerification = hciRequestVerification
    }
    
    public init() {
        self.hciAuthorization = [:]
        self.hciRequestVerification = .none
    }
}
