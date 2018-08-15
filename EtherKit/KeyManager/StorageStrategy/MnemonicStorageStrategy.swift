//
//  MnemonicStorageStrategy.swift
//  EtherKit
//
//  Created by Cole Potrocky on 8/15/18.
//

import Result

// Generates the mnemonic with no pass phrase and stores just the seed
// for the mnemonic.  This allows users to see their mnemonic after generation.
public struct MnemonicStorageStrategy: StorageStrategyType {
  public let storageStrategy: StorageStrategyType

  public init(_ storageStrategy: StorageStrategyType) {
    self.storageStrategy = storageStrategy
  }

  // MARK: - StorageStrategyType

  public func store(data: Data) -> Result<Void, EtherKitError> {
    return storageStrategy.store(data: data)
  }

  public func map<T>(secureContext: @escaping (Data) -> Result<T, EtherKitError>) -> Result<T, EtherKitError> {
    return storageStrategy.map { encodedSentence in
      switch self.seedFromMnemonicData(encodedSentence) {
      case let .success(data):
        return secureContext(data)
      case .failure:
        return .failure(EtherKitError.keyManagerFailed(reason: .keyDerivationFailed))
      }
    }
  }

  public func delete() -> Result<Void, EtherKitError> {
    return storageStrategy.delete()
  }

  // MARK: Private API

  func seedFromMnemonicData(_ data: Data) -> Result<Data, EtherKitError> {
    guard let sentence = Mnemonic.MnemonicSentence(from: data) else {
      return .failure(EtherKitError.keyManagerFailed(reason: .keyDerivationFailed))
    }
    return Mnemonic.createSeed(from: sentence)
      .mapError { _ in EtherKitError.keyManagerFailed(reason: .keyDerivationFailed) }
  }
}
