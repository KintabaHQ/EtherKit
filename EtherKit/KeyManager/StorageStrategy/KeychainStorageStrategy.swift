//
//  KeychainStorageStrategy.swift
//  EtherKit
//
//  Created by Cole Potrocky on 8/13/18.
//

import Result

public struct KeychainStorageStrategy: StorageStrategyType {
  public let identifier: String

  fileprivate var access: SecAccessControl?

  fileprivate var query: [String: Any] {
    return [
      kSecClass as String: kSecClassKey,
      kSecAttrApplicationTag as String: "\(identifier):keychain",
      kSecAttrAccessControl as String: access,
    ]
  }

  public init(identifier: String, access: SecAccessControl? = nil) {
    self.identifier = identifier
    self.access = access ?? SecAccessControlCreateWithFlags(
      kCFAllocatorDefault,
      kSecAttrAccessibleWhenUnlocked,
      [],
      nil
    )
  }

  // MARK: - StorageStrategyType

  public func map<T>(secureContext: @escaping (Data) -> Result<T, EtherKitError>) -> Result<T, EtherKitError> {
    return autoreleasepool {
      let keychainGetQuery: [String: Any] = query.merging([kSecReturnData as String: true as Any]) { a, _ in a }

      var maybeData: CFTypeRef?
      let getStatus = SecItemCopyMatching(keychainGetQuery as CFDictionary, &maybeData)

      guard let data = maybeData as? Data, getStatus == errSecSuccess else {
        return .failure(EtherKitError.keyManagerFailed(reason: .keyNotFound))
      }

      return secureContext(data)
    }
  }

  public func store(data: Data) -> Result<Void, EtherKitError> {
    let keychainAddQuery: [String: Any] = query.merging([
      kSecValueData as String: data as Any,
    ]) { a, _ in a }
    let addStatus = SecItemAdd(keychainAddQuery as CFDictionary, nil)
    guard addStatus == errSecSuccess else {
      return .failure(EtherKitError.keyManagerFailed(reason: .keychainStorageFailure))
    }

    return .success(())
  }

  public func delete() -> Result<Void, EtherKitError> {
    let deleteStatus = SecItemDelete(query as CFDictionary)
    guard deleteStatus == errSecSuccess else {
      return .failure(EtherKitError.keyManagerFailed(reason: .keychainStorageFailure))
    }

    return .success(())
  }
}
