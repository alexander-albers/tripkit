import Foundation
import os.log
import SwiftyJSON
import SWXMLHash

public class HttpClient {
    
    private static let DefaultUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_3) AppleWebKit/602.4.8 (KHTML, like Gecko) Version/10.0.3 Safari/602.4.8"
    
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
        if let cookieString = httpRequest.cookieString {
            urlRequest.setValue(cookieString, forHTTPHeaderField: "Cookie")
        }
        
        if let payload = httpRequest.postPayload {
            os_log("making http request to %{public}@: %{public}@", log: .requestLogger, type: .default, url.absoluteString, payload)
        } else {
            os_log("making http request to %{public}@", log: .requestLogger, type: .default, url.absoluteString)
        }
        let task = URLSession.shared.dataTask(with: urlRequest) { result in
            completion(result)
        }
        task.resume()
        
        return AsyncRequest(task: task)
    }
    
    public static func getJson(httpRequest: HttpRequest, completion: @escaping (Result<JSON, HttpError>) -> Void) -> AsyncRequest {
        return get(httpRequest: httpRequest) { result in
            switch result {
            case .success(_, let data):
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
            case .success(_, let data):
                let xml = SWXMLHash.parse(data)
                completion(.success(xml))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
}

public enum HttpError: Error {
    case invalidUrl(String?)
    case invalidStatusCode(Int)
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
                result(.failure(.invalidStatusCode(response.statusCode)))
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
    public var cookieString: String?
    public var userAgent: String?
    
    public init(urlBuilder: UrlBuilder) {
        self.urlBuilder = urlBuilder
    }
    
    public func setPostPayload(_ postPayload: String?) -> Self {
        self.postPayload = postPayload
        return self
    }
    
    public func setContentType(_ contentType: String?) -> Self {
        self.contentType = contentType
        return self
    }
    
    public func setCookieString(_ cookieString: String?) -> Self {
        self.cookieString = cookieString
        return self
    }
    
    public func setUserAgent(_ userAgent: String?) -> Self {
        self.userAgent = userAgent
        return self
    }
    
}

extension Data {
    
    func toJson(encoding: String.Encoding = .utf8) throws -> Any? {
        let encodedData: Data?
        if encoding == .utf8 {
            encodedData = self
        } else {
            let string = String(data: self, encoding: encoding)
            encodedData = string?.data(using: .utf8, allowLossyConversion: true)
        }
        if let encodedData = encodedData {
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
