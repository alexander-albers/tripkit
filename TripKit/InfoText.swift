import Foundation

public class InfoText: NSObject, NSSecureCoding {
    
    public static var supportsSecureCoding: Bool = true
    
    public let text: String
    public let url: String
    
    init(text: String, url: String) {
        self.text = text
        self.url = url
    }
    
    public required convenience init?(coder aDecoder: NSCoder) {
        guard let text = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.text) as String?, let url = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.url) as String? else { return nil }
        self.init(text: text, url: url)
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(text, forKey: PropertyKey.text)
        aCoder.encode(url, forKey: PropertyKey.url)
    }
    
    struct PropertyKey {
        static let text = "text"
        static let url = "url"
    }
    
}
