//
//  Nonce.swift
//  EtherKit
//
//  Created by Cole Potrocky on 3/28/18.
//

public struct Nonce: UnformattedDataType {
  static var byteCount: UnformattedDataMode {
    return .constrained(8)
  }
  
  let describing: [UInt8]
}
