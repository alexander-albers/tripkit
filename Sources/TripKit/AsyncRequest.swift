import Foundation

public class AsyncRequest {
    
    let task: URLSessionTask?
    
    public init(task: URLSessionTask?) {
        self.task = task
    }
    
    public func cancel() {
        task?.cancel()
    }
    
}
