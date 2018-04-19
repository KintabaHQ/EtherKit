//
//  Hash.swift
//  BigInt
//
//  Created by Cole Potrocky on 3/23/18.
//

public struct Hash: UnformattedDataType {
  static var byteCount: UnformattedDataMode {
    return .constrained(32)
  }

  let describing: [UInt8]
}
