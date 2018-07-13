//
//  WebSocketManager.swift
//  Pods
//
//  Created by Cole Potrocky on 4/12/18.
//

import Marshal
import Starscream

class WebSocketManager: WebSocketDelegate, RequestManager {
  // The URL of the WebSocket server
  let url: URL
  private var extraRequestHeaders: [String: String]?
  // Pending requests that are queued to write once the socket connects
  private var pendingRequests: [String] = []
  // Pending responses that have not yet been fulfilled.
  private var pendingResponses: [RequestIDKey: (_ response: Any) -> Void] = [:]
  lazy var socket: WebSocket = {
    var request = URLRequest(url: url)
    extraRequestHeaders?.forEach { values in
      let (header, value) = values
      request.setValue(value, forHTTPHeaderField: header)
    }
    let webSocket = WebSocket(request: request)
    webSocket.delegate = self
    return webSocket
  }()

  init(for url: URL, extraRequestHeaders: [String: String]? = nil) {
    self.url = url
    self.extraRequestHeaders = extraRequestHeaders
  }

  // MARK: - RequestManager

  func queueRequest(
    _ key: RequestIDKey,
    request: String,
    callback: @escaping (_ response: Any) -> Void
  ) {
    pendingResponses[key] = callback

    // If the socket is connected, write right away.
    if socket.isConnected {
      socket.write(string: request)
      return
    }

    pendingRequests.append(request)
    socket.connect()
  }

  // MARK: - WebSocketDelegate

  func websocketDidConnect(socket: WebSocketClient) {
    for request in pendingRequests {
      socket.write(string: request)
    }
    pendingRequests = []
  }

  func websocketDidDisconnect(socket _: WebSocketClient, error: Error?) {
    pendingRequests = []
    for (_, callback) in pendingResponses {
      callback(error as Any)
    }
    pendingResponses = [:]
  }

  func websocketDidReceiveMessage(socket _: WebSocketClient, text: String) {
    guard let jsonAsData = text.data(using: .utf8),
      let unserialized = try? JSONSerialization.jsonObject(with: jsonAsData) else {
      return
    }

    var maybeIDKey: RequestIDKey?
    if let batchResponse = unserialized as? [[String: Any]] {
      maybeIDKey = try?.batch(batchResponse.map { try $0.value(for: "id") })
    } else if let singleResponse = unserialized as? [String: Any] {
      maybeIDKey = try?.single(singleResponse.value(for: "id"))
    }

    guard let idKey = maybeIDKey,
      let callback = pendingResponses[idKey] else {
      return
    }

    pendingResponses.removeValue(forKey: idKey)
    callback(unserialized)
  }

  func websocketDidReceiveData(socket _: WebSocketClient, data _: Data) {
  }
}
