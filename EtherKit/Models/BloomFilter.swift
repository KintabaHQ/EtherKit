//
//  BloomFilter.swift
//  EtherKit
//
//  Created by Cole Potrocky on 3/28/18.
//

public struct BloomFilter: UnformattedDataType {
  public static var byteCount: UnformattedDataMode {
    return .constrained(256)
  }

  public let data: Data

  public init(data: Data) {
    self.data = data
  }
}
