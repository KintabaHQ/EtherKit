//
//  GetBalanceRequest.swift
//  Pods
//
//  Created by Cole Potrocky on 4/12/18.
//

import Marshal

public class GetBalanceRequest: Request {
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
    return "eth_getBalance"
  }

  init(_ parameters: Parameters) {
    self.parameters = parameters
  }
}
