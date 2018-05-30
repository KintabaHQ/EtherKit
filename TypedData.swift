//
//  TypedData.swift
//  EtherKit
//
//  Created by Zac Morris on 2018-06-04.
//

import BigInt
import Foundation

public struct TypedData: Decodable {
    public let type: String
    public let name: String
    public let value: String
    
    var schemaString: String {
        return "\(type) \(name)"
    }
    
    public var schemaData: Data {
        return Data(bytes: Array(schemaString.utf8))
    }
    
    public var typedData: Data {
        if type.starts(with: "int") {
            if let int = BigInt(value), let size = Int(type.dropFirst(3)) {
                let magnitude = int.magnitude
                var valueData = magnitude.serialize()
                if int.sign == .minus {
                    let serializedLength = magnitude.serialize().count
                    let max = BigUInt(1) << (serializedLength * 8)
                    valueData = (max - magnitude).serialize()
                }

                var data = Data()
                let padding = (size/8) - valueData.count
                if int.sign == .minus {
                    data.append(Data(repeating: 255, count: padding))
                } else {
                    data.append(Data(repeating: 0, count: padding))
                }
                data.append(valueData)

                return data
            }
        } else if type.starts(with: "uint") {
            if let uint = BigUInt(value), let size = Int(type.dropFirst(4)) {
                let valueData = uint.serialize()
                var data = Data()
                let padding = (size/8) - valueData.count
                data.append(Data(repeating: 0, count: padding))
                data.append(valueData)
                return data
            }
        } else if type.starts(with: "bool") {
            if let bool = Bool(value) {
                let byte: UInt8 = bool ? 0x01 : 0x00
                return Data(bytes: [byte])
            }
        } else if type.starts(with: "string") {
            return Data(bytes: Array(value.utf8))
        } else if type.starts(with: "address") {
            if let address = try? Address(describing: value) {
                return address.data
            }
        } else if type.starts(with: "bytes") {
            return Data(hex: value)
        }
        return Data()
    }
}
