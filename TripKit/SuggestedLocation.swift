import Foundation

open class SuggestedLocation: CustomStringConvertible {
    
    public let location: Location!
    public let priority: Int!
    public let displayName: String?
    
    public init(location: Location, priority: Int, displayName: String? = nil) {
        self.location = location
        self.priority = priority
        self.displayName = displayName
    }
    
    public var description: String {
        return "\(displayName ?? location.description)"
    }
    
}
