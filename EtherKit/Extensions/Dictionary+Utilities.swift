//
//  Dictionary+Utilities.swift
//  EtherKit
//
//  Created by Cole Potrocky on 7/12/18.
//

extension Dictionary {
  // Adapted from Swift Package Manager implementation:
  // Source: https://github.com/apple/swift-package-manager/blob/master/Sources/Basic/DictionaryExtensions.swift#L30-L38
  public func compactMapValues<T>(_ transform: (Value) throws -> T?) rethrows -> [Key: T] {
    var transformed: [Key: T] = [:]
    for (key, value) in self {
      if let value = try transform(value) {
        transformed[key] = value
      }
    }
    return transformed
  }
}
