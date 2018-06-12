//
//  URLRequestManager.swift
//  EtherKit
//
//  Created by Cole Potrocky on 4/19/18.
//

final class URLRequestManager: RequestManager {
  let url: URL

  private var pendingRequests = [RequestIDKey: URLSessionDataTask]()
  private var extraRequestHeaders: [String: String]?

  init(for url: URL, extraRequestHeaders: [String: String]? = nil) {
    self.url = url
    self.extraRequestHeaders = extraRequestHeaders
  }

  func queueRequest(_ key: RequestIDKey, request: String, callback: @escaping (Any) -> Void) {
    pendingRequests[key]?.cancel()
    pendingRequests.removeValue(forKey: key)

    var urlRequest = URLRequest(url: url)
    extraRequestHeaders?.forEach { header, value in urlRequest.setValue(value, forHTTPHeaderField: header) }

    urlRequest.httpMethod = "POST"
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    urlRequest.httpBody = request.data(using: .utf8)

    let session = URLSession(configuration: .default)
    let dataTask = session.dataTask(with: urlRequest) { data, _, error in
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
