//
//  RequestManager.swift
//  EtherKit
//
//  Created by Cole Potrocky on 4/19/18.
//

public enum RequestIDKey: Hashable {
  public var hashValue: Int {
    switch self {
    case let .batch(ids):
      return ids.compactMap { $0?.hashValue }.reduce(0) { $0 ^ $1 }
    case let .single(id):
      return id?.hashValue ?? 0
    }
  }

  case batch([String?])
  case single(String?)
}

public protocol RequestManager: class {
  var url: URL { get }

  func queueRequest(
    _ key: RequestIDKey,
    request: String,
    callback: @escaping (_ response: Any) -> Void
  )

  func queueRequest(
    _ key: RequestIDKey,
    request: Data,
    callback: @escaping (_ response: Any) -> Void
  )
}

extension RequestManager {
  func queueRequest(
    _ key: RequestIDKey,
    request: Data,
    callback: @escaping (_ response: Any) -> Void
  ) {
    guard let dataAsString = String(data: request, encoding: .utf8) else {
      return
    }
    queueRequest(key, request: dataAsString, callback: callback)
  }
}
