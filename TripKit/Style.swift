import Foundation

public class LineStyle: NSObject, NSSecureCoding {
    
    public static var supportsSecureCoding: Bool = true
    
    public let shape: Shape!
    public let backgroundColor, backgroundColor2: UInt32!
    public let foregroundColor: UInt32!
    public let borderColor: UInt32!
    
    public init(shape: Shape, backgroundColor: UInt32, backgroundColor2: UInt32, foregroundColor: UInt32, borderColor: UInt32) {
        self.shape = shape
        self.backgroundColor = backgroundColor
        self.backgroundColor2 = backgroundColor2
        self.foregroundColor = foregroundColor
        self.borderColor = borderColor
    }
    
    public convenience init(backgroundColor: UInt32, foregroundColor: UInt32) {
        self.init(shape: Shape.rounded, backgroundColor: backgroundColor, backgroundColor2: 0, foregroundColor: foregroundColor, borderColor: 0)
    }
    
    public convenience init(backgroundColor: UInt32, foregroundColor: UInt32, borderColor: UInt32) {
        self.init(shape: .rounded, backgroundColor: backgroundColor, backgroundColor2: 0, foregroundColor: foregroundColor, borderColor: borderColor)
    }
    
    public convenience init(shape: Shape, backgroundColor: UInt32, foregroundColor: UInt32) {
        self.init(shape: shape, backgroundColor: backgroundColor, backgroundColor2: 0, foregroundColor: foregroundColor, borderColor: 0)
    }
    
    public convenience init(shape: Shape, backgroundColor: UInt32, foregroundColor: UInt32, borderColor: UInt32) {
        self.init(shape: shape, backgroundColor: backgroundColor, backgroundColor2: 0, foregroundColor: foregroundColor, borderColor: borderColor)
    }
    
    required convenience public init?(coder aDecoder: NSCoder) {
        guard let shape = Shape(rawValue: aDecoder.decodeInteger(forKey: PropertyKey.shape)) else {
            print("Could not decode style!")
            return nil
        }
        let backgroundColor = aDecoder.decodeObject(forKey: PropertyKey.backgroundColor) as! UInt32
        let backgroundColor2 = aDecoder.decodeObject(forKey: PropertyKey.backgroundColor2) as! UInt32
        let foregroundColor = aDecoder.decodeObject(forKey: PropertyKey.foregroundColor) as! UInt32
        let borderColor = aDecoder.decodeObject(forKey: PropertyKey.borderColor) as! UInt32
        
        self.init(shape: shape, backgroundColor: backgroundColor, backgroundColor2: backgroundColor2, foregroundColor: foregroundColor, borderColor: borderColor)
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(shape.rawValue, forKey: PropertyKey.shape)
        aCoder.encode(backgroundColor, forKey: PropertyKey.backgroundColor)
        aCoder.encode(backgroundColor2, forKey: PropertyKey.backgroundColor2)
        aCoder.encode(foregroundColor, forKey: PropertyKey.foregroundColor)
        aCoder.encode(borderColor, forKey: PropertyKey.borderColor)
    }
    
    struct PropertyKey {
        
        static let shape = "shape"
        static let backgroundColor = "backgroundColor"
        static let backgroundColor2 = "backgroundColor2"
        static let foregroundColor = "foregroundColor"
        static let borderColor = "borderColor"
        
    }
    
    public static let black: UInt32 = 0xFF000000
    public static let darkGray: UInt32 = 0xFF444444
    public static let gray: UInt32 = 0xFF888888
    public static let white: UInt32 = 0xFFFFFFFF
    public static let red: UInt32 = 0xFFFF0000
    public static let green: UInt32 = 0xFF00FF00
    public static let blue: UInt32 = 0xFF0000FF
    public static let yellow: UInt32 = 0xFFFFFF00
    public static let transparent: UInt32 = 0
    
    public static func parseColor(_ colorStr: String) -> UInt32 {
        guard var color = UInt32(String(colorStr.dropFirst()), radix: 16) else { return 0 }
        if (colorStr.count == 7) {
            color |= 0xff000000 as UInt32
        }
        return color
    }
    
    public static func rgb(_ r: UInt32, _ g: UInt32, _ b: UInt32) -> UInt32 {
        return (0xFF << 24) | (r << 16) | (g << 8) | b
    }
    
}

public enum Shape: Int {
    case rect, rounded, circle
}

public extension UIColor {
    
    convenience init(argb: UInt32) {
        self.init(red: CGFloat(Double((argb >> 16) & 0xff) / 255.0), green: CGFloat(Double((argb >> 8) & 0xff) / 255.0), blue: CGFloat(Double(argb & 0xff) / 255.0), alpha: CGFloat(Double((argb >> 24) & 0xff) / 255.0))
    }
    
}

