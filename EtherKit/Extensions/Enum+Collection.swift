//
//  Enum+Collection.swift
//  EtherKit
//
//  Created by Zac Morris on 2018-08-08.
//  Copyright © 2018 Vault. All rights reserved.
//
// Taken from https://theswiftdev.com/2017/10/12/swift-enum-all-values/
//

public protocol EnumCollection: Hashable {
  static func cases() -> AnySequence<Self>
  static var allValues: [Self] { get }
}

public extension EnumCollection {
  public static func cases() -> AnySequence<Self> {
    return AnySequence { () -> AnyIterator<Self> in
      var raw = 0
      return AnyIterator {
        let current: Self = withUnsafePointer(to: &raw) { $0.withMemoryRebound(to: self, capacity: 1) { $0.pointee } }
        guard current.hashValue == raw else {
          return nil
        }
        raw += 1
        return current
      }
    }
  }

  public static var allValues: [Self] {
    return Array(cases())
  }
}
