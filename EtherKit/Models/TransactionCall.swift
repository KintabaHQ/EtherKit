//
//  TransactionCall.swift
//  EtherKit
//
//  Created by Cole Potrocky on 3/23/18.
//

import Marshal

public struct TransactionCall {
  public let nonce: UInt256
  public let to: Address
  public let gasLimit: UInt256
  public let gasPrice: UInt256
  public let value: UInt256
  // Either contract initialization code or extra transaction data, depending on whether
  // value is 0 or not.
  public let data: GeneralData

  public init(
    nonce: UInt256,
    to: Address,
    gasLimit: UInt256,
    gasPrice: UInt256,
    value: UInt256,
    data: GeneralData = GeneralData(data: Data())
  ) {
    self.nonce = nonce
    self.to = to
    self.gasLimit = gasLimit
    self.gasPrice = gasPrice
    self.value = value
    self.data = data
  }
}

extension TransactionCall: RLPComplexType {
  public func toRLPValue() -> [RLPValueType] {
    return [nonce, gasPrice, gasLimit, to, value, data]
  }
}

extension TransactionCall: Marshaling {
  public func marshaled() -> [String: Any] {
    return [
      "nonce": String(describing: nonce),
      "to": String(describing: to),
      "gasLimit": String(describing: gasLimit),
      "gasPrice": String(describing: gasPrice),
      "value": String(describing: value),
      "data": String(describing: data),
    ]
  }
}
