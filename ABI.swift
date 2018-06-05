//
//  ABI.swift
//  Apollo
//
//  Created by Zac Morris on 2018-06-01.
//

import BigInt

public struct ABIData: UnformattedDataType {
    public static var byteCount: UnformattedDataMode {
        return .unlimited
    }

    public let data: Data
    
    public init(data: Data) {
        self.data = data
    }
    
    public static func encode<T: ABIValueType>(from: T) -> ABIData {
        return from.toABIData { ABIData(data: $0) }
    }
}

public protocol ABIValueType {
    var isDynamic: Bool { get }
    func toABIData(lift: @escaping (Data) -> ABIData) -> ABIData
}

extension Data: ABIValueType {
    public var isDynamic: Bool {
        if self.count > 32 {
            return true
        } else {
            return false
        }
    }
    
    public func toABIData(lift: @escaping (Data) -> ABIData) -> ABIData {
        var data = Data()
        if self.count > 32 {
            let sizeData = ABIData.encode(from: self.count)
            data.append(sizeData.data)
        }

        data.append(self)
        let padding = (self.count + (32 - (self.count % 32)))
        data.append(Data(repeating: 0, count: padding))
        return lift(data)
    }
}

extension String: ABIValueType {
    public var isDynamic: Bool {
        return true
    }
    
    public func toABIData(lift: @escaping (Data) -> ABIData) -> ABIData {
        guard let bytes = self.data(using: .utf8) else {
            fatalError()
        }

        var data = Data()
        let sizeData = ABIData.encode(from: bytes.count)
        data.append(sizeData.data)

        data.append(bytes)
        let padding = (bytes.count + (32 - (bytes.count % 32)))
        data.append(Data(repeating: 0, count: padding))
        return lift(data)
    }
}

extension Address: ABIValueType {
    public var isDynamic: Bool {
        return false
    }
    
    public func toABIData(lift: @escaping (Data) -> ABIData) -> ABIData {
        var data = Data()
        let padding = (self.data.count + (32 - (self.data.count % 32)))
        data.append(Data(repeating: 0, count: padding))
        data.append(self.data)
        return lift(data)
    }
}

extension BigInt: ABIValueType {
    public var isDynamic: Bool {
        return false
    }
    
    public func toABIData(lift: @escaping (Data) -> ABIData) -> ABIData {
        let magnitude = self.magnitude
        let valueData: Data
        if self.sign == .plus {
            valueData = magnitude.serialize()
        } else {
            let serializedLength = magnitude.serialize().count
            let max = BigUInt(1) << (serializedLength * 8)
            valueData = (max - magnitude).serialize()
        }
        
        if valueData.count > 32 {
            fatalError()
        }
        
        var data = Data()
        if self.sign == .plus {
            data.append(Data(repeating: 0, count: 32 - valueData.count))
        } else {
            data.append(Data(repeating: 255, count: 32 - valueData.count))
        }
        data.append(valueData)
        return lift(data)
    }
}

extension BigUInt: ABIValueType {
    public var isDynamic: Bool {
        return false
    }
    
    public func toABIData(lift: @escaping (Data) -> ABIData) -> ABIData {
        let valueData = self.serialize()
        if valueData.count > 32 {
            fatalError()
        }
        
        var data = Data()
        data.append(Data(repeating: 0, count: 32 - valueData.count))
        data.append(valueData)
        return lift(data)
    }
}
    
extension Int: ABIValueType {
    public var isDynamic: Bool {
        return false
    }
    
    public func toABIData(lift: @escaping (Data) -> ABIData) -> ABIData {
        return BigInt(self).toABIData(lift: lift)
    }
}

extension UInt: ABIValueType {
    public var isDynamic: Bool {
        return false
    }
    
    public func toABIData(lift: @escaping (Data) -> ABIData) -> ABIData {
        return BigUInt(self).toABIData(lift: lift)
    }
}

extension Bool: ABIValueType {
    public var isDynamic: Bool {
        return false
    }
    
    public func toABIData(lift: @escaping (Data) -> ABIData) -> ABIData {
        var data = Data()
        data.append(Data(repeating: 0, count: 31))
        data.append(self ? 1 : 0)
        return lift(data)
    }
}

extension Array: ABIValueType where Element == ABIValueType {
    public var isDynamic: Bool {
        return self.contains(where: { $0.isDynamic })
    }
    
    public func toABIData(lift: @escaping (Data) -> ABIData) -> ABIData {
        var headSize = 0
        for subValue in self {
            if subValue.isDynamic {
                headSize += 32
            } else {
                let subData = subValue.toABIData(lift: lift).data
                headSize += subData.count
            }
        }
        
        var data = Data()
        var dynamicOffset = 0
        for subValue in self {
            let subData = subValue.toABIData(lift: lift).data
            if subValue.isDynamic {
                let sizeData = ABIData.encode(from: headSize + dynamicOffset)
                data.append(sizeData.data)
                dynamicOffset += subData.count
            } else {
                data.append(subData)
            }
        }
        
        for subValue in self where subValue.isDynamic {
            let subData = subValue.toABIData(lift: lift).data
            data.append(subData)
        }
        return lift(data)
    }
}
