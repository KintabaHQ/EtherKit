//
//  Key.swift
//  EtherKit
//
//  Created by Cole Potrocky on 8/8/18.
//

import Result
import secp256k1

public enum Key {
  static let context: OpaquePointer = {
    secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN) | UInt32(SECP256K1_CONTEXT_VERIFY))!
  }()

  // A SECP256K1 private key, compatible with Bitcoin, Ethereum networks.
  public struct Private: PrivateKeyType {
    fileprivate static let bytesInKey: Int = 32

    public let storageStrategy: StorageStrategyType

    public init(_ storageStrategy: StorageStrategyType) {
      self.storageStrategy = storageStrategy
    }

    static func create(
      with strategy: StorageStrategyType,
      queue: DispatchQueue = DispatchQueue.global(qos: .default),
      completion: @escaping (Result<Private, EtherKitError>) -> Void
    ) {
      queue.async {
        autoreleasepool {
          var privateKeyCandidate = [UInt8](repeating: 0, count: bytesInKey)
          repeat {
            privateKeyCandidate = Data.randomBytes(count: bytesInKey).bytes
          } while secp256k1_ec_seckey_verify(context, &privateKeyCandidate) != 1

          completion(strategy.store(data: Data(bytes: privateKeyCandidate)).map { _ in Private(strategy) })
        }
      }
    }

    // MARK: - PrivateKeyType

    public typealias PublicKey = Key.Public
    public typealias RawData = Data

    public func unlocked(
      queue: DispatchQueue,
      completion: @escaping (Result<KeyImpl, EtherKitError>) -> Void
    ) {
      queue.async {
        autoreleasepool {
          completion(self.storageStrategy.map { KeyImpl($0) })
        }
      }
    }

    public final class KeyImpl: PrivateKeyImplType {
      let privateKey: Data

      init(_ privateKey: Data) {
        self.privateKey = privateKey
      }

      // MARK: - PrivateKeyImplType

      public var publicKey: Key.Public {
        var raw = secp256k1_pubkey.init()
        secp256k1_ec_pubkey_create(Key.context, &raw, privateKey.bytes)
        return Key.Public(from: raw)
      }

      public func sign(_ data: Data) -> Result<RawSignature, EtherKitError> {
        var digest = data.sha3(.keccak256).bytes
        var rawSig = secp256k1_ecdsa_recoverable_signature.init()

        guard secp256k1_ecdsa_sign_recoverable(
          Key.context,
          &rawSig,
          &digest,
          privateKey.bytes,
          secp256k1_nonce_function_rfc6979,
          nil
        ) == 1 else {
          return .failure(EtherKitError.keyManagerFailed(reason: .signatureFailed))
        }

        let signatureBytesPtr: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer.allocate(capacity: 64)
        var recoveryID: Int32 = 0
        secp256k1_ecdsa_recoverable_signature_serialize_compact(
          Key.context,
          signatureBytesPtr,
          &recoveryID,
          &rawSig
        )
        let signatureBytes: [UInt8] = (0 ..< Int(64)).map { return signatureBytesPtr[$0] }

        return .success((signature: Data(bytes: signatureBytes), recoveryID: recoveryID))
      }
    }
  }

  public struct Public: PublicKeyType {
    fileprivate static let bytesInCompressedKey: Int = 33
    fileprivate static let bytesInUncompressedKey: Int = 65
    fileprivate let rawKey: secp256k1_pubkey

    public var address: Address {
      return Address(data: data(compressed: false).dropFirst().sha3(.keccak256)[12 ..< 32])
    }

    public init(data: Data) {
      precondition(data.count == Public.bytesInUncompressedKey || data.count == Public.bytesInCompressedKey)

      var dataMut = data.bytes
      var raw = secp256k1_pubkey.init()
      secp256k1_ec_pubkey_parse(Key.context, &raw, &dataMut, data.count)

      self.init(from: raw)
    }

    public init(from raw: secp256k1_pubkey) {
      rawKey = raw
    }

    func data(compressed: Bool = true) -> Data {
      var mutableRaw = rawKey
      var keyLength = compressed ? 33 : 65
      var keyBytes = [UInt8](repeating: 0, count: keyLength)
      secp256k1_ec_pubkey_serialize(
        Key.context,
        &keyBytes,
        &keyLength,
        &mutableRaw,
        compressed ? UInt32(SECP256K1_EC_COMPRESSED) : UInt32(SECP256K1_EC_UNCOMPRESSED)
      )
      return Data(keyBytes)
    }

    // MARK: - PublicKeyType

    public func verify(
      signature: Data,
      for message: Data,
      queue: DispatchQueue = DispatchQueue.global(qos: .default),
      completion: @escaping (Bool) -> Void
    ) {
      queue.async {
        var rawSig: secp256k1_ecdsa_signature = {
          var ref = secp256k1_ecdsa_signature.init()
          var sigBytes = signature.bytes
          secp256k1_ecdsa_signature_parse_compact(Key.context, &ref, &sigBytes)
          return ref
        }()

        var msgBytes = message.bytes
        var rawKey = self.rawKey
        completion(secp256k1_ecdsa_verify(Key.context, &rawSig, &msgBytes, &rawKey) == 1)
      }
    }
  }
}
