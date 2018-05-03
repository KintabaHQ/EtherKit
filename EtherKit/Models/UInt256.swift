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

  public init(describing: String) throws {
    guard let value = BigUInt(describing.dropHexPrefix, radix: 16) else {
      throw EtherKitError.dataConversionFailed(
        reason: .scalarConversionFailed(forValue: describing, toType: BigUInt.self)
      )
    }
    self.init(value)
  }

  public func toPaddedData() -> Data {
    var unpaddedValue = describing.serialize()
    let paddingAmount = 32 - unpaddedValue.count
    return Data(repeating: 0, count: paddingAmount) + unpaddedValue
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

    return try UInt256(describing: intStr)
  }
}

extension UInt256: RLPValueType {
  public func toRLPData(lift: @escaping (Data) -> RLPData) -> RLPData {
    return describing.toRLPData(lift: lift)
  }
}

extension UInt256: Codable {
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(String(describing: self))
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    try self.init(describing: container.decode(String.self))
  }
}
