//
//  TypedData.swift
//  EtherKit
//
//  Created by Zac Morris on 2018-06-14.
//
import BigInt
import Foundation
import Marshal

public struct TypeValue: Unmarshaling {
    var name: String
    var type: String
    
    public init(object: MarshaledObject) throws {
        name = try object.value(for: "name")
        type = try object.value(for: "type")
    }
}

public struct Type: ValueType {
    public var values: [TypeValue]
    
    public static func value(from object: Any) throws -> Type {
        let valueArray: [TypeValue] = try [TypeValue].value(from: object)
        return Type(values: valueArray)
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

enum JSONType {
    case bool(value: Bool)
    case uint(value: UInt)
    case int(value: Int)
    case string(value: String)
}

public struct TypeObject: ValueType {
    var value: JSONType?
    var values: [String: TypeObject]?
    
    public static func value(from object: Any) throws -> TypeObject {
        if let boolValue = object as? Bool {
            return TypeObject(value: JSONType.bool(value: boolValue), values: nil)
        } else if let uintValue = object as? UInt {
            return TypeObject(value: JSONType.uint(value: uintValue), values: nil)
        } else if let intValue = object as? Int {
            return TypeObject(value: JSONType.int(value: intValue), values: nil)
        } else if let stringValue = object as? String {
            return TypeObject(value: JSONType.string(value: stringValue), values: nil)
        } else {
            let values = try [String: TypeObject].value(from: object)
            return TypeObject(value: nil, values: values)
        }
    }
}

public struct TypedData: ValueType {
    public var types: [String: Type]
    public var domain: Domain
    public var primaryType: String
    public var message: TypeObject
    
    public static func value(from object: Any) throws -> TypedData {
        guard let valueMaps = object as? [String: Any],
            let types: [String: Type] = try? valueMaps.value(for: "types"),
            let domain: Domain = try? valueMaps.value(for: "domain"),
            let primaryType: String = try? valueMaps.value(for: "primaryType"),
            let message: TypeObject = try? valueMaps.value(for: "message") else {
            fatalError()
        }
        
        return TypedData(types: types, domain: domain, primaryType: primaryType, message: message)
    }
}
