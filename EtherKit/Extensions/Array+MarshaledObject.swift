//
//  Array+MarshaledObject.swift
//  Pods
//
//  Created by Cole Potrocky on 4/11/18.
//

import Marshal

extension Array: MarshaledObject {
  public func optionalAny(for key: KeyType) -> Any? {
    guard let key = key as? Int else {
      return nil
    }
    return self[key]
  }
}
