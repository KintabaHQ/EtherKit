//
//  UnformattedDataType.swift
//  BigInt
//
//  Created by Cole Potrocky on 3/22/18.
//

import Marshal

public enum UnformattedDataMode {
  case constrained(Int)
  case unlimited

  static func == (lhs: UnformattedDataMode, rhs: UnformattedDataMode) -> Bool {
    switch (lhs, rhs) {
    case let (.constrained(leftVal), .constrained(rightVal)):
      return leftVal == rightVal
    case (.unlimited, .unlimited):
      return true
    default:
      return false
    }
  }
}

public protocol UnformattedDataType: CustomStringConvertible, ValueType, RLPValueType, Hashable, Codable {
  static var byteCount: UnformattedDataMode { get }
  static func value(from data: Data) throws -> Self

  var data: Data { get }

  init(data: Data)
  init(describing: String) throws
}

extension UnformattedDataType {
  public static func value(from data: Data) throws -> Self {
    return Self(data: try validateData(for: data))
  }

  // MARK: - ValueType

  public static func value(from object: Any) throws -> Self {
    guard let dataString = object as? String else {
      throw MarshalError.typeMismatch(expected: String.self, actual: type(of: object))
    }

    return try Self(describing: dataString)
  }

  public init(describing: String) throws {
    guard let data = describing.hexToBytes else {
      throw EtherKitError.dataConversionFailed(reason: .scalarConversionFailed(forValue: describing, toType: Data.self))
    }
    self.init(data: try Self.validateData(for: data))
  }

  static func validateData(for data: Data) throws -> Data {
    switch Self.byteCount {
    case let .constrained(by):
      guard data.count == by else {
        throw EtherKitError.dataConversionFailed(reason: .wrongSize(expected: by, actual: data.count))
      }
    case .unlimited:
      break
    }
    return data
  }

  // MARK: - CustomStringConvertible

  public var description: String {
    return data.paddedHexString
  }

  // MARK: - RLPValueType

  public func toRLPData(lift: @escaping (Data) -> RLPData) -> RLPData {
    return data.toRLPData(lift: lift)
  }

  // MARK: - Codable

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(String(describing: self))
  }

  public init(from decoder: Decoder) throws {
    var container = try decoder.singleValueContainer()
    try self.init(describing: try container.decode(String.self))
  }
}
