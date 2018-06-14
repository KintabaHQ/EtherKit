//
//  GetTransactionByHashRequest.swift
//  EtherKit
//
//  Created by Cole Potrocky on 6/12/18.
//

import Marshal

public class GetTransactionByHashRequest: Request {
  public struct Parameters: Marshaling {
    let hash: Hash

    // MARK: - Marshaling

    public func marshaled() -> [Any] {
      return [String(describing: hash)]
    }
  }

  public typealias Result = Transaction
  public var parameters: Parameters
  public var method: String {
    return "eth_getTransactionByHash"
  }

  init(_ parameters: Parameters) {
    self.parameters = parameters
  }
}
