//
//  KeyManager+PromiseKit.swift
//  EtherKit
//
//  Created by Cole Potrocky on 8/21/18.
//

import PromiseKit

public extension PrivateKeyType {
  public func unlocked(queue: DispatchQueue = DispatchQueue.global()) -> Promise<KeyImpl> {
    return Promise { seal in
      self.unlocked(queue: queue, completion: { seal.resolve($0.value, $0.error) })
    }
  }
}

public extension PublicKeyType {
  public func verify(
    signature: Data,
    for message: Data,
    queue: DispatchQueue = DispatchQueue.global()
  ) -> Guarantee<Bool> {
    return Guarantee { seal in
      self.verify(signature: signature, for: message, queue: queue, completion: seal)
    }
  }
}

public extension HDKey.Private {
  public static func create(
    with strategy: StorageStrategyType,
    mnemonic: Mnemonic.MnemonicSentence,
    network: Network,
    path: [KeyPathNode],
    queue: DispatchQueue = DispatchQueue.global()
  ) -> Promise<HDKey.Private> {
    return Promise { seal in
      self.create(with: strategy, mnemonic: mnemonic, network: network, path: path, queue: queue) {
        seal.resolve($0.value, $0.error)
      }
    }
  }
}

public extension Key.Private {
  public static func create(
    with strategy: StorageStrategyType,
    queue: DispatchQueue = DispatchQueue.global()
  ) -> Promise<Key.Private> {
    return Promise { seal in
      self.create(with: strategy, queue: queue) { seal.resolve($0.value, $0.error) }
    }
  }
}

public extension Signable {
  public func sign<T: PrivateKeyType>(
    using key: T,
    network: Network?,
    queue: DispatchQueue = DispatchQueue.global(qos: .default)
  ) -> Promise<Signature> {
    return Promise { seal in
      self.sign(using: key, network: network, queue: queue) { seal.resolve($0.value, $0.error) }
    }
  }
}
