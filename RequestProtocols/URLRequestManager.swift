//
//  URLRequestManager.swift
//  EtherKit
//
//  Created by Cole Potrocky on 4/19/18.
//

final class URLRequestManager: RequestManager {
  let url: URL
  
  private var pendingRequests = [RequestIDKey:URLSessionDataTask]()

  init(for url: URL) {
    self.url = url
  }
  
  func queueRequest(_ key: RequestIDKey, request: String, callback: @escaping (Any) -> Void) {
    pendingRequests[key]?.cancel()
    pendingRequests.removeValue(forKey: key)
    
    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.httpBody = request.data(using: .utf8)
    
    let session = URLSession(configuration: .default)
    let dataTask = session.dataTask(with: urlRequest) { data, response, error in
      guard error == nil,
        let data = data,
        let unserialized = try? JSONSerialization.jsonObject(with: data) else {
        return
      }
      
      callback(unserialized)
    }
    pendingRequests[key] = dataTask
    pendingRequests[key]?.resume()
  }
  
}
