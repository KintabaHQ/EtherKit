//
//  HDKey+Derivation.swift
//  EtherKit
//
//  Created by Cole Potrocky on 8/13/18.
//

import CryptoSwift
import Result
import secp256k1

public struct KeyPathNode {
  public let index: UInt32
  public let hardened: Bool

  public init(at index: UInt32, hardened: Bool = false) {
    self.index = index
    self.hardened = hardened
  }
}

// MARK: Key Derivation From Seed

public extension HDKey {
  public struct KeyDerivation {
    public let key: Data
    public let chainCode: Data
    public let depth: UInt8
    public let fingerprint: UInt32
    public let childIndex: UInt32
  }
}

extension HDKey.Private {
  func map<T>(to keyFn: @escaping (Key.Private) -> Result<T, EtherKitError>) -> Result<T, EtherKitError> {
    return storageStrategy.map { seedKey in
      switch self.derive(from: seedKey) {
      case let .failure(error):
        return .failure(error)
      case let .success(rawChildData):
        let derivedKey = Key.Private(RawStorageStrategy(data: rawChildData.key))
        return keyFn(derivedKey)
      }
    }
  }

  func map<T>(to keyFn: @escaping (Key.Private) -> T) -> Result<T, EtherKitError> {
    return map { .success(keyFn($0)) }
  }

  // MARK: Private API

  func derive(from seed: Data) -> Result<HDKey.KeyDerivation, EtherKitError> {
    guard let hmac = try? HMAC(key: "Bitcoin seed", variant: .sha512).authenticate(seed.bytes) else {
      return .failure(EtherKitError.keyManagerFailed(reason: .keyDerivationFailed))
    }

    let hmacAsData = Data(bytes: hmac)
    let result = try? path.reduce(
      HDKey.KeyDerivation(
        key: hmacAsData[0 ..< 32],
        chainCode: hmacAsData[32 ..< 64],
        depth: 0,
        fingerprint: 0,
        childIndex: 0
      ),
      deriveNode
    )

    guard let value = result else {
      return .failure(EtherKitError.keyManagerFailed(reason: .keyDerivationFailed))
    }

    return .success(value)
  }

  fileprivate func deriveNode(derivation: HDKey.KeyDerivation, node: KeyPathNode) throws -> HDKey.KeyDerivation {
    // We explictly use a hardened flag, so throw if we use a value
    // >= 2^31, all values of which are considered 'hardened' values.
    guard 0x8000_0000 & node.index == 0 else {
      throw EtherKitError.keyManagerFailed(reason: .keyDerivationFailed)
    }

    // Make the index hardened if needed
    let index = (node.hardened ? 0x8000_0000 | node.index : node.index).bigEndian

    var iData: Data
    let publicKey = Key.Private.KeyImpl(derivation.key).publicKey
    if node.hardened {
      iData =
        // Pad hardened l value with one byte of zeros
        Data(bytes: Padding.zeroPadding.add(to: [], blockSize: 1)) +
        // Append the private key of this `node`'s parent.
        derivation.key
    } else {
      // In non hardened cases, L is just equal to the public key of the current path
      iData = publicKey.data(compressed: true)
    }

    iData.append(index.bytes)

    // I as defined in the BIP32 specification.
    guard let IRaw = try? HMAC(key: derivation.chainCode.bytes, variant: .sha512).authenticate(iData.bytes) else {
      throw EtherKitError.keyManagerFailed(reason: .keyDerivationFailed)
    }
    let I = Data(bytes: IRaw)

    // For both hardened and non-hardened keys, append the index of the current `node`
    // with its most significant byte first
    var IL = I[0 ..< 32].bytes
    let IR = I[32 ..< 64]

    var newKey = derivation.key.bytes
    guard secp256k1_ec_privkey_tweak_add(Key.context, &newKey, &IL) == 1 else {
      return try deriveNode(
        derivation: derivation,
        node: KeyPathNode(at: node.index + 1, hardened: node.hardened)
      )
    }

    guard let fingerprint = UInt32(
      RIPEMD160.hash(message: publicKey.data(compressed: true).sha256()).toHexString().prefix(8),
      radix: 16
    )?.bigEndian else {
      throw EtherKitError.keyManagerFailed(reason: .keyDerivationFailed)
    }

    return HDKey.KeyDerivation(
      key: Data(bytes: newKey),
      chainCode: IR,
      depth: derivation.depth + 1,
      fingerprint: fingerprint,
      childIndex: index
    )
  }
}
