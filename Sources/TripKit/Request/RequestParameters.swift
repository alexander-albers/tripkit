import Foundation

/// How the trip should be optimized.
public enum Optimize: Int {
    /// Find trips with least total duration.
    case leastDuration
    /// Find trips with least number of transitions.
    case leastChanges
    /// Find trips with least walking distance.
    case leastWalking
}

/// Walk speed for footpaths.
public enum WalkSpeed: Int {
    case slow, normal, fast
}

/// Accessibility options
public enum Accessibility: Int {
    /// No accessibility restrictions.
    case neutral
    /// Some restrictions apply, like avoiding staircases.
    case limited
    /// Only request completely barrier free trips.
    case barrierFree
}

/// Additional trip options
public enum Option: Int {
    case bike
}

/// Settings for requesting different tariff information.
public class TariffProfile: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool = true
    
    /// 1 for first-class, 2 for second-class
    public var tariffClass: Int
    /// Type of the traveler, depending on his/her age.
    public var travelerType: TravelerType?
    public var tariffReductions: [TariffReduction]
    
    public init(tariffClass: Int, travelerType: TravelerType?, tariffReductions: [TariffReduction]) {
        self.tariffClass = tariffClass
        self.travelerType = travelerType
        self.tariffReductions = tariffReductions
    }
    
    public required convenience init?(coder: NSCoder) {
        let tariffClass = coder.decodeInteger(forKey: PropertyKey.tariffClass)
        let travelerType = coder.containsValue(forKey: PropertyKey.travelerType) ? TravelerType(rawValue: coder.decodeInteger(forKey: PropertyKey.travelerType)) : nil
        let tariffReductions: [TariffReduction]
        if let reductions = coder.decodeObject(of: [NSArray.self, TariffReduction.self], forKey: PropertyKey.tariffReduction) as? [TariffReduction] {
            tariffReductions = reductions
        } else if let tariffReduction = coder.decodeObject(of: TariffReduction.self, forKey: PropertyKey.tariffReduction) {
            tariffReductions = [tariffReduction]
        } else {
            tariffReductions = []
        }
        self.init(tariffClass: tariffClass, travelerType: travelerType, tariffReductions: tariffReductions)
    }
    
    public func encode(with coder: NSCoder) {
        coder.encode(tariffClass, forKey: PropertyKey.tariffClass)
        if let travelerType = travelerType {
            coder.encode(travelerType.rawValue, forKey: PropertyKey.travelerType)
        }
        coder.encode(tariffReductions, forKey: PropertyKey.tariffReduction)
    }
    
    struct PropertyKey {
        static let tariffClass = "tariffClass"
        static let travelerType = "travelerType"
        static let tariffReduction = "tariffReduction"
    }
}

/// Type of the traveler, depending on his/her age.
public enum TravelerType: Int {
    /// Default
    case adult
    /// For example, pensioner, 65+ years old (DB).
    case senior
    /// For example passengers aged 15-26 years old (DB).
    case youngAdult
    /// For example passengers aged 6-14 years old (DB).
    case child
    /// For example passengers aged 0-5 years old (DB).
    case youngChild
}

/// Object which reduces the displayed tariff rate, like for example a loyalty card.
public class TariffReduction: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool = true
    
    /// User-readable title.
    public let title: String
    /// 1 for first-class, 2 for second-class.
    public let tariffClass: Int?
    /// A uniquely identifiable code.
    public let code: Int
    
    init(title: String, tariffClass: Int?, code: Int) {
        self.title = title
        self.tariffClass = tariffClass
        self.code = code
    }
    
    public required convenience init?(coder: NSCoder) {
        guard let title = coder.decodeObject(of: NSString.self, forKey: PropertyKey.title) as String? else { return nil }
        let tariffClass = coder.containsValue(forKey: PropertyKey.tariffClass) ? coder.decodeInteger(forKey: PropertyKey.tariffClass) : nil
        let code = coder.decodeInteger(forKey: "code")
        self.init(title: title, tariffClass: tariffClass, code: code)
    }
    
    public func encode(with coder: NSCoder) {
        coder.encode(title, forKey: PropertyKey.title)
        coder.encode(tariffClass, forKey: PropertyKey.tariffClass)
        coder.encode(code, forKey: PropertyKey.code)
    }
    
    struct PropertyKey {
        static let title = "title"
        static let tariffClass = "tariffClass"
        static let code = "code"
    }
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
    public var tariffProfile: TariffProfile?
    
    public init(products: [Product]? = nil, optimize: Optimize? = nil, walkSpeed: WalkSpeed? = nil, accessibility: Accessibility? = nil, options: [Option]? = nil, maxChanges: Int? = nil, minChangeTime: Int? = nil, maxFootpathTime: Int? = nil, maxFootpathDist: Int? = nil, tariffProfile: TariffProfile? = nil) {
        self.products = products
        self.optimize = optimize
        self.walkSpeed = walkSpeed
        self.accessibility = accessibility
        self.options = options
        self.maxChanges = maxChanges
        self.minChangeTime = minChangeTime
        self.maxFootpathTime = maxFootpathTime
        self.maxFootpathDist = maxFootpathDist
        self.tariffProfile = tariffProfile
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
        let tariffProfile = aDecoder.decodeObject(of: TariffProfile.self, forKey: PropertyKey.tariffProfile)
        self.init(products: products, optimize: optimize, walkSpeed: walkSpeed, accessibility: accessibility, options: options, maxChanges: maxChanges, minChangeTime: minChangeTime, maxFootpathTime: maxFootpathTime, maxFootpathDist: maxFootpathDist, tariffProfile: tariffProfile)
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
        aCoder.encode(tariffProfile, forKey: PropertyKey.tariffProfile)
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
        static let tariffProfile = "tariffProfile"
    }
}

public enum QueryTrait: Int {
    case maxChanges, minChangeTime, maxFootpathTime, maxFootpathDist, tariffClass, tariffTravelerType, tariffReductions
}
