//
//  EtherQuery.swift
//  EtherKit
//
//  Created by Cole Potrocky on 6/8/18.
//

import Foundation
import Marshal
import Result

public final class EtherQuery {
  public static let DefaultGasLimit: UInt256 = UInt256(90000)
  public enum ConnectionMode {
    case websocket
    case http
  }

  private let connectionMode: ConnectionMode
  private let extraRequestHeaders: [String: String]?
  private let url: URL

  private lazy var manager: RequestManager = {
    switch connectionMode {
    case .http:
      return URLRequestManager(for: url, extraRequestHeaders: extraRequestHeaders)
    case .websocket:
      return WebSocketManager(for: url, extraRequestHeaders: extraRequestHeaders)
    }
  }()

  public init(_ url: URL, connectionMode: ConnectionMode, extraRequestHeaders: [String: String]? = nil) {
    self.url = url
    self.connectionMode = connectionMode
    self.extraRequestHeaders = extraRequestHeaders
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

  public func transaction(_ hash: Hash) -> GetTransactionByHashRequest {
    return GetTransactionByHashRequest(GetTransactionByHashRequest.Parameters(hash: hash))
  }

  public func blockNumber() -> BlockNumberRequest {
    return BlockNumberRequest()
  }

  public func block(_ blockNumber: BlockNumber, fullTransactionObjects: Bool = false) -> GetBlockByNumberRequest {
    return GetBlockByNumberRequest(GetBlockByNumberRequest.Parameters(
      blockNumber: blockNumber,
      fullTransactionObjects: fullTransactionObjects
    ))
  }

  public func code(_ address: Address, blockNumber: BlockNumber = .latest) -> GetCodeRequest {
    return GetCodeRequest(GetCodeRequest.Parameters(address: address, blockNumber: blockNumber))
  }

  public func gasPrice() -> GasPriceRequest {
    return GasPriceRequest()
  }

  public func estimateGasLimit(
    to: Address,
    from: Address? = nil,
    gasLimit: UInt256? = nil,
    gasPrice: UInt256? = nil,
    value: UInt256? = nil,
    data: GeneralData? = nil
  ) -> EstimateGasRequest {
    return EstimateGasRequest(EstimateGasRequest.Parameters(
      from: from,
      to: to,
      gasLimit: gasLimit,
      gasPrice: gasPrice,
      value: value,
      data: data
    ))
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

  public func requestGasEstimate(
    for transaction: SendTransaction,
    from address: Address,
    completion: @escaping (Result<UInt256, EtherKitError>) -> Void
  ) {
    request(
      code(transaction.to),
      estimateGasLimit(
        to: transaction.to,
        from: address,
        gasPrice: transaction.gasPrice,
        value: transaction.value, data: transaction.data
      )
    ) { result in
      completion(result.map {
        let (code, estimatedGasLimit) = $0
        return code.data.isEmpty ? EtherQuery.DefaultGasLimit : estimatedGasLimit
      })
    }
  }

  // MARK: Mutative Requests

  public func send<T: PrivateKeyType>(
    using key: T,
    to: Address,
    value: UInt256,
    data: GeneralData? = nil,
    queue: DispatchQueue = DispatchQueue.global(qos: .default),
    completion: @escaping (Result<Hash, EtherKitError>) -> Void
  ) {
    key.unlocked(queue: queue) {
      switch $0 {
      case .failure:
        completion(.failure(EtherKitError.keyManagerFailed(reason: .keyNotFound)))
        return
      case let .success(unlockedKey):
        self.request(
          self.networkVersion(),
          self.transactionCount(unlockedKey.publicKey.address, blockNumber: .pending),
          self.gasPrice()
        ) {
          switch $0 {
          case let .failure(error):
            completion(.failure(error))
          case let .success(items):
            let (network, nonce, networkGasPrice) = items
            let rawTransaction = SendTransaction(
              to: to,
              value: value,
              gasLimit: EtherQuery.DefaultGasLimit,
              gasPrice: networkGasPrice,
              nonce: nonce,
              data: data ?? GeneralData(data: Data())
            )

            self.requestGasEstimate(for: rawTransaction, from: unlockedKey.publicKey.address) {
              switch $0 {
              case let .failure(error):
                completion(.failure(error))
              case let .success(gasLimit):

                let finalTransaction = SendTransaction(
                  to: rawTransaction.to,
                  value: rawTransaction.value,
                  gasLimit: gasLimit,
                  gasPrice: rawTransaction.gasPrice,
                  nonce: rawTransaction.nonce,
                  data: rawTransaction.data
                )

                finalTransaction.sign(using: unlockedKey, network: network).bimap(
                  success: { signature in
                    let request = SendRawTransactionRequest(SendRawTransactionRequest.Parameters(
                      data: RLPData.encode(from: finalTransaction.toRLPValue() + signature.toRLPValue())
                    ))
                    self.request(request) { completion($0) }
                  },
                  failure: { $0 }
                )
              }
            }
          }
        }
      }
    }
  }
}
