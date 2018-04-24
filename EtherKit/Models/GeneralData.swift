//
//  Data.swift
//  BigInt
//
//  Created by Cole Potrocky on 3/23/18.
//

public struct GeneralData: UnformattedDataType {
  static var byteCount: UnformattedDataMode {
    return .unlimited
  }

  let describing: [UInt8]

  public init(describing: [UInt8]) {
    self.describing = describing
  }
}
