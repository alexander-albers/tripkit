import Foundation

public struct ParseError: Error {
    
    public var reason: String
    
    init(reason: String) {
        self.reason = reason
    }
    
}
