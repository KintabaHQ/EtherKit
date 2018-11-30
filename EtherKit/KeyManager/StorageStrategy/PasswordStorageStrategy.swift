//
//  PasswordStorageStrategy.swift
//  EtherKit
//
//  Created by Cole Potrocky on 11/21/18.
//

import CryptoSwift
import Result

public class PasswordStorageStrategy: StorageStrategyType {
  public typealias PasswordGetter = (@escaping (String?) -> Void) -> Void

  static var salt: [UInt8] {
    return Array("etherkit".utf8)
  }

  static var prefix: Data {
    return "etherkit".data(using: .utf8)!
  }

  static var semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)

  fileprivate let passwordGetter: PasswordGetter
  fileprivate let keychainStorageStrategy: KeychainStorageStrategy
  fileprivate let keychainIVStorageStrategy: KeychainStorageStrategy

  public init(identifier: String, passwordGetter: @escaping PasswordGetter) {
    let accessControl = SecAccessControlCreateWithFlags(
      kCFAllocatorDefault,
      kSecAttrAccessibleAlwaysThisDeviceOnly,
      [],
      nil
    )
    keychainStorageStrategy = KeychainStorageStrategy(
      identifier: identifier,
      access: accessControl
    )
    keychainIVStorageStrategy = KeychainStorageStrategy(
      identifier: "\(identifier):iv",
      access: accessControl
    )
    self.passwordGetter = passwordGetter
  }

  // MARK: - StorageStrategyType

  public func store(data: Data) -> Result<Void, EtherKitError> {
    guard let password = getPasswordSync() else {
      return .failure(EtherKitError.keyManagerFailed(reason: .encryptionFailed))
    }

    do {
      let iv = Data.randomBytes(count: 16)
      keychainIVStorageStrategy.store(data: iv)

      let derivedKey = try getDerivedKey(from: password)
      let aes = try AES(key: derivedKey, blockMode: CTR(iv: iv.bytes))

      var prefixedData = Data()
      prefixedData.append(PasswordStorageStrategy.prefix)
      prefixedData.append(data)

      keychainStorageStrategy.store(data: Data(bytes: try aes.encrypt(prefixedData.bytes)))
    } catch {
      return .failure(EtherKitError.keyManagerFailed(reason: .encryptionFailed))
    }

    return .success(())
  }

  public func map<T>(secureContext: @escaping ((Data) -> Result<T, EtherKitError>)) -> Result<T, EtherKitError> {
    let maybeCipherText = keychainStorageStrategy.map { $0 }
    let maybeIV = keychainIVStorageStrategy.map { $0 }

    guard let password = getPasswordSync(), let iv = maybeIV.value, let cipherText = maybeCipherText.value else {
      return .failure(EtherKitError.keyManagerFailed(reason: .decryptionFailed))
    }

    do {
      let aes = try AES(key: getDerivedKey(from: password), blockMode: CTR(iv: iv.bytes))
      let prefixedData = Data(bytes: try aes.decrypt(cipherText.bytes))
      let prefix = prefixedData.subdata(in: 0 ..< PasswordStorageStrategy.prefix.count)
      let data = prefixedData.subdata(in: PasswordStorageStrategy.prefix.count ..< prefixedData.count)

      guard prefix == PasswordStorageStrategy.prefix else {
        return .failure(EtherKitError.keyManagerFailed(reason: .decryptionFailed))
      }

      return secureContext(data)
    } catch {
      return .failure(EtherKitError.keyManagerFailed(reason: .decryptionFailed))
    }
  }

  public func delete() -> Result<Void, EtherKitError> {
    return keychainIVStorageStrategy.delete().flatMap { self.keychainStorageStrategy.delete() }
  }

  // MARK: - Private API

  fileprivate func getDerivedKey(from password: String) throws -> [UInt8] {
    return try PKCS5.PBKDF2(password: password.bytes, salt: PasswordStorageStrategy.salt).calculate()
  }

  /// Often, a password will be
  fileprivate func getPasswordSync() -> String? {
    var maybePassword = PasswordBox()

    passwordGetter {
      maybePassword.setPassword(to: $0)
      type(of: self).semaphore.signal()
    }
    type(of: self).semaphore.wait()

    return maybePassword.getPassword()
  }
}

fileprivate class PasswordBox {
  var password: String?

  init() {}

  func setPassword(to: String?) {
    password = to
  }

  func getPassword() -> String? {
    return password
  }
}
