//
//  SendTransaction.swift
//  EtherKit
//
//  Created by Cole Potrocky on 3/28/18.
//

import Marshal

public struct SendTransaction {
  let from: Address
  let to: Address?
  let gas: UInt256?
  let gasPrice: UInt256?
  let value: UInt256?
  let data: GeneralData = GeneralData(describing: [])
}

extension SendTransaction: Marshaling {
  public func marshaled() -> [String: Any] {
    let toDict: [String: CustomStringConvertible?] = [
      "from": from,
      "to": to,
      "gas": gas,
      "gasPrice": gasPrice,
      "value": value,
      "data": data
    ]
    return toDict.filter { (_, value) in value != nil }.mapValues { String(describing: $0!) }
  }
}
