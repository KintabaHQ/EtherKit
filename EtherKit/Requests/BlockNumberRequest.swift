//
//  BlockNumberRequest.swift
//  EtherKit
//
//  Created by Cole Potrocky on 5/29/18.
//

import Foundation

public class BlockNumberRequest: Request {
  public typealias Parameters = Void
  public typealias Result = UInt256

  public var method: String {
    return "eth_blockNumber"
  }
}
