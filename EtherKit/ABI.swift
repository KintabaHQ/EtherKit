//
//  ABI.swift
//  Apollo
//
//  Created by Zac Morris on 2018-07-20.
//

import BigInt

public indirect enum ABIType: CustomStringConvertible {
  case bool(value: Bool)
  case int(size: Int, value: BigInt)
  case uint(size: Int, value: BigUInt)
  case string(value: String)
  case address(value: Address)
  case bytes(count: UnformattedDataMode, value: Data)
  case array(count: UnformattedDataMode, type: ABIType, value: [ABIType])
  case functionSelector(name: String, parameterTypes: [ABIType], contract: Address?)

  public var description: String {
    switch self {
    case .bool:
      return "bool"
    case let .int(size, _):
      return "int\(size)"
    case let .uint(size, _):
      return "uint\(size)"
    case .string:
      return "string"
    case .address:
      return "address"
    case let .bytes(constraint, _):
      switch constraint {
      case .unlimited:
        return "bytes"
      case let .constrained(count):
        return "bytes\(count)"
      }
    case let .array(constraint, type, _):
      switch constraint {
      case .unlimited:
        return String(describing: type) + "[]"
      case let .constrained(count):
        return String(describing: type) + "[\(count)]"
      }
    case let .functionSelector(name, parameterTypes, _):
      let parameterString = parameterTypes
        .compactMap { String(describing: $0) }
        .joined(separator: ",")
      return "\(name)(\(parameterString))"
    }
  }

  public var isDynamic: Bool {
    switch self {
    case .bool:
      return false
    case .int:
      return false
    case .uint:
      return false
    case .string:
      return true
    case .address:
      return false
    case let .bytes(constraint, _):
      switch constraint {
      case .unlimited:
        return true
      case .constrained:
        return false
      }
    case let .array(constraint, type, _):
      switch constraint {
      case .unlimited:
        return true
      case .constrained:
        return type.isDynamic
      }
    case .functionSelector:
      return false
    }
  }

  public func encode() -> Data {
    var data = Data()
    switch self {
    case let .bool(value):
      data.append(Data(repeating: 0, count: 31))
      data.append(value ? 1 : 0)
    case let .int(_, value):
      let magnitude = value.magnitude
      let valueData: Data
      if value.sign == .plus {
        valueData = magnitude.serialize()
      } else {
        let serializedLength = magnitude.serialize().count
        let max = BigUInt(1) << (serializedLength * 8)
        valueData = (max - magnitude).serialize()
      }

      if valueData.count > 32 {
        fatalError()
      }

      if value.sign == .plus {
        data.append(Data(repeating: 0, count: 32 - valueData.count))
      } else {
        data.append(Data(repeating: 255, count: 32 - valueData.count))
      }
      data.append(valueData)
    case let .uint(_, value):
      let valueData = value.serialize()
      if valueData.count > 32 {
        fatalError()
      }

      data.append(Data(repeating: 0, count: 32 - valueData.count))
      data.append(valueData)
    case let .address(value):
      let padding = 32 - value.data.count
      data.append(Data(repeating: 0, count: padding))
      data.append(value.data)
    case let .string(value):
      guard let bytes = value.data(using: .utf8) else {
        fatalError()
      }

      let sizeType: ABIType = .uint(size: 256, value: BigUInt(bytes.count))
      data.append(sizeType.encode())
      data.append(bytes)
      let padding = 32 - (bytes.count % 32)
      data.append(Data(repeating: 0, count: padding))
    case let .bytes(constraint, value):
      switch constraint {
      case .unlimited:
        let sizeType: ABIType = .uint(size: 256, value: BigUInt(value.count))
        data.append(sizeType.encode())
      case .constrained:
        break
      }
      data.append(value)
      let padding = 32 - (value.count % 32)
      data.append(Data(repeating: 0, count: padding))
    case let .array(constraint, type, value):
      switch constraint {
      case .unlimited:
        let sizeType: ABIType = .uint(size: 256, value: BigUInt(value.count))
        data.append(sizeType.encode())
      case .constrained:
        break
      }

      var elemDatas: [Data] = []
      for arrayElem in value {
        let elemData = arrayElem.encode()
        elemDatas.append(elemData)
      }

      if type.isDynamic {
        var headData = Data()
        var valueData = Data()
        var dynamicOffset = 32 * elemDatas.count
        for elemData in elemDatas {
          let sizeType: ABIType = .uint(size: 256, value: BigUInt(dynamicOffset))
          headData.append(sizeType.encode())
          dynamicOffset = dynamicOffset + elemData.count
          valueData.append(elemData)
        }
        data.append(headData)
        data.append(valueData)
      } else {
        for elemData in elemDatas {
          data.append(elemData)
        }
      }
    case let .functionSelector(_, _, contract):
      let funcSig = String(describing: self)

      if let contract = contract {
        data.append(contract.abiType.encode())
      }
      guard let asciiBytes = funcSig.data(using: .ascii) else {
        fatalError()
      }
      let fullHash = asciiBytes.sha3(.keccak256)
      data.append(fullHash[0 ..< 4])
    }

    return data
  }
}

public protocol ABIValueType {
  var abiType: ABIType { get }
}

extension Bool: ABIValueType {
  public var abiType: ABIType {
    return .bool(value: self)
  }
}

extension BigInt: ABIValueType {
  public var abiType: ABIType {
    return .int(size: 256, value: self)
  }
}

extension BigUInt: ABIValueType {
  public var isDynamic: Bool {
    return false
  }

  public var abiType: ABIType {
    return .uint(size: 256, value: self)
  }
}

extension Int: ABIValueType {
  public var abiType: ABIType {
    return .int(size: 64, value: BigInt(self))
  }
}

extension UInt: ABIValueType {
  public var abiType: ABIType {
    return .uint(size: 64, value: BigUInt(self))
  }
}

extension Address: ABIValueType {
  public var abiType: ABIType {
    return .address(value: self)
  }
}

extension String: ABIValueType {
  public var abiType: ABIType {
    return .string(value: self)
  }
}

extension Data: ABIValueType {
  public var abiType: ABIType {
    if count > 32 {
      return .bytes(count: .unlimited, value: self)
    } else {
      return .bytes(count: .constrained(count), value: self)
    }
  }
}

extension Array: ABIValueType where Element: ABIValueType {
  public var abiType: ABIType {
    if count == 0 {
      fatalError()
    }
    var valueArray: [ABIType] = []
    for elem in self {
      valueArray.append(elem.abiType)
    }
    return .array(count: .unlimited, type: self[0].abiType, value: valueArray)
  }
}

extension FunctionSelector: ABIValueType {
  public var isDynamic: Bool {
    return false
  }

  public var abiType: ABIType {
    return .functionSelector(name: name, parameterTypes: parameterTypes, contract: contract)
  }
}
