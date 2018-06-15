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
}

public struct Type: ValueType {
    public var properties: [TypeProperty]
    
    public static func value(from object: Any) throws -> Type {
        let propArray: [TypeProperty] = try [TypeProperty].value(from: object)
        return Type(properties: propArray)
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
    case bytes(size: Int, value: Data)
    case dynamicBytes(value: Data)
    case array(size: Int, value: [MessageValue])
    case dynamicArray(value: [MessageValue])
    case message(type: String, value: Message)
}

public struct Message {
    public var values: [String: MessageValue] = [:]
    
    public init(from object: [String: Any], types: [String: Type], typeString: String) throws {
        guard let type = types[typeString] else {
            fatalError()
        }
        for prop in type.properties {
            if prop.type == "bool" {
                let boolVal: Bool = try object.value(for: prop.name)
                values[prop.name] = MessageValue.bool(value: boolVal)
            } else if prop.type.starts(with: "uint") {
                guard let size = Int(prop.type.dropFirst(4)) else {
                    fatalError()
                }
                if let uintVal: UInt = try? object.value(for: prop.name) {
                    values[prop.name] = MessageValue.uint(size: size, value: BigUInt(uintVal))
                } else if let stringVal: String = try? object.value(for: prop.name),
                    let bigUInt = BigUInt(stringVal) {
                    values[prop.name] = MessageValue.uint(size: size, value: bigUInt)
                } else {
                    fatalError()
                }
            } else if prop.type.starts(with: "int") {
                guard let size = Int(prop.type.dropFirst(3)) else {
                    fatalError()
                }
                if let intVal: Int = try? object.value(for: prop.name) {
                    values[prop.name] = MessageValue.int(size: size, value: BigInt(intVal))
                } else if let stringVal: String = try? object.value(for: prop.name),
                    let bigInt = BigInt(stringVal) {
                    values[prop.name] = MessageValue.int(size: size, value: bigInt)
                } else {
                    fatalError()
                }
            } else if prop.type == "string" {
                let stringVal: String = try object.value(for: prop.name)
                values[prop.name] = MessageValue.string(value: stringVal)
            } else if prop.type == "address" {
                let addressVal: Address = try object.value(for: prop.name)
                values[prop.name] = MessageValue.address(value: addressVal)
            } else if prop.type.starts(with: "bytes") {
                guard let stringVal: String = try? object.value(for: prop.name) else {
                    fatalError()
                }
                let data = Data(hex: stringVal)
                if let size = Int(prop.type.dropFirst(5)) {
                    values[prop.name] = MessageValue.bytes(size: size, value: data)
                } else {
                    values[prop.name] = MessageValue.dynamicBytes(value: data)
                }
            } else if prop.type.contains("[") && prop.type.contains("]") {
                var parts = prop.type.components(separatedBy: CharacterSet(charactersIn: "[]"))
                let type = parts[0]
                if let size = Int(parts[1]) {
                    
                } else {
                    
                }
            } else {
                guard let messageObject: [String: Any] = try object.value(for: prop.name),
                    let message = try? Message(from: messageObject, types: types, typeString: prop.type) else {
                    fatalError()
                }
                values[prop.name] = MessageValue.message(type: prop.type, value: message)
            }    
        }
    }
}

public struct TypedData: ValueType {
    public var types: [String: Type]
    public var domain: Domain
    public var primaryType: String
    public var message: Message
    
    public static func value(from object: Any) throws -> TypedData {
        guard let valueMaps = object as? [String: Any],
            let types: [String: Type] = try? valueMaps.value(for: "types"),
            let domain: Domain = try? valueMaps.value(for: "domain"),
            let primaryType: String = try? valueMaps.value(for: "primaryType"),
            let messageObject: [String: Any] = try? valueMaps.value(for: "message") else {
            fatalError()
        }
        
        guard let message = try? Message(from: messageObject, types: types, typeString: primaryType) else {
            fatalError()
        }
        
        return TypedData(types: types, domain: domain, primaryType: primaryType, message: message)
    }
}
