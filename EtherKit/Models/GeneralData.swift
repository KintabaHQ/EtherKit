//
//  Data.swift
//  BigInt
//
//  Created by Cole Potrocky on 3/23/18.
//

public struct GeneralData: UnformattedDataType {
  public static var byteCount: UnformattedDataMode {
    return .unlimited
  }

  public let data: Data

  public init(data: Data) {
    self.data = data
  }
}
