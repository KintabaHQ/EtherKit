//
//  Nonce.swift
//  EtherKit
//
//  Created by Cole Potrocky on 3/28/18.
//

public struct Nonce: UnformattedDataType {
  public static var byteCount: UnformattedDataMode {
    return .constrained(8)
  }

  public let data: Data

  public init(data: Data) {
    self.data = data
  }
}
