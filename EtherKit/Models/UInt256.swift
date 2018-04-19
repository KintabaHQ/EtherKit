//
//  UInt256.swift
//  EtherKit
//
//  Created by Cole Potrocky on 3/21/18.
//

import BigInt
import Marshal

public struct UInt256 {
  public let describing: BigUInt

  public init(_ value: BigUInt) {
    describing = value
  }

  public init?(describing: String) {
    guard let value = BigUInt(describing.dropHexPrefix, radix: 16) else {
      return nil
    }
    self.init(value)
  }
}

extension UInt256: CustomStringConvertible {
  public var description: String {
    return "0x\(String(describing, radix: 16))"
  }
}

extension UInt256: ValueType {
  public static func value(from object: Any) throws -> UInt256 {
    guard let intStr = object as? String else {
      throw MarshalError.typeMismatch(expected: String.self, actual: type(of: object))
    }

    guard let uintValue = UInt256(describing: intStr) else {
      throw MarshalError.typeMismatch(expected: UInt256.self, actual: type(of: intStr))
    }

    return uintValue
  }
}
