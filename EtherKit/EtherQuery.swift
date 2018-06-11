//
//  EtherQuery.swift
//  EtherKit
//
//  Created by Cole Potrocky on 6/8/18.
//

import Foundation
import Result
import Marshal

public final class EtherQuery {
  public enum ConnectionMode {
    case websocket
    case http
  }

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
  
  // MARK: JSONRPC Request Implementations
  
  public func networkVersion() -> NetVersionRequest {
    return NetVersionRequest()
  }
  
  public func balanceOf(_ address: Address, blockNumber: BlockNumber = .latest) -> GetBalanceRequest {
    return GetBalanceRequest(GetBalanceRequest.Parameters(address: address, blockNumber: blockNumber))
  }
  
  public func transactionCount(_ address: Address, blockNumber: BlockNumber = .latest) -> GetTransactionCountRequest {
    return GetTransactionCountRequest(GetTransactionCountRequest.Parameters(address: address, blockNumber: blockNumber))
  }
  
  public func blockNumber() -> BlockNumberRequest {
    return BlockNumberRequest()
  }
  
  public func gasPrice() -> GasPriceRequest {
    return GasPriceRequest()
  }
  
  // MARK: Request Dispatchers
  
  public func request<T: Request>(
    _ request: T,
    completion: @escaping (Result<T.Result, EtherKitError>) -> Void
  ) {
    guard let requestAsDatum = try? JSONSerialization.data(withJSONObject: request.marshaled()) else {
      completion(.failure(EtherKitError.jsonRPCFailed(reason: .invalidRequestJSON)))
      return
    }
    
    manager.queueRequest(
      .single(request.id),
      request: requestAsDatum
    ) { response in
      do {
        completion(.success(try request.response(from: response)))
      } catch let error as EtherKitError {
        completion(.failure(error))
      } catch {
        completion(.failure(.unknown(error: error)))
      }
    }
  }
  
  public func request<T1: Request, T2: Request>(
    _ request1: T1,
    _ request2: T2,
    completion: @escaping (Result<(T1.Result, T2.Result), EtherKitError>) -> Void
  ) {
    guard let requestsAsData = try? JSONSerialization.data(
      withJSONObject: [request1.marshaled(), request2.marshaled()]
      ) else {
        completion(.failure(.jsonRPCFailed(reason: .invalidRequestJSON)))
        return
    }
    
    manager.queueRequest(
      .batch([request1.id, request2.id]),
      request: requestsAsData
    ) { response in
      guard let responses = response as? [Any] else {
        let marshalError = MarshalError.typeMismatch(expected: [Any].self, actual: type(of: response))
        completion(.failure(.jsonRPCFailed(reason: .parseError(error: marshalError))))
        return
      }
      
      let result1 = responses.compactMap { try? request1.response(from: $0) }.first
      let result2 = responses.compactMap { try? request2.response(from: $0) }.first
      guard result1 != nil && result2 != nil else {
        completion(.failure(.jsonRPCFailed(reason: .unknown)))
        return
      }
      completion(.success((result1!, result2!)))
    }
  }
  
  public func request<T1: Request, T2: Request, T3: Request>(
    _ request1: T1,
    _ request2: T2,
    _ request3: T3,
    completion: @escaping (Result<(T1.Result, T2.Result, T3.Result), EtherKitError>) -> Void
  ) {
    guard let requestsAsData = try? JSONSerialization.data(
      withJSONObject: [request1.marshaled(), request2.marshaled(), request3.marshaled()]
      ) else {
        completion(.failure(.jsonRPCFailed(reason: .invalidRequestJSON)))
        return
    }
    
    manager.queueRequest(
      .batch([request1.id, request2.id, request3.id]),
      request: requestsAsData
    ) { response in
      guard let responses = response as? [Any] else {
        let marshalError = MarshalError.typeMismatch(expected: [Any].self, actual: type(of: response))
        completion(.failure(.jsonRPCFailed(reason: .parseError(error: marshalError))))
        return
      }
      
      let result1 = responses.compactMap { try? request1.response(from: $0) }.first
      let result2 = responses.compactMap { try? request2.response(from: $0) }.first
      let result3 = responses.compactMap { try? request3.response(from: $0) }.first
      guard result1 != nil && result2 != nil && result3 != nil else {
        completion(.failure(EtherKitError.jsonRPCFailed(reason: .unknown)))
        return
      }
      completion(.success((result1!, result2!, result3!)))
    }
  }
  
  // MARK: Mutative Requests
  
  public func send(
    using manager: EtherKeyManager,
    from: Address,
    to: Address,
    value: UInt256,
    data: GeneralData? = nil,
    completion: @escaping (Result<Hash, EtherKitError>) -> Void
  ) {
    request(
      networkVersion(),
      transactionCount(from, blockNumber: .pending),
      self.gasPrice()
    ) { result in
      switch result {
      case let .failure(error):
        completion(.failure(error))
      case let .success(items):
        let (network, nonce, networkGasPrice) = items

        let transaction = SendTransaction(
          to: to,
          value: value,
          gasLimit: UInt256(90000),
          gasPrice: networkGasPrice,
          nonce: nonce,
          data: data ?? GeneralData(data: Data())
        )
          
        transaction.sign(using: manager, with: from, network: network) { result in
          switch result {
          case let .failure(error):
            completion(.failure(error))
          case let .success(signature):
            let request = SendRawTransactionRequest(SendRawTransactionRequest.Parameters(
              data: RLPData.encode(from: transaction.toRLPValue() + signature.toRLPValue())
            ))
            self.request(request) { completion($0) }
          }
        }
      }
    }
  }
}
