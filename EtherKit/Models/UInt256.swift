//
//  UInt256.swift
//  EtherKit
//
//  Created by Cole Potrocky on 3/21/18.
//

import BigInt
import Marshal

public struct UInt256: Equatable {
  public let value: BigUInt

  public init(_ value: BigUInt, from denomination: Denomination = .wei) {
    self.value = value * denomination.rawValue
  }

  public init(_ value: Double, from denomination: Denomination) {
    self.value = BigUInt(value * Double(denomination.rawValue))
  }

  public init(from: String) throws {
    guard let value = BigUInt(from.dropHexPrefix, radix: 16) else {
      throw EtherKitError.dataConversionFailed(
        reason: .scalarConversionFailed(forValue: from, toType: BigUInt.self)
      )
    }
    self.init(value)
  }

  public func toPaddedData() -> Data {
    var unpaddedValue = value.serialize()
    let paddingAmount = 32 - unpaddedValue.count
    return Data(repeating: 0, count: paddingAmount) + unpaddedValue
  }
}

extension UInt256: CustomStringConvertible {
  public var description: String {
    return "0x\(String(value, radix: 16))"
  }
}

extension UInt256: ValueType {
  public static func value(from object: Any) throws -> UInt256 {
    guard let intStr = object as? String else {
      throw MarshalError.typeMismatch(expected: String.self, actual: type(of: object))
    }

    return try UInt256(from: intStr)
  }
}

extension UInt256: RLPValueType {
  public func toRLPData(lift: @escaping (Data) -> RLPData) -> RLPData {
    return value.toRLPData(lift: lift)
  }
}

extension UInt256: Codable {
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(String(describing: self))
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    try self.init(from: container.decode(String.self))
  }
}
