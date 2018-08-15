//
//  RawStorageStrategy.swift
//  EtherKit
//
//  Created by Cole Potrocky on 8/13/18.
//

import Result

public struct RawStorageStrategy: StorageStrategyType {
  var data: Data

  public init(data: Data) {
    self.data = data
  }

  // MARK: - StorageStrategyType

  public func map<T>(secureContext: @escaping ((Data) -> Result<T, EtherKitError>)) -> Result<T, EtherKitError> {
    return secureContext(data)
  }

  public func store(data _: Data) -> Result<Void, EtherKitError> {
    return .success(())
  }

  public func delete() -> Result<Void, EtherKitError> {
    return .success(())
  }
}
