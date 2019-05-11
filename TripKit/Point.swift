import Foundation

public class LocationPoint: NSObject, NSSecureCoding {
    
    public static var supportsSecureCoding: Bool = true
    
    public let lat: Int
    public let lon: Int
    
    public init(lat: Int, lon: Int) {
        self.lat = lat
        self.lon = lon
    }
    
    required convenience public init?(coder aDecoder: NSCoder) {
        self.init(lat: aDecoder.decodeInteger(forKey: PropertyKey.lat), lon: aDecoder.decodeInteger(forKey: PropertyKey.lon))
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(lat, forKey: PropertyKey.lat)
        aCoder.encode(lon, forKey: PropertyKey.lon)
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? LocationPoint else { return false }
        if self === other { return true }
        return self.lat == other.lat && self.lon == other.lon
    }
    
    struct PropertyKey {
        
        static let lat = "lat"
        static let lon = "lon"
        
    }
    
}
