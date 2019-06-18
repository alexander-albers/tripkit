import Foundation

open class SuggestedLocation: CustomStringConvertible {
    
    public let location: Location!
    public let priority: Int!
    
    public init(location: Location, priority: Int) {
        self.location = location
        self.priority = priority
    }
    
    public var description: String {
        return location.description
    }
    
}
