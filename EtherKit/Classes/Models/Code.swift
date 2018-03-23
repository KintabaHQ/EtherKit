//
//  Code.swift
//  BigInt
//
//  Created by Cole Potrocky on 3/23/18.
//

public struct Code: UnformattedDataType {
  static var byteCount: UnformattedDataMode {
    return .unlimited
  }
  
  let describing: [UInt8]
}
