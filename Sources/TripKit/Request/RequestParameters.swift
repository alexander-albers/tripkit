import Foundation

public enum Optimize: Int {
    case leastDuration, leastChanges, leastWalking
}

public enum WalkSpeed: Int {
    case slow, normal, fast
}

public enum Accessibility: Int {
    case neutral, limited, barrierFree
}

public enum Option: Int {
    case bike
}

public class TripOptions: NSObject, NSSecureCoding {
    
    public static var supportsSecureCoding: Bool = true
    
    public var products: [Product]?
    public var optimize: Optimize?
    public var walkSpeed: WalkSpeed?
    public var accessibility: Accessibility?
    public var options: [Option]?
    public var maxChanges: Int?
    public var minChangeTime: Int? // in minutes
    public var maxFootpathTime: Int? // in minutes
    public var maxFootpathDist: Int? // in meters
    
    public init(products: [Product]? = nil, optimize: Optimize? = nil, walkSpeed: WalkSpeed? = nil, accessibility: Accessibility? = nil, options: [Option]? = nil, maxChanges: Int? = nil, minChangeTime: Int? = nil, maxFootpathTime: Int? = nil, maxFootpathDist: Int? = nil) {
        self.products = products
        self.optimize = optimize
        self.accessibility = accessibility
        self.options = options
        self.maxChanges = maxChanges
        self.minChangeTime = minChangeTime
        self.maxFootpathTime = maxFootpathTime
        self.maxFootpathDist = maxFootpathDist
    }
    
    public required convenience init?(coder aDecoder: NSCoder) {
        let productsString = aDecoder.decodeObject(of: [NSArray.self, NSString.self], forKey: PropertyKey.products) as? [String]
        let products = productsString?.compactMap { Product(rawValue: $0) }
        let optimize = Optimize(rawValue: aDecoder.decodeObject(of: NSNumber.self, forKey: PropertyKey.optimize) as? Int ?? -1)
        let walkSpeed = WalkSpeed(rawValue: aDecoder.decodeObject(of: NSNumber.self, forKey: PropertyKey.walkSpeed) as? Int ?? -1)
        let accessibility = Accessibility(rawValue: aDecoder.decodeObject(of: NSNumber.self, forKey: PropertyKey.accessibility) as? Int ?? -1)
        let optionsInt = aDecoder.decodeObject(of: [NSArray.self], forKey: PropertyKey.options) as? [Int]
        let options = optionsInt?.compactMap { Option(rawValue: $0) }
        let maxChanges = aDecoder.decodeObject(of: NSNumber.self, forKey: PropertyKey.maxChanges) as? Int
        let minChangeTime = aDecoder.decodeObject(of: NSNumber.self, forKey: PropertyKey.minChangeTime) as? Int
        let maxFootpathTime = aDecoder.decodeObject(of: NSNumber.self, forKey: PropertyKey.maxFootpathTime) as? Int
        let maxFootpathDist = aDecoder.decodeObject(of: NSNumber.self, forKey: PropertyKey.maxFootpathDist) as? Int
        self.init(products: products, optimize: optimize, walkSpeed: walkSpeed, accessibility: accessibility, options: options, maxChanges: maxChanges, minChangeTime: minChangeTime, maxFootpathTime: maxFootpathTime, maxFootpathDist: maxFootpathDist)
    }
    
    public func encode(with aCoder: NSCoder) {
        if let products = products {
            aCoder.encode(products.map { $0.rawValue }, forKey: PropertyKey.products)
        }
        aCoder.encode(optimize?.rawValue, forKey: PropertyKey.optimize)
        aCoder.encode(walkSpeed?.rawValue, forKey: PropertyKey.walkSpeed)
        aCoder.encode(accessibility?.rawValue, forKey: PropertyKey.accessibility)
        aCoder.encode(options?.map { $0.rawValue }, forKey: PropertyKey.options)
        aCoder.encode(maxChanges, forKey: PropertyKey.maxChanges)
        aCoder.encode(minChangeTime, forKey: PropertyKey.minChangeTime)
        aCoder.encode(maxFootpathTime, forKey: PropertyKey.maxFootpathTime)
        aCoder.encode(maxFootpathDist, forKey: PropertyKey.maxFootpathDist)
    }
    
    struct PropertyKey {
        static let products = "products"
        static let optimize = "optimize"
        static let walkSpeed = "walkSpeed"
        static let accessibility = "accessibility"
        static let options = "options"
        static let maxChanges = "maxChanges"
        static let minChangeTime = "minChangeTime"
        static let maxFootpathTime = "maxFootpathTime"
        static let maxFootpathDist = "maxFootpathDist"
    }
}

public enum QueryTrait: Int {
    case maxChanges, minChangeTime, maxFootpathTime, maxFootpathDist
}
