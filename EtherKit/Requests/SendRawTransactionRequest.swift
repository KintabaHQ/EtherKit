//
//  SendRawTransactionRequest.swift
//  EtherKit
//
//  Created by Cole Potrocky on 4/27/18.
//

import Marshal

public class SendRawTransactionRequest: Request {
  public struct Parameters: Marshaling {
    let data: RLPData

    public func marshaled() -> [Any] {
      return [String(describing: data)]
    }
  }

  public typealias Result = Hash

  public var parameters: Parameters
  public var method: String {
    return "eth_sendRawTransaction"
  }

  init(_ parameters: Parameters) {
    self.parameters = parameters
  }
}
