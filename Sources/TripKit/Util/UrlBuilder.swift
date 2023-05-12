import Foundation
import os.log

public class UrlBuilder: CustomStringConvertible {
    
    private var path: String?
    private var encoding: String.Encoding?
    private var queryItems: [QueryItem] = []
    private var anchorHash: String?
    
    public init(path: String? = nil, encoding: String.Encoding? = nil) {
        self.path = path
        self.encoding = encoding
    }
    
    public func setPath(path: String?) {
        self.path = path
    }
    
    public func getPath() -> String? {
        return path
    }
    
    public func setEncoding(encoding: String.Encoding?) {
        self.encoding = encoding
    }
    
    public func setAnchorHash(anchorHash: String?) {
        self.anchorHash = anchorHash
    }
    
    public func addParameter(key: String, value: Any?) {
        queryItems.append(QueryItem(key: key, value: value == nil ? nil : String(describing: value!)))
    }
    
    public func insertParameter(key: String, value: Any?, at index: Int) {
        queryItems.insert(QueryItem(key: key, value: value == nil ? nil : String(describing: value!)), at: index)
    }
    
    public func setParameter(key: String, value: Any?) {
        if let index = queryItems.firstIndex(where: {$0.key == key}) {
            var item = queryItems.remove(at: index)
            item.value = value == nil ? nil : String(describing: value!)
            queryItems.append(item)
        } else {
            queryItems.append(QueryItem(key: key, value: value == nil ? nil : String(describing: value!)))
        }
    }
    
    public func removeParameter(key: String) {
        if let index = queryItems.firstIndex(where: {$0.key == key}) {
            queryItems.remove(at: index)
        }
    }
    
    public func build() -> URL? {
        guard let path = path else {
            return nil
        }
        guard var urlComponents = URLComponents(string: path) else {
            return nil
        }
        let queryItems = self.queryItems
        if let items = urlComponents.queryItems {
            for item in items {
                insertParameter(key: item.name, value: item.value, at: 0)
            }
        }
        let query = createParameterList()
        self.queryItems = queryItems
        if !query.isEmpty {
            urlComponents.percentEncodedQuery = query
        } else {
            urlComponents.percentEncodedQuery = nil
        }
        if let anchorHash = anchorHash {
            urlComponents.fragment = anchorHash
        }
        
        return urlComponents.url
    }
    
    public func createParameterList() -> String {
        var result = ""
        for queryItem in queryItems {
            guard let encodedKey = queryItem.key.encodeUrl(using: encoding ?? .utf8) else {
                os_log("Failed to append query parameter: key=%{public}@", log: .requestLogger, type: .error, queryItem.key)
                continue
            }
            if !result.isEmpty {
                result += "&"
            }
            result += encodedKey + "="
            if let encodedValue = queryItem.value?.encodeUrl(using: encoding ?? .utf8) {
                result += encodedValue
            }
        }
        return result
    }
    
    public var description: String {
        var result = ""
        let parameters = createParameterList()
        if !parameters.isEmpty {
            result += "?" + parameters
        }
        if let path = path {
            result = path + result
        }
        if let anchorHash = anchorHash {
            result += "#" + anchorHash
        }
        return result
    }
}

fileprivate struct QueryItem {
    
    let key: String
    var value: String?
    
}
