//
//  StorageStrategyType.swift
//  EtherKit
//
//  Created by Cole Potrocky on 8/13/18.
//

import Result

public protocol StorageStrategyType {
  func store(data: Data) -> Result<Void, EtherKitError>
  func map<T>(secureContext: @escaping ((Data) -> Result<T, EtherKitError>)) -> Result<T, EtherKitError>
  func delete() -> Result<Void, EtherKitError>
}

extension StorageStrategyType {
  public func map<T>(secureContext: @escaping (Data) -> T) -> Result<T, EtherKitError> {
    return map { .success(secureContext($0)) }
  }
}
