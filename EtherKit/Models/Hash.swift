//
//  Hash.swift
//  BigInt
//
//  Created by Cole Potrocky on 3/23/18.
//

public struct Hash: UnformattedDataType {
  public static var byteCount: UnformattedDataMode {
    return .constrained(32)
  }

  public let data: Data

  public init(data: Data) {
    self.data = data
  }
}
