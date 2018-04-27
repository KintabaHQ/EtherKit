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
}

protocol UnformattedDataType: CustomStringConvertible, ValueType {
  static var byteCount: UnformattedDataMode { get }
  static func value(from data: Data) throws -> Self

  var data: Data { get }

  init(data: Data)
  init?(describing: String)
}

extension UnformattedDataType {
  public static func value(from object: Any) throws -> Self {
    guard let dataString = object as? String else {
      throw MarshalError.typeMismatch(expected: String.self, actual: type(of: object))
    }

    guard let dataObject = Self(describing: dataString) else {
      throw MarshalError.typeMismatch(expected: Self.self, actual: type(of: dataString))
    }

    return dataObject
  }

  public static func value(from data: Data) throws -> Self {
    switch Self.byteCount {
    case let .constrained(by):
      guard data.count == by else {
        throw EtherKitError.invalidDataSize(expected: by, actual: data.count)
      }
    case .unlimited:
      break
    }

    return Self(data: data)
  }

  public var description: String {
    return data.paddedHexString
  }

  public init?(describing: String) {
    guard let data = describing.hexToBytes else {
      return nil
    }

    switch Self.byteCount {
    case let .constrained(by):
      guard data.count == by else {
        return nil
      }
    case .unlimited:
      break
    }

    self.init(data: data)
  }
}
