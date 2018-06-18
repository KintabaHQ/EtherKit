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
    
    public func encode() -> String {
        return "\(type) \(name)"
    }
}

public struct Type: ValueType {
    public var properties: [TypeProperty]
    
    public static func value(from object: Any) throws -> Type {
        let propertyArray: [TypeProperty] = try [TypeProperty].value(from: object)
        return Type(properties: propertyArray)
    }
    
    public func encodeProperties() -> String {
        let encodedProps = properties.map { prop in
            return prop.encode()
        }
        return "(" + encodedProps.joined(separator: ",") + ")"
    }
    
    public func getSubTypes() -> [String] {
        let standardTypes: [String] = ["bool", "uint", "int", "string", "address", "bytes"]
        
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
}

public struct Types {
    public var types: [String: Type]
    
    subscript(typeName: String) -> Type? {
        get { return types[typeName] }
        set { types[typeName] = newValue }
    }
    
    public func getTypeHash(for mainTypeName: String) throws -> Data {
        guard let mainType = types[mainTypeName] else {
            fatalError()
        }
        
        var subTypes: [String] = mainType.getSubTypes()
        var seenTypes: [String] = []
        while subTypes.count > 0 {
            let typeName = subTypes.removeFirst()
            if seenTypes.contains(typeName) {
                continue
            }
            seenTypes.append(typeName)
            
            guard let subType = types[typeName] else {
                fatalError()
            }
            subTypes.append(contentsOf: subType.getSubTypes())
        }
        
        seenTypes = seenTypes.sorted()
        var encodedTypes = "\(mainTypeName)\(mainType.encodeProperties())"
        for typeName in seenTypes {
            guard let subType = types[typeName] else {
                fatalError()
            }
            encodedTypes.append("\(typeName)\(subType.encodeProperties())")
        }
        
        return Data(bytes: Array(encodedTypes.utf8)).sha3(.keccak256)
    }
}

public struct Domain: Unmarshaling {
    public var name: String?
    public var version: String?
    public var chainId: UInt?
    public var verifyingContract: Address?
    public var salt: String?
    
    public init(object: MarshaledObject) throws {
        name = try object.value(for: "name")
        version = try object.value(for: "version")
        chainId = try object.value(for: "chainId")
        verifyingContract = try object.value(for: "verifyingContract")
        salt = try object.value(for: "salt")
    }
}

public enum MessageValue {
    case bool(value: Bool)
    case uint(size: Int, value: BigUInt)
    case int(size: Int, value: BigInt)
    case string(value: String)
    case address(value: Address)
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
        } else if type == "string" {
            let stringVal = try String.value(from: object)
            return MessageValue.string(value: stringVal)
        } else if type == "address" {
            let addressVal = try Address.value(from: object)
            return MessageValue.address(value: addressVal)
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
            let messageObject = try MessageObject(from: subObject, types: types, typeString: type)
            return MessageValue.object(type: type, value: messageObject)
        }
    }
}

public struct MessageObject {
    public var values: [String: MessageValue] = [:]
    
    public init(from object: [String: Any], types: Types, typeString: String) throws {
        guard let type = types[typeString] else {
            throw EtherKitError.web3Failure(reason: .parsingFailure)
        }
        for prop in type.properties {
            guard let valueObject: Any = object[prop.name] else {
                throw EtherKitError.web3Failure(reason: .parsingFailure)
            }
            values[prop.name] = try MessageValue.getMessageValue(from: valueObject, type: prop.type, types: types)
        }
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
            let message = try? MessageObject(from: messageObject, types: types, typeString: primaryType) else {
            throw EtherKitError.web3Failure(reason: .parsingFailure)
        }
        
        return TypedData(types: types, domain: domain, primaryType: primaryType, message: message)
    }
    
    public func getTypeHash() throws -> Data {
        return try types.getTypeHash(for: primaryType)
    }
    
    public func getEncodedData() throws -> Data {

    }
}







































