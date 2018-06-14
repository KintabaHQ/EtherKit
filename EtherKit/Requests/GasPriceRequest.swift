//
//  GasPriceRequest.swift
//  EtherKit
//
//  Created by Cole Potrocky on 6/8/18.
//

public class GasPriceRequest: Request {
  public typealias Parameters = Void
  public typealias Result = UInt256

  public var method: String {
    return "eth_gasPrice"
  }
}
