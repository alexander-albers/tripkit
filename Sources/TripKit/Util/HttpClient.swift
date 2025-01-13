import Foundation
import os.log
import SwiftyJSON
import SWXMLHash

public class HttpClient: NSObject {
    
    private static var shared = HttpClient()
    private static let DefaultUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_3) AppleWebKit/602.4.8 (KHTML, like Gecko) Version/10.0.3 Safari/602.4.8"
    
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        if #available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, *) {
            config.waitsForConnectivity = true
        }
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()
    private var clientIdentityCache: [String: SecIdentity] = [:]
    private var clientRootCache: [String: SecCertificate] = [:]
    
    public static func get(httpRequest: HttpRequest, completion: @escaping (Result<(HTTPURLResponse, Data), HttpError>) -> Void) -> AsyncRequest {
        guard let url = httpRequest.urlBuilder.build() else {
            os_log("Failed to parse http url %{public}@", log: .requestLogger, type: .error, httpRequest.urlBuilder.getPath() ?? "<unknown>")
            completion(.failure(.invalidUrl(httpRequest.urlBuilder.getPath())))
            return AsyncRequest(task: nil)
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.setValue(httpRequest.userAgent ?? DefaultUserAgent, forHTTPHeaderField: "User-Agent")
        
        if let payload = httpRequest.postPayload {
            urlRequest.httpMethod = "POST"
            urlRequest.setValue(httpRequest.contentType ?? "application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = payload.data(using: .utf8) // TODO: don't hardcode encoding
        }
        
        for (header, value) in httpRequest.headers ?? [:] {
            urlRequest.setValue(value, forHTTPHeaderField: header)
        }
        
        if let payload = httpRequest.postPayload {
            os_log("making http request to %{public}@: %{public}@", log: .requestLogger, type: .default, url.absoluteString, payload.replacingOccurrences(of: "\"auth\":\\s*(\\{[^}]*\\})", with: "\"auth\":<private>", options: .regularExpression))
        } else {
            os_log("making http request to %{public}@", log: .requestLogger, type: .default, url.absoluteString)
        }
        let task = shared.urlSession.dataTask(with: urlRequest) { result in
            completion(result)
        }
        task.resume()
        
        return AsyncRequest(task: task)
    }
    
    public static func getJson(httpRequest: HttpRequest, completion: @escaping (Result<JSON, HttpError>) -> Void) -> AsyncRequest {
        return get(httpRequest: httpRequest) { result in
            switch result {
            case .success((_, let data)):
                do {
                    let json = try JSON(data: data)
                    completion(.success(json))
                } catch let err {
                    os_log("failed to parse json from http response: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                    completion(.failure(.parseError))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public static func getXml(httpRequest: HttpRequest, completion: @escaping (Result<XMLIndexer, HttpError>) -> Void) -> AsyncRequest {
        return get(httpRequest: httpRequest) { result in
            switch result {
            case .success((_, let data)):
                let xml = XMLHash.parse(data)
                completion(.success(xml))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
}

extension HttpClient: URLSessionDelegate {
    public static func cacheIdentity(for host: String, identity: SecIdentity) {
        shared.clientIdentityCache[host] = identity
    }
    
    public static func cacheRootCertificate(for host: String, certificate: SecCertificate) {
        shared.clientRootCache[host] = certificate
    }
    
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        switch (challenge.protectionSpace.authenticationMethod) {
        case NSURLAuthenticationMethodClientCertificate:
            if let identity = clientIdentityCache[challenge.protectionSpace.host] {
                completionHandler(.useCredential, URLCredential(identity: identity, certificates: nil, persistence: .forSession))
            } else {
                completionHandler(.performDefaultHandling, nil)
            }
        case NSURLAuthenticationMethodServerTrust:
            if let rootCert = clientRootCache[challenge.protectionSpace.host], let trust = challenge.protectionSpace.serverTrust {
                if trust.evaluateAllowing(rootCertificates: [rootCert]) {
                    completionHandler(.useCredential, URLCredential(trust: trust))
                } else {
                    completionHandler(.cancelAuthenticationChallenge, nil)
                }
            } else {
                completionHandler(.performDefaultHandling, nil)
            }
        default:
            completionHandler(.performDefaultHandling, nil)
        }
    }
}


public enum HttpError: Error {
    case invalidUrl(String?)
    case invalidStatusCode(Int, Data)
    case networkError(Error)
    case parseError
}

extension URLSession {
    func dataTask(with urlRequest: URLRequest, result: @escaping (Result<(HTTPURLResponse, Data), HttpError>) -> Void) -> URLSessionDataTask {
        return dataTask(with: urlRequest) { (data, response, err) in
            if let err = err {
                os_log("failed to execute http request: %{public}@", log: .requestLogger, type: .error, String(describing: err))
                    result(.failure(.networkError(err)))
                return
            }
            guard let response = response as? HTTPURLResponse, let data = data else {
                os_log("failed to parse http response", log: .requestLogger, type: .error)
                result(.failure(.parseError))
                return
            }
            guard response.statusCode / 100 == 2 else {
                os_log("got invalid http status code %d", log: .requestLogger, type: .error, response.statusCode)
                result(.failure(.invalidStatusCode(response.statusCode, data)))
                return
            }
            result(.success((response, data)))
        }
    }
}

public class HttpRequest {
    public let urlBuilder: UrlBuilder
    public var postPayload: String?
    public var contentType: String?
    public var userAgent: String?
    public var headers: [String: String]?
    /// the response to this request
    public var responseData: Data?
    
    public init(urlBuilder: UrlBuilder) {
        self.urlBuilder = urlBuilder
    }
    
    @discardableResult
    public func setPostPayload(_ postPayload: String?) -> Self {
        self.postPayload = postPayload
        return self
    }
    
    @discardableResult
    public func setContentType(_ contentType: String?) -> Self {
        self.contentType = contentType
        return self
    }
    
    @discardableResult
    public func setUserAgent(_ userAgent: String?) -> Self {
        self.userAgent = userAgent
        return self
    }
    
    @discardableResult
    public func setHeaders(_ headers: [String: String]?) -> Self {
        self.headers = headers
        return self
    }
    
}

extension Data {
    
    func encodedData(encoding: String.Encoding) -> Data? {
        let encodedData: Data?
        if encoding == .utf8 {
            encodedData = self
        } else {
            let string = String(data: self, encoding: encoding)
            encodedData = string?.data(using: .utf8, allowLossyConversion: true)
        }
        return encodedData
    }
    
    func toJson(encoding: String.Encoding = .utf8) throws -> Any? {
        if let encodedData = encodedData(encoding: encoding) {
            return try JSONSerialization.jsonObject(with: encodedData, options: .allowFragments)
        } else {
            return nil
        }
    }
    
}

extension String {
    
    public func decodeUrl(using encoding: String.Encoding) -> String? {
        return (self as NSString).replacingPercentEscapes(using: encoding.rawValue)
    }
    
    public func encodeUrl(using encoding: String.Encoding) -> String? {
        return (self as NSString).addingPercentEscapes(using: encoding.rawValue)
    }
    
}
