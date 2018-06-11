//
//  EtherKeyManager.swift
//  EtherKit
//
//  Created by Cole Potrocky on 4/21/18.
//

import BigInt
import CryptoSwift
import LocalAuthentication
import Result
import secp256k1

public final class EtherKeyManager {
  public enum Device {
    public static var hasSecureEnclave: Bool {
      return !isSimulator && hasBiometricSupport
    }

    public static var isSimulator: Bool {
      return TARGET_OS_SIMULATOR == 1
    }

    public static var hasBiometricSupport: Bool {
      var error: NSError?
      var hasBiometricSupport = LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
      guard error == nil else {
        guard #available(iOS 11, *) else {
          return error?.code != LAError.touchIDNotAvailable.rawValue
        }
        return error?.code != LAError.biometryNotAvailable.rawValue
      }
      return hasBiometricSupport
    }
  }

  private struct Constants {
    static let attrKeyTypeEllipticCurve: Any = {
      guard #available(iOS 10.0, *) else {
        return kSecAttrKeyTypeEC
      }
      return kSecAttrKeyTypeECSECPrimeRandom
    }()

    static let bytesInSecp256k1PrivateKey: Int = 32
  }

  private enum KeyType: String {
    case enclave = "secp256r1"
    case crypto = "secp256k1"

    func applicationTag(for address: Address) -> Data {
      return "\(applicationTag).\(String(describing: address)).\(rawValue)".data(using: .utf8)!
    }
  }

  private let applicationTag: String
  private lazy var secp256k1Context = {
    secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN) | UInt32(SECP256K1_CONTEXT_VERIFY))!
  }()

  public init(applicationTag: String) {
    self.applicationTag = applicationTag
  }

  // Destroy the context, if created for secp256k1

  // Creating a key-pair consists of creating two new curves:
  // 1. A SECP-256r1 curve.  This keypair sits in the secure element on the device.
  // 2. a SECP-256k1 curve.  This keypair is encrypted in keychain using the SE key.
  public func createKeyPair(completion: @escaping (Result<Address, EtherKitError>) -> Void) {
    DispatchQueue.global(qos: .default).async {
      // overwrite data in memory
      var secp256k1PrivateBytes = [UInt8](repeating: 0, count: Constants.bytesInSecp256k1PrivateKey)
      repeat {
        SecRandomCopyBytes(kSecRandomDefault, Constants.bytesInSecp256k1PrivateKey, &secp256k1PrivateBytes)
      } while secp256k1_ec_seckey_verify(self.secp256k1Context, &secp256k1PrivateBytes) != 1

      var secp256k1PublicKeyRaw: secp256k1_pubkey = secp256k1_pubkey.init()
      secp256k1_ec_pubkey_create(self.secp256k1Context, &secp256k1PublicKeyRaw, secp256k1PrivateBytes)
      var secp256k1PublicKey = [UInt8](repeating: 0, count: 65)
      var pubKeySerializedLength = 65
      secp256k1_ec_pubkey_serialize(
        self.secp256k1Context,
        &secp256k1PublicKey,
        &pubKeySerializedLength,
        &secp256k1PublicKeyRaw,
        UInt32(SECP256K1_EC_UNCOMPRESSED)
      )
      let newAddress = Address(from: Data(secp256k1PublicKey.dropFirst()))

      var secp256k1PrivateKey = Data(bytes: secp256k1PrivateBytes)
      // We should probably not do this on the main thread.
      if Device.hasSecureEnclave {
        let biometryFlag: SecAccessControlCreateFlags
        if #available(iOS 11.3, *) {
          biometryFlag = .biometryCurrentSet
        } else {
          biometryFlag = .touchIDCurrentSet
        }

        let access = SecAccessControlCreateWithFlags(
          kCFAllocatorDefault,
          kSecAttrAccessibleWhenUnlocked,
          [.privateKeyUsage, biometryFlag],
          nil
        )!

        let privateKeyAttrs: [String: Any] = [
          kSecAttrIsPermanent as String: true,
          kSecAttrAccessControl as String: access,
          kSecAttrApplicationTag as String: KeyType.enclave.applicationTag(for: newAddress),
          kSecUseAuthenticationUI as String: kSecUseAuthenticationUIAllow,
        ]

        let attributes: [String: Any] = [
          kSecAttrKeyType as String: Constants.attrKeyTypeEllipticCurve,
          kSecAttrKeySizeInBits as String: 256,
          kSecPrivateKeyAttrs as String: privateKeyAttrs,
          kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
        ]

        var error: Unmanaged<CFError>?
        guard let enclaveKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
          completion(.failure(EtherKitError.keyManagerFailed(reason: .secureEnclaveCreationFailed)))
          return
        }

        let publicKey = SecKeyCopyPublicKey(enclaveKey)!
        let secp256k1CipherKey = SecKeyCreateEncryptedData(
          publicKey,
          .eciesEncryptionCofactorX963SHA256AESGCM,
          secp256k1PrivateKey as CFData,
          nil
        )

        guard secp256k1CipherKey != nil else {
          completion(.failure(EtherKitError.keyManagerFailed(reason: .encryptionFailed)))
          return
        }
        secp256k1PrivateKey = secp256k1CipherKey as! Data
      }

      let addQuery: [String: Any] = [
        kSecClass as String: kSecClassKey,
        kSecAttrApplicationTag as String: KeyType.crypto.applicationTag(for: newAddress),
        kSecValueData as String: secp256k1PrivateKey,
      ]

      let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
      guard addStatus == errSecSuccess else {
        completion(.failure(EtherKitError.keyManagerFailed(reason: .keychainStorageFailure)))
        return
      }

      completion(.success(newAddress))
    }
  }
  
  // MARK: Internal API

  private func mapToCryptoKey(for address: Address, block: @escaping (_ privateKey: [UInt8]) throws -> Void) throws {
    // Scrub this from memory
    var cryptoPrivateKey: CFTypeRef?
    var getquery: [String: Any] = [
      kSecClass as String: kSecClassKey,
      kSecAttrApplicationTag as String: KeyType.crypto.applicationTag(for: address),
      kSecReturnData as String: true,
    ]
    let status = SecItemCopyMatching(getquery as CFDictionary, &cryptoPrivateKey)
    guard status == errSecSuccess else {
      throw EtherKitError.keyManagerFailed(reason: .keyNotFound)
    }
    guard Device.hasSecureEnclave else {
      try block([UInt8](cryptoPrivateKey as! Data))
      return
    }

    var enclavePrivateKey: CFTypeRef?
    var enclaveQuery: [String: Any] = [
      kSecClass as String: kSecClassKey,
      kSecAttrApplicationTag as String: KeyType.enclave.applicationTag(for: address),
      kSecReturnRef as String: true,
    ]
    let enclaveStatus = SecItemCopyMatching(enclaveQuery as CFDictionary, &enclavePrivateKey)
    guard enclaveStatus == errSecSuccess else {
      throw EtherKitError.keyManagerFailed(reason: .keyNotFound)
    }
    let decryptedCryptoKey = SecKeyCreateDecryptedData(
      enclavePrivateKey as! SecKey,
      .eciesEncryptionCofactorX963SHA256AESGCM,
      cryptoPrivateKey as! CFData,
      nil
    )

    guard decryptedCryptoKey != nil else {
      throw EtherKitError.keyManagerFailed(reason: .decryptionFailed)
    }

    try block([UInt8](decryptedCryptoKey as! Data))
  }
  
  func signRaw(
    _ data: Data,
    for address: Address,
    callback: @escaping (_ sig: Data, _ recoveryID: UInt) -> Void
  ) throws {
    var digestForData = [UInt8](data.sha3(.keccak256))
    var unsafeSignature = secp256k1_ecdsa_recoverable_signature.init()
    
    try mapToCryptoKey(for: address) { privateKey throws in
      let result = secp256k1_ecdsa_sign_recoverable(
        self.secp256k1Context,
        &unsafeSignature,
        &digestForData,
        privateKey,
        secp256k1_nonce_function_rfc6979,
        nil
      )
      guard result == 1 else {
        throw EtherKitError.keyManagerFailed(reason: .signatureFailed)
      }
      
      let signatureBytesPtr: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer.allocate(capacity: 64)
      var recoveryID: Int32 = 0
      secp256k1_ecdsa_recoverable_signature_serialize_compact(
        self.secp256k1Context,
        signatureBytesPtr,
        &recoveryID,
        &unsafeSignature
      )
      let signatureBytes: [UInt8] = (0 ..< Int(64)).map { return signatureBytesPtr[$0] }
      
      callback(Data(bytes: signatureBytes), UInt(recoveryID))
    }
  }
  
  func verifyRaw(
    _ signature: Data,
    address: Address,
    digest: Data,
    callback: @escaping (_ isValid: Bool) -> Void
  ) throws {
    try mapToCryptoKey(for: address) { privateKey in
      var privateKey = privateKey
      var publicKey = secp256k1_pubkey.init()
      secp256k1_ec_pubkey_create(self.secp256k1Context, &publicKey, &privateKey)
      
      var signatureBytes = [UInt8](signature)
      var signature = secp256k1_ecdsa_signature.init()
      secp256k1_ecdsa_signature_parse_compact(self.secp256k1Context, &signature, &signatureBytes)
      
      var digestBytes = [UInt8](digest)
      let validateResult = secp256k1_ecdsa_verify(self.secp256k1Context, &signature, &digestBytes, &publicKey)
      callback(validateResult == 1)
    }
  }
}
