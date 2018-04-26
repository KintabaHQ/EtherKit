//
//  BloomFilter.swift
//  EtherKit
//
//  Created by Cole Potrocky on 3/28/18.
//

public struct BloomFilter: UnformattedDataType {
  static var byteCount: UnformattedDataMode {
    return .constrained(256)
  }

  public let data: Data
}
