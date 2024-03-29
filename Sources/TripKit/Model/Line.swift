import Foundation

public class Line: NSObject, NSSecureCoding {
    
    public static var supportsSecureCoding: Bool = true
    /// A unique id for this line.
    public let id: String?
    /// Operator if the line.
    public let network: String?
    /// Type of the line.
    public let product: Product?
    /// Short name of the line, should be used for displaying the line.
    ///
    /// Example: ICE42, RE42, S4, U4, 201
    public let label: String?
    /// Longer name of the line, including the number.
    public let name: String?
    /// Line number, not specific to a specific train but to a route.
    public let number: String?
    /// Contains the (internal) vehicle number of the line.
    public let vehicleNumber: String?
    /// Specifies the visual style of a line label.
    public let style: LineStyle!
    /// Attributes of this line, like bicycle carriage or wheelchair access.
    public let attr: [Attr]?
    /// Line specific notice.
    public let message: String?
    /// Outward or return direction.
    public let direction: Direction?
    
    static let FOOTWAY = Line(id: nil, network: nil, product: nil, label: nil)
    static let TRANSFER = Line(id: nil, network: nil, product: nil, label: nil)
    static let SECURE_CONNECTION = Line(id: nil, network: nil, product: nil, label: nil)
    static let DO_NOT_CHANGE = Line(id: nil, network: nil, product: nil, label: nil)
    
    public init(id: String?, network: String?, product: Product?, label: String?, name: String?, number: String? = nil, vehicleNumber: String? = nil, style: LineStyle!, attr: [Attr]?, message: String?, direction: Direction? = nil) {
        self.id = id
        self.network = network
        self.product = product
        self.label = label
        self.name = name
        self.number = number
        self.vehicleNumber = vehicleNumber
        self.style = style
        self.attr = attr
        self.message = message
        self.direction = direction
    }
    
    public convenience init(id: String?, network: String?, product: Product?, label: String?) {
        self.init(id: id, network: network, product: product, label: label, name: nil, style: nil, attr: nil, message: nil, direction: nil)
    }
    
    required convenience public init?(coder aDecoder: NSCoder) {
        let id = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.id) as String?
        let network = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.network) as String?
        let product = Product(rawValue: aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.product) as String? ?? "")
        let label = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.label) as String?
        let name = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.name) as String?
        let number = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.number) as String?
        let vehicleNumber = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.vehicleNumber) as String?
        let style = aDecoder.decodeObject(of: LineStyle.self, forKey: PropertyKey.style)
        var attr = [Attr]()
        if let arr = aDecoder.decodeObject(of: [NSNumber.self, NSArray.self], forKey: PropertyKey.attr) as? [Int] {
            for arrElem in arr {
                if let a = Attr(rawValue: arrElem) {
                    attr.append(a)
                }
            }
        }
        let message = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.message) as String?
        let direction: Direction?
        if aDecoder.containsValue(forKey: PropertyKey.direction) {
            let dir = aDecoder.decodeInteger(forKey: PropertyKey.direction)
            direction = Direction(rawValue: dir)
        } else {
            direction = nil
        }
        
        self.init(id: id, network: network, product: product, label: label, name: name, number: number, vehicleNumber: vehicleNumber, style: style, attr: attr, message: message, direction: direction)
    }
    
    public func encode(with aCoder: NSCoder) {
        if let id = id {
            aCoder.encode(id, forKey: PropertyKey.id)
        }
        if let network = network {
            aCoder.encode(network, forKey: PropertyKey.network)
        }
        if let product = product {
            aCoder.encode(product.rawValue, forKey: PropertyKey.product)
        }
        if let label = label {
            aCoder.encode(label, forKey: PropertyKey.label)
        }
        if let name = name {
            aCoder.encode(name, forKey: PropertyKey.name)
        }
        if let number = number {
            aCoder.encode(number, forKey: PropertyKey.number)
        }
        if let vehicleNumber = vehicleNumber {
            aCoder.encode(vehicleNumber, forKey: PropertyKey.vehicleNumber)
        }
        if let style = style {
            aCoder.encode(style, forKey: PropertyKey.style)
        }
        if let attr = attr {
            var intArr = [Int]()
            for attrElem in attr {
                intArr.append(attrElem.rawValue)
            }
            aCoder.encode(intArr, forKey: PropertyKey.attr)
        }
        if let message = message {
            aCoder.encode(message, forKey: PropertyKey.message)
        }
        if let direction = direction {
            aCoder.encode(direction.rawValue, forKey: PropertyKey.direction)
        }
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? Line else { return false }
        return object.product == product && object.label == label
    }
    
    public override var hash: Int {
        return "\(product?.rawValue ?? ""):\(label ?? ""):\(network ?? "")".hash
    }
    
    public override var description: String {
        return "Line id=\(id ?? ""), network=\(network ?? ""), product=\(product?.rawValue ?? ""), label=\(label ?? ""), name=\(name ?? ""), vehicleNumber=\(vehicleNumber ?? "")"
    }
    
    public enum Attr: Int {
        case circleClockwise, circleAnticlockwise, serviceReplacement, lineAirport, wheelChairAccess, bicycleCarriage, wifiAvailable, restaurant, powerSockets, airConditioned
    }
    
    public enum Direction: Int {
        case outward, `return`
    }
    
    struct PropertyKey {
        
        static let id = "id"
        static let network = "network"
        static let product = "product"
        static let label = "label"
        static let name = "name"
        static let number = "number"
        static let vehicleNumber = "vehicleNumber"
        static let style = "style"
        static let attr = "attr"
        static let message = "message"
        static let direction = "direction"
        
    }
    
}
