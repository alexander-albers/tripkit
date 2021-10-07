import Foundation

public class Fare: NSObject, NSSecureCoding {
    
    public static var supportsSecureCoding: Bool = true
    
    public let name: String?
    public let type: FareType
    public let currency: String
    public let fare: Float
    public let unitsName: String?
    public let units: String?
    
    init(name: String?, type: FareType, currency: String, fare: Float, unitsName: String?, units: String?) {
        self.name = name
        self.type = type
        self.currency = currency
        self.fare = fare
        self.unitsName = unitsName
        self.units = units
    }
    
    required public convenience init?(coder aDecoder: NSCoder) {
        guard let type = FareType(rawValue: aDecoder.decodeInteger(forKey: PropertyKey.type)), let currency = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.currency) as String? else { return nil }
        
        let name = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.name) as String?
        let fare = aDecoder.decodeFloat(forKey: PropertyKey.fare)
        let unitsName = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.unitsName) as String?
        let units = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.units) as String?
        
        self.init(name: name, type: type, currency: currency, fare: fare, unitsName: unitsName, units: units)
    }
    
    public func encode(with aCoder: NSCoder) {
        if let name = name {
            aCoder.encode(name, forKey: PropertyKey.name)
        }
        aCoder.encode(type.rawValue, forKey: PropertyKey.type)
        aCoder.encode(currency, forKey: PropertyKey.currency)
        aCoder.encode(fare, forKey: PropertyKey.fare)
        if let unitsName = unitsName {
            aCoder.encode(unitsName, forKey: PropertyKey.unitsName)
        }
        if let units = units {
            aCoder.encode(units, forKey: PropertyKey.units)
        }
    }
    
    public enum FareType: Int {
        case adult, child, bike, student
    }
    
    struct PropertyKey {
        
        static let name = "network"
        static let type = "type"
        static let currency = "currency"
        static let fare = "fare"
        static let unitsName = "units_name"
        static let units = "units"
        
    }
    
}
