//
//  SendTransaction.swift
//  EtherKit
//
//  Created by Cole Potrocky on 3/23/18.
//

import Marshal

public struct SendTransaction {
  public let value: UInt256
  public let to: Address
  public let data: GeneralData
  public let nonce: UInt256
  public let gasLimit: UInt256
  public let gasPrice: UInt256

  public init(
    to: Address,
    value: UInt256,
    gasLimit: UInt256,
    gasPrice: UInt256,
    nonce: UInt256,
    data: GeneralData
  ) {
    self.nonce = nonce
    self.to = to
    self.gasLimit = gasLimit
    self.gasPrice = gasPrice
    self.value = value
    self.data = data
  }
}

extension SendTransaction: RLPComplexType {
  public func toRLPValue() -> [RLPValueType] {
    return [nonce, gasPrice, gasLimit, to, value, data]
  }
}

extension SendTransaction: Marshaling {
  public func marshaled() -> [String: Any] {
    return [
      "nonce": nonce as CustomStringConvertible,
      "to": to,
      "gasLimit": gasLimit,
      "gasPrice": gasPrice,
      "value": value,
      "data": data,
    ].mapValues { String(describing: $0) }
  }
}

extension SendTransaction: Signable {
  public func signatureData(_ network: Network?) -> Data {
    guard let network = network else {
      return RLPData.encode(from: toRLPValue()).data
    }

    return RLPData.encode(
      from: toRLPValue() + Signature(v: network.rawValue, r: 0.packedData, s: 0.packedData).toRLPValue()
    ).data
  }

  public var usesReplayProtection: Bool {
    return true
  }
}
