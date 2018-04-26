//
//  Network.swift
//  EtherKit
//
//  Created by Cole Potrocky on 3/17/18.
//

import Marshal

public enum Network {
  case main
  case morden
  case ropstein
  case rinkeby
  case kovan
  case nonStandard(number: UInt)
}

extension Network: RawRepresentable {
  public typealias RawValue = UInt

  public init?(rawValue: RawValue) {
    switch rawValue {
    case 1: self = .main
    case 2: self = .morden
    case 3: self = .ropstein
    case 4: self = .rinkeby
    case 42: self = .kovan
    default: self = .nonStandard(number: rawValue)
    }
  }

  public var rawValue: RawValue {
    switch self {
    case .main: return 1
    case .morden: return 2
    case .ropstein: return 3
    case .rinkeby: return 4
    case .kovan: return 42
    case let .nonStandard(number):
      return number
    }
  }
}

extension Network: ValueType {
  public static func value(from object: Any) throws -> Network {
    var rawValue: UInt?
    if let object = object as? String {
      rawValue = UInt(object)
    } else if let object = object as? UInt {
      rawValue = object
    }
    guard let value = rawValue, let network = Network(rawValue: value) else {
      throw MarshalError.typeMismatch(expected: Network.self, actual: type(of: object))
    }
    return network
  }
}
