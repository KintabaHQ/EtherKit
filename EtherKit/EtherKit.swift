//
//  EtherKit.swift
//  Pods
//
//  Created by Cole Potrocky on 4/12/18.
//

public enum ConnectionMode {
  case websocket
  case http
}

public final class EtherKit {
  private let connectionMode: ConnectionMode
  private let url: URL

  private lazy var manager: RequestManager = {
    switch connectionMode {
    case .http:
      return URLRequestManager(for: url)
    case .websocket:
      return WebSocketManager(for: url)
    }
  }()

  public init(_ url: URL, connectionMode: ConnectionMode) {
    self.url = url
    self.connectionMode = connectionMode
  }

  public func balanceOf(_ address: Address, blockNumber: BlockNumber = .latest) -> GetBalanceRequest {
    return GetBalanceRequest(GetBalanceRequest.Parameters(address: address, blockNumber: blockNumber))
  }

  public func request<T: Request>(_ request: T, completion: @escaping (T.Result) -> Void) throws {
    guard let requestAsDatum = try? JSONSerialization.data(withJSONObject: [request.marshaled()]) else {
      return
    }

    manager.queueRequest(
      .single(request.id),
      request: requestAsDatum
    ) { response in
      guard let result = try? request.response(from: response) else {
        return
      }
      completion(result)
    }
  }

  public func request<T1: Request, T2: Request>(
    _ request1: T1,
    _ request2: T2,
    completion: @escaping (T1.Result, T2.Result) -> Void
  ) throws {
    guard let requestsAsData = try? JSONSerialization.data(
      withJSONObject: [request1.marshaled(), request2.marshaled()]
    ) else {
      return
    }

    manager.queueRequest(
      .batch([request1.id, request2.id]),
      request: requestsAsData
    ) { responses in
      guard let responses = responses as? [Any] else {
        return
      }

      let result1 = responses.compactMap { try? request1.response(from: $0) }.first
      let result2 = responses.compactMap { try? request2.response(from: $0) }.first
      guard result1 != nil && result2 != nil else {
        return
      }
      completion(result1!, result2!)
    }
  }

  public func request<T1: Request, T2: Request, T3: Request>(
    _ request1: T1,
    _ request2: T2,
    _ request3: T3,
    completion: @escaping (T1.Result, T2.Result, T3.Result) -> Void
  ) throws {
    guard let requestsAsData = try? JSONSerialization.data(
      withJSONObject: [request1.marshaled(), request2.marshaled(), request3.marshaled()]
    ) else {
      return
    }

    manager.queueRequest(
      .batch([request1.id, request2.id, request3.id]),
      request: requestsAsData
    ) { responses in
      guard let responses = responses as? [Any]
      else {
        return
      }
      let result1 = responses.compactMap { try? request1.response(from: $0) }.first
      let result2 = responses.compactMap { try? request2.response(from: $0) }.first
      let result3 = responses.compactMap { try? request3.response(from: $0) }.first
      guard result1 != nil && result2 != nil && result3 != nil else {
        return
      }
      completion(result1!, result2!, result3!)
    }
  }
}
