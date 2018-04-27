//
//  RLP.swift
//  EtherKit
//
//  Created by Cole Potrocky on 4/26/18.
//

import BigInt

public struct RLPData: UnformattedDataType {
  static var byteCount: UnformattedDataMode {
    return .unlimited
  }

  public static func value(from: RLPValueType) -> RLPData {
    print(from, type(of: from))
    return from.toRLPValue { RLPData(data: $0) }
  }

  public let data: Data
}

public protocol RLPValueType {
  func toRLPValue(lift: @escaping (Data) -> RLPData) -> RLPData
}

public protocol RLPElementType: RLPValueType {
  var packedData: Data { get }
}

extension RLPElementType {
  public func toRLPValue(lift: @escaping (Data) -> RLPData) -> RLPData {
    let data = packedData
    let byteCount = data.count
    if byteCount == 1, let first = data.first, first < 128 {
      return lift(data)
    }

    var newData: Data
    switch byteCount {
    case 0 ... 55:
      newData = Data(bytes: [UInt8(128 + byteCount)])
      newData.append(contentsOf: data)
    case _ where byteCount > 55:
      let countAsData = byteCount.packedData
      newData = Data(bytes: [UInt8(183 + countAsData.count)])
      newData.append(countAsData)
      newData.append(contentsOf: data)
    default:
      fatalError()
    }
    return lift(newData)
  }
}

extension String: RLPElementType {
  public var packedData: Data {
    return data(using: .utf8)!
  }
}

extension FixedWidthInteger {
  public var packedData: Data {
    var asBE = bigEndian
    var data = Data(bytes: &asBE, count: MemoryLayout.size(ofValue: self))
    data.removeFirst(asBE.trailingZeroBitCount / 8)
    return data
  }
}

extension Int: RLPElementType {}
extension UInt: RLPElementType {}
extension UInt8: RLPElementType {}
extension UInt16: RLPElementType {}
extension UInt32: RLPElementType {}
extension BigUInt: RLPElementType {
  public var packedData: Data {
    return serialize()
  }
}

extension Array: RLPValueType where Element: RLPValueType {
  public func toRLPValue(lift: @escaping (Data) -> RLPData) -> RLPData {
    let listData = reduce(into: Data()) { acc, val in acc.append(contentsOf: val.toRLPValue(lift: lift).data) }
    let byteCount = listData.count

    var newData: Data
    switch byteCount {
    case 0 ... 55:
      newData = Data(bytes: [UInt8(192 + listData.count)])
      newData.append(listData)
    case _ where byteCount > 55:
      let countAsData = count.toRLPValue(lift: lift).data
      newData = Data(bytes: [UInt8(247 + countAsData.count)])
      newData.append(countAsData)
      newData.append(contentsOf: listData)

    default:
      fatalError()
    }
    return lift(newData)
  }
}
