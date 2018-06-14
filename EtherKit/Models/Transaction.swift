//
//  Transaction.swift
//  EtherKit
//
//  Created by Cole Potrocky on 3/23/18.
//

import Marshal

public struct Transaction {
  public let hash: Hash
  public let nonce: UInt256
  public let blockHash: Hash
  public let blockNumber: UInt256?
  public let transactionIndex: UInt256?
  public let from: Address
  public let to: Address
  public let value: UInt256
  public let gasPrice: UInt256
  public let gas: UInt256
  public let input: GeneralData
}

extension Transaction: Unmarshaling {
  public init(object: MarshaledObject) throws {
    hash = try object.value(for: "hash")
    nonce = try object.value(for: "nonce")
    blockHash = try object.value(for: "blockHash")
    blockNumber = try object.value(for: "blockNumber")
    transactionIndex = try object.value(for: "transactionIndex")
    from = try object.value(for: "from")
    to = try object.value(for: "to")
    value = try object.value(for: "value")
    gasPrice = try object.value(for: "gasPrice")
    gas = try object.value(for: "gas")
    input = try object.value(for: "input")
  }
}

extension Transaction: Marshaling {
  public func marshaled() -> [String: Any] {
    let toDict: [String: CustomStringConvertible?] = [
      "hash": hash,
      "nonce": nonce,
      "blockHash": blockHash,
      "blockNumber": blockNumber,
      "transactionIndex": transactionIndex,
      "from": from,
      "to": to,
      "value": value,
      "gasPrice": gasPrice,
      "gas": gas,
      "input": input,
    ]

    return toDict.filter { _, value in value != nil }.mapValues { String(describing: $0) }
  }
}
