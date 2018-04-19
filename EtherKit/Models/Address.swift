//
//  Address.swift
//  EtherKit
//
//  Created by Cole Potrocky on 3/21/18.
//

public struct Address: UnformattedDataType {
  static var byteCount: UnformattedDataMode {
    return .constrained(20)
  }
  
  let describing: [UInt8]
}
