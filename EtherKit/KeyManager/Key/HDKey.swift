//
//  HDKey.swift
//  EtherKit
//
//  Created by Cole Potrocky on 8/13/18.
//

import CryptoSwift
import Result

public enum HDKey {
  public enum KeyType {
    case seed
    case mnemonic
  }

  public struct Private: PrivateKeyType {
    public let storageStrategy: StorageStrategyType
    public let network: Network
    public let path: [KeyPathNode]

    public init(
      _ storageStrategy: StorageStrategyType,
      network: Network,
      path: [KeyPathNode]
    ) {
      self.storageStrategy = storageStrategy
      self.network = network
      self.path = path
    }

    public static func create(
      with strategy: StorageStrategyType,
      mnemonic: Mnemonic.MnemonicSentence,
      network: Network,
      path: [KeyPathNode],
      queue: DispatchQueue = DispatchQueue.global(qos: .default),
      completion: @escaping (Result<Private, EtherKitError>) -> Void
    ) {
      queue.async {
        switch strategy {
        case is MnemonicStorageStrategy:
          completion(
            strategy.store(data: mnemonic.data).map { Private(strategy, network: network, path: path) }
          )
        default:
          completion(
            Mnemonic.createSeed(from: mnemonic)
              .mapError { _ in EtherKitError.keyManagerFailed(reason: .keyDerivationFailed) }
              .flatMap { strategy.store(data: $0) }
              .map { Private(strategy, network: network, path: path) }
          )
        }
      }
    }

    // MARK: - PrivateKeyType

    public typealias RawData = (source: Data, derivation: KeyDerivation, network: Network)
    public typealias PublicKey = HDKey.Public

    public func unlocked(
      queue: DispatchQueue,
      completion: @escaping (Result<KeyImpl, EtherKitError>) -> Void
    ) {
      queue.async {
        autoreleasepool {
          switch self.storageStrategy {
          case let mnemonic as MnemonicStorageStrategy:
            completion(
              mnemonic.storageStrategy
                .map { $0 }
                .flatMap { mnemonicData in
                  mnemonic.seedFromMnemonicData(mnemonicData)
                    .flatMap { self.derive(from: $0) }
                    .map { KeyImpl(mnemonicData, derivation: $0, network: self.network) }
                }
            )
          default:
            completion(
              self.storageStrategy
                .map { $0 }
                .flatMap { seed in self.derive(from: seed).map {
                  KeyImpl(seed, derivation: $0, network: self.network)
                } }
            )
          }
        }
      }
    }

    public final class KeyImpl: PrivateKeyImplType {
      let raw: Data
      let derivation: HDKey.KeyDerivation
      let network: Network

      public var mnemonic: [String]? {
        return Mnemonic.MnemonicSentence(from: raw)?.sentence
      }

      public var extended: String {
        var data = Data()
        data.append(network.privateKeyPrefix.bigEndian.bytes)
        data.append(derivation.depth.littleEndian)
        data.append(derivation.fingerprint.littleEndian.bytes)
        data.append(derivation.childIndex.littleEndian.bytes)
        data.append(derivation.chainCode)
        data.append(contentsOf: Padding.zeroPadding.add(to: [], blockSize: 1))
        data.append(derivation.key)

        return data.bytes.base58CheckEncodedString
      }

      init(_ raw: Data, derivation: HDKey.KeyDerivation, network: Network) {
        self.raw = raw
        self.derivation = derivation
        self.network = network
      }

      // MARK: - PrivateKeyImplType

      public typealias PrivateKeyType = HDKey.Private

      public var publicKey: HDKey.Public {
        let implicitWrappedKey = Key.Private.KeyImpl(derivation.key).publicKey.data(compressed: true)
        return HDKey.Public(
          derivation: HDKey.KeyDerivation(
            key: implicitWrappedKey,
            chainCode: derivation.chainCode,
            depth: derivation.depth,
            fingerprint: derivation.fingerprint,
            childIndex: derivation.childIndex
          ),
          network: network
        )
      }

      public func sign(_ data: Data) -> Result<RawSignature, EtherKitError> {
        return Key.Private.KeyImpl(derivation.key).sign(data)
      }
    }
  }

  public struct Public: PublicKeyType {
    let derivation: KeyDerivation
    let derivedKey: Key.Public
    let network: Network

    init(derivation: KeyDerivation, network: Network) {
      self.derivation = derivation
      derivedKey = Key.Public(data: derivation.key)
      self.network = network
    }

    var extended: String {
      var data = Data()
      data.append(network.publicKeyPrefix.bigEndian.bytes)
      data.append(derivation.depth.littleEndian)
      data.append(derivation.fingerprint.littleEndian.bytes)
      data.append(derivation.childIndex.littleEndian.bytes)
      data.append(derivation.chainCode)
      data.append(derivedKey.data(compressed: true))
      return data.bytes.base58CheckEncodedString
    }

    // MARK: - PublicKeyType

    public var address: Address {
      return derivedKey.address
    }

    public func verify(
      signature: Data,
      for message: Data,
      queue: DispatchQueue = DispatchQueue.global(qos: .default),
      completion: @escaping (Bool) -> Void
    ) {
      return derivedKey.verify(signature: signature, for: message, queue: queue, completion: completion)
    }
  }
}

// MARK: Key Prefixes For BIP32

extension Network {
  var privateKeyPrefix: UInt32 {
    switch self {
    case .main, .nonStandard(number: _):
      return 0x0488_ADE4
    case .kovan, .morden, .rinkeby, .ropstein:
      return 0x0435_8394
    }
  }

  var publicKeyPrefix: UInt32 {
    switch self {
    case .main, .nonStandard(number: _):
      return 0x0488_B21E
    case .kovan, .morden, .rinkeby, .ropstein:
      return 0x0435_87CF
    }
  }
}
