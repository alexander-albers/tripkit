import Foundation

open class SuggestedLocation: NSObject, NSSecureCoding {
    
    public static var supportsSecureCoding: Bool = true
    
    /// Station, poi or address.
    public let location: Location
    /// Priority for sorting all suggested locations.
    public let priority: Int
    
    public init(location: Location, priority: Int) {
        self.location = location
        self.priority = priority
    }
    
    public required convenience init?(coder: NSCoder) {
        guard
            let location = coder.decodeObject(of: Location.self, forKey: PropertyKey.locationKey)
        else {
            return nil
        }
        let priority = coder.decodeInteger(forKey: PropertyKey.priorityKey)
        self.init(location: location, priority: priority)
    }
    
    public func encode(with coder: NSCoder) {
        coder.encode(location, forKey: PropertyKey.locationKey)
        coder.encode(priority, forKey: PropertyKey.priorityKey)
    }
    
    public override var description: String {
        return location.description
    }
    
    open override func isEqual(_ other: Any?) -> Bool {
        guard let other = other as? SuggestedLocation else { return false }
        if self === other { return true }
        return self.location == other.location
    }
    
    struct PropertyKey {
        
        static let locationKey = "location"
        static let priorityKey = "priority"
        
    }
    
}
