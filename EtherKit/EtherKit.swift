//
//  EtherKit.swift
//  Pods
//
//  Created by Cole Potrocky on 4/12/18.
//

import Marshal
import Result

public enum ConnectionMode {
  case websocket
  case http
}

public final class EtherKit {
  private let connectionMode: ConnectionMode
  private let url: URL
  private let applicationTag: String

  private lazy var manager: RequestManager = {
    switch connectionMode {
    case .http:
      return URLRequestManager(for: url)
    case .websocket:
      return WebSocketManager(for: url)
    }
  }()

  private lazy var keyManager: KeyManager = {
    KeyManager(applicationTag: applicationTag)
  }()

  public init(_ url: URL, connectionMode: ConnectionMode, applicationTag: String) {
    self.url = url
    self.connectionMode = connectionMode
    self.applicationTag = applicationTag
  }

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

  public func sign(
    with sender: Address,
    transaction: TransactionCall,
    network: Network,
    completion: @escaping (Result<SignedTransactionCall, EtherKitError>) -> Void
  ) {
    do {
      try SignedTransactionCall.create(
        manager: keyManager,
        sign: transaction,
        network: network,
        with: sender
      ) {
        completion(.success($0))
      }
    } catch let error as EtherKitError {
      completion(.failure(error))
    } catch {
      completion(.failure(.unknown(error: error)))
    }
  }

  public func sign(
    message: Data,
    network: Network,
    for address: Address,
    completion: @escaping (Result<Signature, EtherKitError>) -> Void
  ) {
    do {
      let prefix = "\u{19}Ethereum Signed Message:\n\(message.count)".data(using: .utf8)!
      try Signature.create(message: prefix + message, manager: keyManager, network: network, for: address) {
        completion(.success($0))
      }
    } catch let error as EtherKitError {
      completion(.failure(error))
    } catch {
      completion(.failure(.unknown(error: error)))
    }
  }

  public func sign(
    message: String,
    network: Network,
    for address: Address,
    completion: @escaping (Result<Signature, EtherKitError>) -> Void
  ) {
    return sign(message: message.packedData, network: network, for: address, completion: completion)
  }

  public func sign(
    datas: [TypedData],
    network: Network,
    for address: Address,
    completion: @escaping (Result<Signature, EtherKitError>) -> Void
  ) {
    do {
      let schemas = datas.map { $0.schemaData }.reduce(Data(), { $0 + $1 }).sha3(.keccak256)
      let values = datas.map { $0.typedData }.reduce(Data(), { $0 + $1 }).sha3(.keccak256)
      let message = (schemas + values)

      try Signature.create(message: message, manager: keyManager, network: network, for: address) {
        completion(.success($0))
      }
    } catch let error as EtherKitError {
      completion(.failure(error))
    } catch {
      completion(.failure(.unknown(error: error)))
    }
  }

  public func send(
    with sender: Address,
    to: Address,
    value: UInt256,
    completion: @escaping (Result<Hash, EtherKitError>) -> Void
  ) {
    request(
      networkVersion(),
      transactionCount(sender, blockNumber: .pending)
    ) { result in
      switch result {
      case let .success(items):
        let (network, nonce) = items
        self.sign(
          with: sender,
          transaction: TransactionCall(
            nonce: UInt256(nonce.describing),
            to: to,
            gasLimit: UInt256(21000),
            gasPrice: UInt256(20_000_000_000),
            value: value
          ),
          network: network
        ) {
          switch $0 {
          case let .success(signedTransaction):
            let encodedData = RLPData.encode(from: signedTransaction)
            let sendRequest = SendRawTransactionRequest(SendRawTransactionRequest.Parameters(data: encodedData))
            self.request(sendRequest) { completion($0) }
          case let .failure(error):
            completion(.failure(error))
          }
        }
      case let .failure(error):
        completion(.failure(error))
      }
    }
  }

  public func send(
    with sender: Address,
    to: Address,
    value: UInt256,
    data: GeneralData,
    gas: UInt256 = UInt256(21000),
    completion: @escaping (Result<Hash, EtherKitError>) -> Void
  ) {
    request(
      networkVersion(),
      transactionCount(sender, blockNumber: .pending)
    ) { result in
      switch result {
      case let .success(items):
        let (network, nonce) = items
        self.sign(
          with: sender,
          transaction: TransactionCall(
            nonce: UInt256(nonce.describing),
            to: to,
            gasLimit: gas,
            gasPrice: UInt256(20_000_000_000),
            value: value,
            data: data
          ),
          network: network
        ) {
          switch $0 {
          case let .success(signedTransaction):
            let encodedData = RLPData.encode(from: signedTransaction)
            let sendRequest = SendRawTransactionRequest(SendRawTransactionRequest.Parameters(data: encodedData))
            self.request(sendRequest) { completion($0) }
          case let .failure(error):
            completion(.failure(error))
          }
        }
      case let .failure(error):
        completion(.failure(error))
      }
    }
  }

  public func createKeyPair(
    _ config: KeyManager.PairConfig = KeyManager.PairConfig(operationPrompt: nil),
    completion: @escaping (Result<Address, EtherKitError>) -> Void
  ) {
    return try keyManager.create(config: config, completion: completion)
  }
}
