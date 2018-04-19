//
//  GetTransactionCountRequest.swift
//  EtherKit
//
//  Created by Cole Potrocky on 4/19/18.
//

import Marshal

public class GetTransactionCountRequest: Request {
  public struct Parameters: Marshaling {
    let address: Address
    let blockNumber: BlockNumber

    // MARK: - Marshaling

    public func marshaled() -> [Any] {
      return [address.description, blockNumber.rawValue]
    }
  }

  public typealias Result = UInt256
  public var parameters: Parameters
  public var method: String {
    return "eth_getTransactionCount"
  }

  init(_ parameters: Parameters) {
    self.parameters = parameters
  }
}
