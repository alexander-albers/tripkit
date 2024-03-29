import Foundation
import os.log

/// Specifies the visual style of a line label.
public class LineStyle: NSObject, NSSecureCoding {
    
    public static var supportsSecureCoding: Bool = true
    
    /// The shape of the background.
    public let shape: Shape!
    /// The color of the background.
    public let backgroundColor, backgroundColor2: UInt32!
    /// The color of the foreground, i.e. of the line label text.
    public let foregroundColor: UInt32!
    /// The color of the border of the shape.
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
            os_log("failed to decode line style", log: .default, type: .error)
            return nil
        }
        let backgroundColor = aDecoder.decodeObject(of: NSNumber.self, forKey: PropertyKey.backgroundColor) as! UInt32
        let backgroundColor2 = aDecoder.decodeObject(of: NSNumber.self, forKey: PropertyKey.backgroundColor2) as! UInt32
        let foregroundColor = aDecoder.decodeObject(of: NSNumber.self, forKey: PropertyKey.foregroundColor) as! UInt32
        let borderColor = aDecoder.decodeObject(of: NSNumber.self, forKey: PropertyKey.borderColor) as! UInt32
        
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

#if canImport(UIKit)
import UIKit
public extension UIColor {
    
    var argb: UInt32 {
        guard let components = self.cgColor.components else { return 0 }
        let red, green, blue, alpha: UInt32
        if components.count == 2 {
            red = UInt32(Double(components[0]) * 255.0)
            green = UInt32(Double(components[0]) * 255.0)
            blue = UInt32(Double(components[0]) * 255.0)
            alpha = UInt32(Double(components[1]) * 255.0)
        } else if components.count == 4 {
            red = UInt32(Double(components[0]) * 255.0)
            green = UInt32(Double(components[1]) * 255.0)
            blue = UInt32(Double(components[2]) * 255.0)
            alpha = UInt32(Double(components[3]) * 255.0)
        } else {
            return 0
        }
        return (alpha << 24) + (red << 16) + (green << 8) + blue
    }
    
    convenience init(argb: UInt32) {
        self.init(
            red: CGFloat((argb >> 16) & UInt32(0xff)) / CGFloat(0xff),
            green: CGFloat((argb >> 8) & UInt32(0xff)) / CGFloat(0xff),
            blue: CGFloat(argb & UInt32(0xff)) / CGFloat(0xff),
            alpha: CGFloat((argb >> 24) & UInt32(0xff)) / CGFloat(0xff)
        )
    }
    
}
#endif
