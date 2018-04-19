//
//  UnformattedDataType.swift
//  BigInt
//
//  Created by Cole Potrocky on 3/22/18.
//

import Marshal

public enum UnformattedDataMode {
  case constrained(UInt)
  case unlimited
}

protocol UnformattedDataType: CustomStringConvertible, ValueType {
  static var byteCount: UnformattedDataMode { get }
  var describing: [UInt8] { get }

  init(describing: [UInt8])
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
  
  public var description: String {
    return describing.reduce("0x") { return "\($0)\(String(format: "%02x", $1))" }
  }
  
  public init?(describing: String) {
    guard let describing = describing.hexToBytes else {
      return nil
    }
    
    switch Self.byteCount {
    case .constrained(let by):
      guard describing.count == by else {
        return nil
      }
    case .unlimited:
      break
    }
    
    self.init(describing: describing)
  }
}

