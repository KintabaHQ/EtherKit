//
//  TypedData.swift
//  EtherKit
//
//  Created by Zac Morris on 2018-06-14.
//
import BigInt
import Foundation
import Marshal

// Represents the definition of a member variable for a struct type
public struct MemberVariable: Unmarshaling {
  var name: String
  var type: String

  public init(object: MarshaledObject) throws {
    name = try object.value(for: "name")
    type = try object.value(for: "type")
  }
}

extension MemberVariable: CustomStringConvertible {
  // Encodes this member variable
  public var description: String {
    return "\(type) \(name)"
  }
}

// Represents the collection of member variables defining a struct type
public struct StructTypeDefinition: ValueType {
  public var members: [MemberVariable]

  public static func value(from object: Any) throws -> StructTypeDefinition {
    let memberArray: [MemberVariable] = try [MemberVariable].value(from: object)
    return StructTypeDefinition(members: memberArray)
  }

  // Returns the collection of struct types used as a member variable by this struct type
  public func getSubStructTypes() -> Set<String> {
    let standardTypes: Set<String> = ["bool", "uint", "int", "address", "string", "bytes"]

    let subTypes: Set<String> = members.reduce(into: Set<String>(), { set, prop in
      let subType = prop.type.components(separatedBy: "[")[0]
      let matches = standardTypes.contains { type in
        return subType.starts(with: type)
      }
      if !matches {
        set.insert(subType)
      }
    })
    return subTypes
  }
}

extension StructTypeDefinition: CustomStringConvertible {
  // Encodes the member variables for this struct type
  public var description: String {
    let encodedMems: [String] = members.map { member in
      return String(describing: member)
    }
    return "(" + encodedMems.joined(separator: ",") + ")"
  }
}

// Extends the dictionary representing type name to the struct type definition
public extension Dictionary where Key == String, Value == StructTypeDefinition {
  // Returns the typeHash representation for the named struct type
  public func getTypeHash(for typeName: String) throws -> Data {
    guard let mainType = self[typeName] else {
      throw EtherKitError.web3Failure(reason: .parsingFailure)
    }

    var subTypes: Set<String> = mainType.getSubStructTypes()
    var seenTypes: Set<String> = []
    while subTypes.count > 0 {
      let subName = subTypes.removeFirst()
      if seenTypes.contains(subName) {
        continue
      }
      seenTypes.insert(subName)

      guard let subType = self[subName] else {
        throw EtherKitError.web3Failure(reason: .parsingFailure)
      }
      subTypes.formUnion(subType.getSubStructTypes())
    }

    var encodedTypes = "\(typeName)\(mainType)"
    let sortedTypes = seenTypes.sorted()
    for seenName in sortedTypes {
      guard let subType = self[seenName] else {
        throw EtherKitError.web3Failure(reason: .parsingFailure)
      }
      encodedTypes.append("\(seenName)\(subType)")
    }
    return Data(bytes: Array(encodedTypes.utf8)).sha3(.keccak256)
  }
}

// Represents the EIP712Domain data for a given typed data message
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

  // Encodes the data representing the domain
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

// Represents the value of a member variable in a struct type data
public enum MemberValue {
  case bool(value: Bool)
  case uint(size: Int, value: BigUInt)
  case int(size: Int, value: BigInt)
  case address(value: Address)
  case string(value: String)
  case bytes(count: UnformattedDataMode, value: Data)
  case array(count: UnformattedDataMode, value: [MemberValue])
  case structData(type: String, value: StructTypeData)

  // Initialize a new member value from a marshaled object
  public init(from object: Any, type: String, types: [String: StructTypeDefinition]) throws {
    if type == "bool" {
      let boolVal = try Bool.value(from: object)
      self = MemberValue.bool(value: boolVal)
    } else if type.starts(with: "uint") {
      guard let size = Int(type.dropFirst(4)) else {
        throw EtherKitError.web3Failure(reason: .parsingFailure)
      }
      if let uintVal = try? UInt.value(from: object) {
        self = MemberValue.uint(size: size, value: BigUInt(uintVal))
      } else if let stringVal = try? String.value(from: object),
        let bigUInt = BigUInt(stringVal) {
        self = MemberValue.uint(size: size, value: bigUInt)
      } else {
        throw EtherKitError.web3Failure(reason: .parsingFailure)
      }
    } else if type.starts(with: "int") {
      guard let size = Int(type.dropFirst(3)) else {
        throw EtherKitError.web3Failure(reason: .parsingFailure)
      }
      if let intVal = try? Int.value(from: object) {
        self = MemberValue.int(size: size, value: BigInt(intVal))
      } else if let stringVal = try? String.value(from: object),
        let bigInt = BigInt(stringVal) {
        self = MemberValue.int(size: size, value: bigInt)
      } else {
        throw EtherKitError.web3Failure(reason: .parsingFailure)
      }
    } else if type == "address" {
      let addressVal = try Address.value(from: object)
      self = MemberValue.address(value: addressVal)
    } else if type == "string" {
      let stringVal = try String.value(from: object)
      self = MemberValue.string(value: stringVal)
    } else if type.starts(with: "bytes") {
      let stringVal = try String.value(from: object)
      let data = Data(hex: stringVal)
      if let count = Int(type.dropFirst(5)) {
        self = MemberValue.bytes(count: .constrained(count), value: data)
      } else {
        self = MemberValue.bytes(count: .unlimited, value: data)
      }
    } else if type.contains("[") && type.contains("]") {
      var parts = type.components(separatedBy: CharacterSet(charactersIn: "[]"))
      let subType = parts[0]
      guard let objectArray = object as? [Any] else {
        throw EtherKitError.web3Failure(reason: .parsingFailure)
      }
      var valueArray: [MemberValue] = []
      for valueObject in objectArray {
        let subValue = try MemberValue(from: valueObject, type: subType, types: types)
        valueArray.append(subValue)
      }
      if let count = Int(parts[1]) {
        self = MemberValue.array(count: .constrained(count), value: valueArray)
      } else {
        self = MemberValue.array(count: .unlimited, value: valueArray)
      }
    } else {
      guard let subObject = object as? [String: Any] else {
        throw EtherKitError.web3Failure(reason: .parsingFailure)
      }
      let structData = try StructTypeData(from: subObject, typeName: type, types: types)
      self = MemberValue.structData(type: type, value: structData)
    }
  }

  // Encodes the data representing this struct type
  public func encodeData(types: [String: StructTypeDefinition]) throws -> Data {
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
    case let .structData(type, value):
      let typeHash = try types.getTypeHash(for: type)
      let encodedData = try value.encodeData(typeName: type, types: types)
      return (typeHash + encodedData).sha3(.keccak256)
    }
  }
}

// Represents a data instance of a struct type
public struct StructTypeData {
  public var values: [String: MemberValue] = [:]

  public init(from object: [String: Any], typeName: String, types: [String: StructTypeDefinition]) throws {
    guard let type = types[typeName] else {
      throw EtherKitError.web3Failure(reason: .parsingFailure)
    }
    for member in type.members {
      guard let valueObject: Any = object[member.name] else {
        throw EtherKitError.web3Failure(reason: .parsingFailure)
      }
      values[member.name] = try MemberValue(from: valueObject, type: member.type, types: types)
    }
  }

  // Encodes the data representing this struct type instance
  public func encodeData(typeName: String, types: [String: StructTypeDefinition]) throws -> Data {
    guard let mainType = types[typeName] else {
      throw EtherKitError.web3Failure(reason: .parsingFailure)
    }

    var data = Data()
    for member in mainType.members {
      guard let subVal = values[member.name],
        let subData = try? subVal.encodeData(types: types) else {
        throw EtherKitError.web3Failure(reason: .parsingFailure)
      }
      data.append(subData)
    }
    return data
  }
}

// Represents a complete instance of a typed data message
public struct TypedData: ValueType {
  public var types: [String: StructTypeDefinition]
  public var domain: Domain
  public var primaryType: String
  public var message: StructTypeData

  public static func value(from object: Any) throws -> TypedData {
    guard let valueMaps = object as? [String: Any],
      let types: [String: StructTypeDefinition] = try? valueMaps.value(for: "types"),
      let domain: Domain = try? valueMaps.value(for: "domain"),
      let primaryType: String = try? valueMaps.value(for: "primaryType"),
      let messageObject: [String: Any] = try? valueMaps.value(for: "message"),
      let message = try? StructTypeData(from: messageObject, typeName: primaryType, types: types) else {
      throw EtherKitError.web3Failure(reason: .parsingFailure)
    }

    return TypedData(types: types, domain: domain, primaryType: primaryType, message: message)
  }

  // Returns the hashed domain used as domain separator when signing
  public func hashDomain() throws -> Data {
    let typeHash = try types.getTypeHash(for: "EIP712Domain")
    let encodedData = try domain.encodeData()
    return (typeHash + encodedData).sha3(.keccak256)
  }

  // Returns the type hash for this typed data messaged used for hashing
  public func getTypeHash() throws -> Data {
    return try types.getTypeHash(for: primaryType)
  }

  // Encodes the data for this typed data message used for hashing
  public func encodeData() throws -> Data {
    return try message.encodeData(typeName: primaryType, types: types)
  }

  // Hashes the entire typed data message for use when signing
  public func hash() throws -> Data {
    let typeHash = try getTypeHash()
    let encodedData = try encodeData()
    return (typeHash + encodedData).sha3(.keccak256)
  }
}

// Returns the data representation of a typed data message for signing based on EIP-712 spec
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#specification
extension TypedData: Signable {
  public func signatureData(_: Network?) -> Data {
    guard let domainSeparator = try? hashDomain(),
      let hashStruct = try? hash() else {
      fatalError()
    }
    var data = Data()
    data.append(0x19)
    data.append(0x01)
    data.append(domainSeparator)
    data.append(hashStruct)

    return data.sha3(.keccak256)
  }

  public var usesReplayProtection: Bool {
    return true
  }
}
