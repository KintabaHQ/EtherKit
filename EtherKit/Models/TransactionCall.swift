//
//  TransactionCall.swift
//  EtherKit
//
//  Created by Cole Potrocky on 3/23/18.
//

import Marshal

public struct TransactionCall: Marshaling {
  let to: Address
  let from: Address? = nil
  let gas: UInt256? = nil
  let gasPrice: UInt256? = nil
  let value: UInt256? = nil
  let data: GeneralData? = nil

  public init(to: Address) {
    self.to = to
  }

  public func marshaled() -> [String: Any] {
    return [
      "to": to,
      "from": from,
      "gas": gas,
      "gasPrice": gasPrice,
      "value": value,
      "data": data,
    ].filter { _, value in value != nil }.mapValues({ String(describing: $0) })
  }
}
