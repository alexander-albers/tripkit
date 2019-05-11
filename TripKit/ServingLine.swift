import Foundation

public class ServingLine: NSObject, NSCoding {
    
    public let line: Line
    public let destination: Location?
    
    public init(line: Line, destination: Location?) {
        self.line = line
        self.destination = destination
    }
    
    public required convenience init?(coder aDecoder: NSCoder) {
        guard let line = aDecoder.decodeObject(of: Line.self, forKey: PropertyKey.lineKey) as Line? else { return nil }
        let destination = aDecoder.decodeObject(of: Location.self, forKey: PropertyKey.destinationKey) as Location?
        self.init(line: line, destination: destination)
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(line, forKey: PropertyKey.lineKey)
        if let destination = destination {
            aCoder.encode(destination, forKey: PropertyKey.destinationKey)
        }
    }
    
    override public func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? LineDestination else { return false }
        if object.line != line { return false }
        
        return destination?.getUniqueShortName() == object.destination?.getUniqueShortName()
    }
    
    override public var hash: Int {
        if let destination = destination {
            return line.hash + destination.getUniqueShortName().hash
        } else {
            return line.hash
        }
    }
    
    struct PropertyKey {
        
        static let lineKey = "line"
        static let destinationKey = "destination"
        
    }
    
}
