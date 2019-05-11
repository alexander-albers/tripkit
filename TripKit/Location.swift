import Foundation
import CoreLocation

public class Location: NSObject, NSSecureCoding {
    
    private static let NON_UNIQUE_NAMES =  ["Hauptbahnhof", "Hbf", "Hbf.", "HB", "Bahnhof", "Bf", "Bf.", "Bhf", "Bhf.", "Busbahnhof", "Südbahnhof", "ZOB", "Schiffstation", "Schiffst.", "Zentrum", "Markt", "Dorf", "Kirche", "Nord", "Ost", "Süd", "West", "Airport", "Flughafen", "Talstation"]
    
    public static var supportsSecureCoding: Bool = true
    
    public let type: LocationType
    public let id: String?
    public let coord: LocationPoint?
    public let place: String?
    public let name: String?
    public let products: [Product]?
    
    lazy var distanceFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 2
        return numberFormatter
    }()
    
    public init?(type: LocationType, id: String?, coord: LocationPoint?, place: String?, name: String?, products: [Product]?) {
        if let id = id, id.isEmpty {
            return nil
        }
        if let _ = place, name == nil {
            return nil
        }
        if type == .any {
            if id != nil {
                return nil
            }
        } else if type == .coord && coord == nil {
            return nil
        }
        
        self.type = type
        self.id = id;
        self.coord = coord
        self.place = place
        self.name = name
        self.products = products
    }
    
    public init(id: String) {
        self.type = .station
        self.id = id
        self.coord = nil
        self.place = nil
        self.name = nil
        self.products = nil
    }
    
    public init(anyName: String?) {
        self.type = .any
        self.id = nil
        self.coord = nil
        self.place = nil
        self.name = anyName
        self.products = nil
    }
    
    public init(lat: Int, lon: Int) {
        self.type = .coord
        self.id = nil
        self.coord = LocationPoint(lat: lat, lon: lon)
        self.place = nil
        self.name = nil
        self.products = nil
    }
    
    convenience public init?(type: LocationType, id: String?, coord: LocationPoint?, place: String?, name: String?) {
        self.init(type: type, id: id, coord: coord, place: place, name: name, products: nil)
    }
    
    convenience public init?(type: LocationType, id: String) {
        self.init(type: type, id: id, coord: nil, place: nil, name: nil)
    }
    
    required convenience public init?(coder aDecoder: NSCoder) {
        guard let type = LocationType(rawValue: aDecoder.decodeInteger(forKey: PropertyKey.locationTypeKey)) else {
            print("Location type could not be decoded")
            return nil
        }
        
        let id = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.locationIdKey) as String?
        let coord: LocationPoint?
        if aDecoder.containsValue(forKey: PropertyKey.locationLatKey) && aDecoder.containsValue(forKey: PropertyKey.locationLonKey) {
            let lat = aDecoder.decodeInteger(forKey: PropertyKey.locationLatKey)
            let lon = aDecoder.decodeInteger(forKey: PropertyKey.locationLonKey)
            coord = LocationPoint(lat: lat, lon: lon)
        } else {
            coord = nil
        }
        let place = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.locationPlaceKey) as String?
        let name = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.locationNameKey) as String?
        
        self.init(type: type, id: id, coord: coord, place: place, name: name)
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(type.rawValue, forKey: PropertyKey.locationTypeKey)
        aCoder.encode(id, forKey: PropertyKey.locationIdKey)
        if let coord = coord {
            aCoder.encode(coord.lat, forKey: PropertyKey.locationLatKey)
            aCoder.encode(coord.lon, forKey: PropertyKey.locationLonKey)
        }
        aCoder.encode(place, forKey: PropertyKey.locationPlaceKey)
        aCoder.encode(name, forKey: PropertyKey.locationNameKey)
    }
    
    public func hasLocation() -> Bool {
        return coord != nil
    }
    
    public func hasName() -> Bool {
        return name != nil || place != nil
    }
    
    public func getUniqueShortName() -> String {
        if let place = self.place, !place.isEmpty, let name = self.name, !name.contains(place) && (Location.NON_UNIQUE_NAMES.contains(name) || name.split(separator: " ").first(where: {Location.NON_UNIQUE_NAMES.contains(String($0))}) != nil || name.split(separator: ",").first(where: {Location.NON_UNIQUE_NAMES.contains(String($0))}) != nil) {
            return place + ", " + name
        } else if let name = self.name {
            return name
        } else if let id = self.id, id != "" {
            return id
        } else if let coord = coord {
            return "\(Double(coord.lat) / 1e6):\(Double(coord.lon) / 1e6)"
        } else {
            return type.displayName
        }
    }
    
    public func getUniqueLongName() -> String {
        var result = ""
        if let name = name {
            result += name
        }
        if let place = place, !result.contains(place) {
            if !result.isEmpty {
                result += ", "
            }
            result += place
        }
        if result.isEmpty {
            if let coord = coord {
                result =  "\(Double(coord.lat) / 1e6):\(Double(coord.lon) / 1e6)"
            } else {
                result = type.displayName
            }
        }
        return result
    }
    
    public func getMultilineLabel() -> String {
        var result = ""
        if let place = place {
            result += place
        }
        if let name = name {
            if !result.isEmpty {
                result += "\n"
            }
            result += name
        }
        if result.isEmpty {
            if let coord = coord {
                result =  "\(Double(coord.lat) / 1e6):\(Double(coord.lon) / 1e6)"
            } else {
                result = type.displayName
            }
        }
        return result
    }
    
    public func getDistanceText(_ location: CLLocation) -> String {
        let distance = getDistance(from: location)
        if distance > 1000 {
            return "\(distanceFormatter.string(from: (distance / 1000) as NSNumber) ?? String(format: "%.2f", distance / 1000))\u{00a0}km"
        } else {
            return "\(Int(distance))\u{00a0}m"
        }
    }
    
    public func getDistance(from location: CLLocation) -> CLLocationDistance {
        let distance: CLLocationDistance
        if let coord = coord {
            distance = location.distance(from: CLLocation(latitude: Double(coord.lat) / 1000000.0, longitude: Double(coord.lon) / 1000000.0))
        } else {
            distance = 0
        }
        return distance
    }
    
    public func getTypeIconName() -> String {
        let iconName: String
        if type == .station {
            iconName = "stop"
        } else if type == .poi {
            iconName = "poi"
        } else {
            iconName = "location"
        }
        return iconName
    }
    
    public func isIdentified() -> Bool {
        if type == .station {
            return id != nil && id != ""
        }
        if type == .poi {
            return true
        }
        if type == .address || type == .coord {
            return hasLocation()
        }
        
        return false
    }
    
    override public var description: String {
        return getUniqueLongName()
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? Location else { return false }
        if self === other { return true }
        if self.type != other.type { return false }
        if let id = self.id {
            return id == other.id ?? ""
        }
        if coord != nil && other.coord != nil && coord == other.coord { return true }
        if self.place != other.place { return false }
        if self.name != other.name { return false }
        
        return true
    }
    
    public override var hash: Int {
        get {
            if let id = id {
                return id.hash
            } else {
                if let coord = coord {
                    return "\(coord.lat):\(coord.lon)".hashValue
                }
                return type.hashValue
            }
        }
    }
    
    struct PropertyKey {
        
        static let locationTypeKey = "type"
        static let locationIdKey = "id"
        static let locationLatKey = "lat"
        static let locationLonKey = "lon"
        static let locationPlaceKey = "place"
        static let locationNameKey = "name"
        
    }
    
    
}

public enum LocationType: Int {
    
    /** Location can represent any of the below. Mainly meant for user input. */
    case any,
    /** Location represents a station or stop. */
    station,
    /** Location represents a point of interest. */
    poi,
    /** Location represents a postal address. */
    address,
    /** Location represents a just a plain coordinate, e.g. acquired by GPS. */
    coord
    
    public static let ALL: [LocationType] = [.any, .station, .poi, .address, .coord]
    private static let stringValues: [LocationType: String] = [.any: "any", .station: "station", .poi: "poi", .address: "address", .coord: "coord"]
    
    public var stringValue: String {
        return LocationType.stringValues[self]!
    }
    
    public var displayName: String {
        switch self {
        case .any:
            return "Ort"
        case .station:
            return "Haltestelle"
        case .poi:
            return "Point Of Interest"
        case .address:
            return "Adresse"
        case .coord:
            return "Adresse"
        }
    }
    
    public static func from(string: String) -> LocationType? {
        return stringValues.first(where: {$1 == string})?.key
    }
    
}
