//
//  TypedData.swift
//  EtherKit
//
//  Created by Zac Morris on 2018-06-14.
//
import BigInt
import Foundation
import Marshal

public struct TypeProperty: Unmarshaling {
  var name: String
  var type: String

  public init(object: MarshaledObject) throws {
    name = try object.value(for: "name")
    type = try object.value(for: "type")
  }

  public func encodeType() -> String {
    return "\(type) \(name)"
  }
}

public struct Type: ValueType {
  public var properties: [TypeProperty]

  public static func value(from object: Any) throws -> Type {
    let propertyArray: [TypeProperty] = try [TypeProperty].value(from: object)
    return Type(properties: propertyArray)
  }

  public func getSubTypes() -> [String] {
    let standardTypes: [String] = ["bool", "uint", "int", "address", "string", "bytes"]

    let subTypes: [String] = properties.reduce([String](), { arr, prop in
      var subType = prop.type
      let matches = standardTypes.contains { type in
        return subType.starts(with: type)
      }
      if !matches {
        if subType.contains("[") {
          subType = subType.components(separatedBy: "[")[0]
        }
        if !arr.contains(subType) {
          var newArr: [String] = arr
          newArr.append(subType)
          return newArr
        }
      }
      return arr
    })
    return subTypes
  }

  public func encodeProperties() -> String {
    let encodedProps = properties.map { prop in
      return prop.encodeType()
    }
    return "(" + encodedProps.joined(separator: ",") + ")"
  }
}

public struct Types {
  public var types: [String: Type]

  subscript(typeName: String) -> Type? {
    get { return types[typeName] }
    set { types[typeName] = newValue }
  }

  public func getTypeHash(for typeName: String) throws -> Data {
    guard let mainType = types[typeName] else {
      throw EtherKitError.web3Failure(reason: .parsingFailure)
    }

    var subTypes: [String] = mainType.getSubTypes()
    var seenTypes: [String] = []
    while subTypes.count > 0 {
      let subName = subTypes.removeFirst()
      if seenTypes.contains(subName) {
        continue
      }
      seenTypes.append(subName)

      guard let subType = types[subName] else {
        throw EtherKitError.web3Failure(reason: .parsingFailure)
      }
      subTypes.append(contentsOf: subType.getSubTypes())
    }

    var encodedTypes = "\(typeName)\(mainType.encodeProperties())"
    seenTypes = seenTypes.sorted()
    for seenName in seenTypes {
      guard let subType = types[seenName] else {
        throw EtherKitError.web3Failure(reason: .parsingFailure)
      }
      encodedTypes.append("\(seenName)\(subType.encodeProperties())")
    }
    return Data(bytes: Array(encodedTypes.utf8)).sha3(.keccak256)
  }
}

public struct Domain: Unmarshaling {
  public var name: String?
  public var version: String?
  public var chainId: BigUInt?
  public var verifyingContract: Address?
  public var salt: Data?

  public init(object: MarshaledObject) throws {
    name = try object.value(for: "name")
    version = try object.value(for: "version")

    if let uint: UInt = try? object.value(for: "chainId") {
      chainId = BigUInt(uint)
    } else if let string: String = try? object.value(for: "chainId"),
      let bigUInt = BigUInt(string) {
      chainId = bigUInt
    }

    verifyingContract = try object.value(for: "verifyingContract")

    if let string: String = try? object.value(for: "salt") {
      salt = Data(hex: string)
    }
  }

  public func encodeData() throws -> Data {
    var data = Data()
    if let name = name {
      data.append(Data(bytes: Array(name.utf8)).sha3(.keccak256))
    }
    if let version = version {
      data.append(Data(bytes: Array(version.utf8)).sha3(.keccak256))
    }
    if let chainId = chainId {
      let valueData = chainId.serialize()
      let padding = 32 - valueData.count
      data.append(Data(repeating: 0, count: padding))
      data.append(valueData)
    }
    if let verifyingContract = verifyingContract {
      let uint = BigUInt(verifyingContract.data)
      let uintData = uint.serialize()
      let padding = 32 - uintData.count
      data.append(Data(repeating: 0, count: padding))
      data.append(uintData)
    }
    if let salt = salt {
      data.append(salt)
    }
    return data
  }
}

public enum MessageValue {
  case bool(value: Bool)
  case uint(size: Int, value: BigUInt)
  case int(size: Int, value: BigInt)
  case address(value: Address)
  case string(value: String)
  case bytes(count: UnformattedDataMode, value: Data)
  case array(count: UnformattedDataMode, value: [MessageValue])
  case object(type: String, value: MessageObject)

  public static func getMessageValue(from object: Any, type: String, types: Types) throws -> MessageValue {
    if type == "bool" {
      let boolVal = try Bool.value(from: object)
      return MessageValue.bool(value: boolVal)
    } else if type.starts(with: "uint") {
      guard let size = Int(type.dropFirst(4)) else {
        throw EtherKitError.web3Failure(reason: .parsingFailure)
      }
      if let uintVal = try? UInt.value(from: object) {
        return MessageValue.uint(size: size, value: BigUInt(uintVal))
      } else if let stringVal = try? String.value(from: object),
        let bigUInt = BigUInt(stringVal) {
        return MessageValue.uint(size: size, value: bigUInt)
      } else {
        throw EtherKitError.web3Failure(reason: .parsingFailure)
      }
    } else if type.starts(with: "int") {
      guard let size = Int(type.dropFirst(3)) else {
        throw EtherKitError.web3Failure(reason: .parsingFailure)
      }
      if let intVal = try? Int.value(from: object) {
        return MessageValue.int(size: size, value: BigInt(intVal))
      } else if let stringVal = try? String.value(from: object),
        let bigInt = BigInt(stringVal) {
        return MessageValue.int(size: size, value: bigInt)
      } else {
        throw EtherKitError.web3Failure(reason: .parsingFailure)
      }
    } else if type == "address" {
      let addressVal = try Address.value(from: object)
      return MessageValue.address(value: addressVal)
    } else if type == "string" {
      let stringVal = try String.value(from: object)
      return MessageValue.string(value: stringVal)
    } else if type.starts(with: "bytes") {
      let stringVal = try String.value(from: object)
      let data = Data(hex: stringVal)
      if let count = Int(type.dropFirst(5)) {
        return MessageValue.bytes(count: .constrained(count), value: data)
      } else {
        return MessageValue.bytes(count: .unlimited, value: data)
      }
    } else if type.contains("[") && type.contains("]") {
      var parts = type.components(separatedBy: CharacterSet(charactersIn: "[]"))
      let subType = parts[0]
      guard let objectArray = object as? [Any] else {
        throw EtherKitError.web3Failure(reason: .parsingFailure)
      }
      var valueArray: [MessageValue] = []
      for valueObject in objectArray {
        let subValue = try MessageValue.getMessageValue(from: valueObject, type: subType, types: types)
        valueArray.append(subValue)
      }
      if let count = Int(parts[1]) {
        return MessageValue.array(count: .constrained(count), value: valueArray)
      } else {
        return MessageValue.array(count: .unlimited, value: valueArray)
      }
    } else {
      guard let subObject = object as? [String: Any] else {
        throw EtherKitError.web3Failure(reason: .parsingFailure)
      }
      let messageObject = try MessageObject(from: subObject, typeName: type, types: types)
      return MessageValue.object(type: type, value: messageObject)
    }
  }

  public func encodeData(types: Types) throws -> Data {
    switch self {
    case let .bool(value):
      var data = Data()
      data.append(Data(repeating: 0, count: 31))
      let valueData: UInt8 = value ? 0x01 : 0x00
      data.append(valueData)
      return data
    case let .uint(_, value):
      var data = Data()
      let valueData = value.serialize()
      let padding = 32 - valueData.count
      data.append(Data(repeating: 0, count: padding))
      data.append(valueData)
      return data
    case let .int(_, value):
      let magnitude = value.magnitude
      var valueData = magnitude.serialize()
      if value.sign == .minus {
        let serializedLength = magnitude.serialize().count
        let max = BigUInt(1) << (serializedLength * 8)
        valueData = (max - magnitude).serialize()
      }
      var data = Data()
      let padding = 32 - valueData.count
      if value.sign == .minus {
        data.append(Data(repeating: 255, count: padding))
      } else {
        data.append(Data(repeating: 0, count: padding))
      }
      data.append(valueData)
      return data
    case let .address(value):
      var data = Data()
      let uint = BigUInt(value.data)
      let uintData = uint.serialize()
      let padding = 32 - uintData.count
      data.append(Data(repeating: 0, count: padding))
      data.append(uintData)
      return data
    case let .string(value):
      let stringData = Data(bytes: Array(value.utf8))
      return stringData.sha3(.keccak256)
    case let .bytes(count, value):
      if count == UnformattedDataMode.unlimited {
        return value.sha3(.keccak256)
      } else {
        var data = Data()
        let padding = 32 - value.count
        data.append(value)
        data.append(Data(repeating: 0, count: padding))
        return data
      }
    case let .array(_, value):
      var data = Data()
      for subVal in value {
        let subData = try subVal.encodeData(types: types)
        data.append(subData)
      }
      return data
    case let .object(type, value):
      let typeHash = try types.getTypeHash(for: type)
      let encodedData = try value.encodeData(typeName: type, types: types)
      return (typeHash + encodedData).sha3(.keccak256)
    }
  }
}

public struct MessageObject {
  public var values: [String: MessageValue] = [:]

  public init(from object: [String: Any], typeName: String, types: Types) throws {
    guard let type = types[typeName] else {
      throw EtherKitError.web3Failure(reason: .parsingFailure)
    }
    for prop in type.properties {
      guard let valueObject: Any = object[prop.name] else {
        throw EtherKitError.web3Failure(reason: .parsingFailure)
      }
      values[prop.name] = try MessageValue.getMessageValue(from: valueObject, type: prop.type, types: types)
    }
  }

  public func encodeData(typeName: String, types: Types) throws -> Data {
    guard let mainType = types[typeName] else {
      fatalError()
    }

    var data = Data()
    for prop in mainType.properties {
      guard let subVal = values[prop.name] else {
        fatalError()
      }
      guard let subData = try? subVal.encodeData(types: types) else {
        fatalError()
      }
      data.append(subData)
    }
    return data
  }
}

public struct TypedData: ValueType {
  public var types: Types
  public var domain: Domain
  public var primaryType: String
  public var message: MessageObject

  public static func value(from object: Any) throws -> TypedData {
    guard let valueMaps = object as? [String: Any],
      let typeDict: [String: Type] = try? valueMaps.value(for: "types") else {
      throw EtherKitError.web3Failure(reason: .parsingFailure)
    }
    let types: Types = Types(types: typeDict)

    guard let domain: Domain = try? valueMaps.value(for: "domain"),
      let primaryType: String = try? valueMaps.value(for: "primaryType"),
      let messageObject: [String: Any] = try? valueMaps.value(for: "message"),
      let message = try? MessageObject(from: messageObject, typeName: primaryType, types: types) else {
      throw EtherKitError.web3Failure(reason: .parsingFailure)
    }

    return TypedData(types: types, domain: domain, primaryType: primaryType, message: message)
  }

  public func getDomainSeparator() throws -> Data {
    let typeHash = try types.getTypeHash(for: "EIP712Domain")
    let encodedData = try domain.encodeData()
    return (typeHash + encodedData).sha3(.keccak256)
  }

  public func getTypeHash() throws -> Data {
    return try types.getTypeHash(for: primaryType)
  }

  public func encodeData() throws -> Data {
    return try message.encodeData(typeName: primaryType, types: types)
  }

  public func getHashStruct() throws -> Data {
    let typeHash = try getTypeHash()
    let encodedData = try encodeData()
    return (typeHash + encodedData).sha3(.keccak256)
  }
}

extension TypedData: Signable {
  public func signatureData(_: Network?) -> Data {
    guard let domainSep = try? getDomainSeparator(),
      let hashedData = try? getHashStruct() else {
      fatalError()
    }
    var data = Data()
    data.append(0x19)
    data.append(0x01)
    data.append(domainSep)
    data.append(hashedData)

    return data.sha3(.keccak256)
  }
}
