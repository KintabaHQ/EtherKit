//
//  GetCodeRequest.swift
//  EtherKit
//
//  Created by Cole Potrocky on 7/12/18.
//

import Marshal

public class GetCodeRequest: Request {
  public struct Parameters: Marshaling {
    let address: Address
    let blockNumber: BlockNumber

    // MARK: - Marshaling

    public func marshaled() -> [Any] {
      return [address.description, blockNumber.rawValue]
    }
  }

  public typealias Result = GeneralData

  public var parameters: Parameters

  public var method: String {
    return "eth_getCode"
  }

  init(_ parameters: Parameters) {
    self.parameters = parameters
  }
}
