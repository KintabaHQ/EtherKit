//
//  EnclaveStorageStrategy.swift
//  EtherKit
//
//  Created by Cole Potrocky on 8/13/18.
//

import Result

public struct EnclaveStorageStrategy: StorageStrategyType {
  fileprivate static var curveType: CFString = {
    guard #available(iOS 10.0, *) else {
      return kSecAttrKeyTypeEC
    }
    return kSecAttrKeyTypeECSECPrimeRandom
  }()

  fileprivate static var biometryFlag: SecAccessControlCreateFlags = {
    if #available(iOS 11.3, *) {
      return .biometryCurrentSet
    } else {
      return .touchIDCurrentSet
    }
  }()

  // A string uniquely identifying this item.
  let identifier: String

  fileprivate var query: [String: Any] {
    return [
      kSecClass as String: kSecClassKey,
      kSecAttrApplicationTag as String: "\(identifier):enclave",
    ]
  }

  fileprivate let keychainStorageStrategy: KeychainStorageStrategy

  public init?(identifier: String) {
    guard Device.hasSecureEnclave else { return nil }
    self.identifier = identifier
    keychainStorageStrategy = KeychainStorageStrategy(
      identifier: identifier,
      access: SecAccessControlCreateWithFlags(
        kCFAllocatorDefault,
        kSecAttrAccessibleAlwaysThisDeviceOnly,
        [],
        nil
      )
    )
  }

  // MARK: - StorageStrategyType

  public func store(data: Data) -> Result<Void, EtherKitError> {
    guard let accessConfig = SecAccessControlCreateWithFlags(
      kCFAllocatorDefault,
      kSecAttrAccessibleWhenUnlocked,
      [.privateKeyUsage, type(of: self).biometryFlag],
      nil
    ) else {
      return .failure(EtherKitError.keyManagerFailed(reason: .secureEnclaveCreationFailed))
    }

    let privateKeyCreationAttributes: [String: Any] = query.merging([
      kSecAttrIsPermanent as String: true,
      kSecAttrAccessControl as String: accessConfig,
      kSecUseAuthenticationUI as String: kSecUseAuthenticationUIAllow,
    ]) { a, _ in a }

    let creationAttributes: [String: Any] = [
      kSecAttrKeyType as String: type(of: self).curveType,
      kSecAttrKeySizeInBits as String: 256,
      kSecPrivateKeyAttrs as String: privateKeyCreationAttributes,
      kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
    ]

    guard let privateKey = SecKeyCreateRandomKey(creationAttributes as CFDictionary, nil),
      let publicKey = SecKeyCopyPublicKey(privateKey) else {
      return .failure(EtherKitError.keyManagerFailed(reason: .secureEnclaveCreationFailed))
    }

    guard let cipherData = SecKeyCreateEncryptedData(
      publicKey,
      // Use symmetric encryption strategy using the enclave key.
      .eciesEncryptionCofactorX963SHA256AESGCM,
      data as CFData,
      nil
    ) else {
      return .failure(EtherKitError.keyManagerFailed(reason: .secureEnclaveCreationFailed))
    }

    return keychainStorageStrategy.store(data: cipherData as Data)
  }

  public func map<T>(secureContext: @escaping (Data) -> Result<T, EtherKitError>) -> Result<T, EtherKitError> {
    let keychainResult = keychainStorageStrategy.map { $0 }
    switch keychainResult {
    case let .failure(error):
      return .failure(error)
    case let .success(cipherData):
      let getQuery: [String: Any] = query.merging([
        kSecClass as String: kSecClassKey,
        kSecReturnRef as String: true,
      ]) { a, _ in a }

      var enclaveRawKey: CFTypeRef?
      let retrievalStatus = SecItemCopyMatching(getQuery as CFDictionary, &enclaveRawKey)
      guard retrievalStatus == errSecSuccess,
        let enclaveKey = enclaveRawKey else {
        return .failure(EtherKitError.keyManagerFailed(reason: .keyNotFound))
      }

      guard let plainData = SecKeyCreateDecryptedData(
        enclaveKey as! SecKey,
        .eciesEncryptionCofactorX963SHA256AESGCM,
        cipherData as CFData,
        nil
      ) else {
        return .failure(EtherKitError.keyManagerFailed(reason: .keyNotFound))
      }

      return secureContext(plainData as Data)
    }
  }

  public func delete() -> Result<Void, EtherKitError> {
    let deleteStatus = SecItemDelete(query as CFDictionary)
    guard deleteStatus == errSecSuccess else {
      return .failure(EtherKitError.keyManagerFailed(reason: .keychainStorageFailure))
    }

    return keychainStorageStrategy.delete()
  }
}
