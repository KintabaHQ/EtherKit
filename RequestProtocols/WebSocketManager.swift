//
//  WebSocketManager.swift
//  Pods
//
//  Created by Cole Potrocky on 4/12/18.
//

import Starscream
import Marshal

class WebSocketManager: WebSocketDelegate, RequestManager {
  
  // The URL of the WebSocket server
  let url: URL
  // Pending requests that are queued to write once the socket connects
  private var pendingRequests: [String] = []
  // Pending responses that have not yet been fulfilled.
  private var pendingResponses: [RequestIDKey: (_ response: Any) -> Void] = [:]
  lazy var socket: WebSocket = {
    let webSocket = WebSocket(url: url)
    webSocket.delegate = self
    webSocket.connect()
    return webSocket
  }()
  
  init(for url: URL) {
    self.url = url
  }
  
  // MARK: - RequestManager
  
  func queueRequest(
    _ key: RequestIDKey,
    request: String,
    callback: @escaping (_ response: Any) -> Void
  ) {
    pendingResponses[key] = callback
    if !socket.isConnected {
      socket.connect()
    }
    pendingRequests.append(request)
  }
  
  // MARK: - WebSocketDelegate
  
  func websocketDidConnect(socket: WebSocketClient) {
    for request in pendingRequests {
      socket.write(string: request)
    }
    pendingRequests = []
  }
  
  func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
  }
  
  func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
    guard let jsonAsData = text.data(using: .utf8),
      let unserialized = try? JSONSerialization.jsonObject(with: jsonAsData) else {
      return
    }
    
    var maybeIDKey: RequestIDKey? = nil
    if let batchResponse = unserialized as? [[String: Any]] {
      maybeIDKey = try? .batch(batchResponse.map { try $0.value(for: "id") })
    } else if let singleResponse = unserialized as? [String: Any] {
      maybeIDKey = try? .single(try singleResponse.value(for: "id"))
    }
    
    guard let idKey = maybeIDKey,
      let callback = pendingResponses[idKey] else {
      return
    }
  
    pendingResponses.removeValue(forKey: idKey)
    callback(unserialized)
  }
  
  func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
  }
  
}

