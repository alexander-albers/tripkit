import Foundation

public struct AuthorizationData {
    public var apiBase: String = ""
    public var hciAuthorization: [String: Any] = [:]
    public var certAuthorization: [String: Any] = [:]
    public var hciRequestVerification: AbstractHafasClientInterfaceProvider.RequestVerification = .none
}
