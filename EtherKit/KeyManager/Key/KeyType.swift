//
//  KeyType.swift
//  EtherKit
//
//  Created by Cole Potrocky on 8/13/18.
//

import Result

public typealias RawSignature = (signature: Data, recoveryID: Int32)

public protocol PrivateKeyType {
  associatedtype KeyImpl: PrivateKeyImplType

  // Describes how to access this private key's raw data and how to interact with it
  var storageStrategy: StorageStrategyType { get }

  // There could be a scenario where a program deletes data within the secure enclave,
  // then we try to access it expecting it'll be there.  This hdies the real guts of the key
  // inside a closure for easy processing
  func unlocked(
    queue: DispatchQueue,
    completion: @escaping (Result<KeyImpl, EtherKitError>) -> Void
  )
}

public extension PrivateKeyType {
  public func unlocked(completion: @escaping (Result<KeyImpl, EtherKitError>) -> Void) {
    unlocked(queue: DispatchQueue.global(qos: .default), completion: completion)
  }
}

public protocol PublicKeyType {
  var address: Address { get }
  func verify(signature: Data, for message: Data, queue: DispatchQueue, completion: @escaping (Bool) -> Void)
}

// MARK: - Implicit API

public protocol PrivateKeyImplType {
  associatedtype PublicKey: PublicKeyType

  var publicKey: PublicKey { get }

  func sign(_ data: Data) -> Result<RawSignature, EtherKitError>
}
