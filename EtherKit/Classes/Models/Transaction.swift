//
//  Transaction.swift
//  EtherKit
//
//  Created by Cole Potrocky on 3/23/18.
//

struct Transaction: Encodable {
  let from: Address
  let to: Address?
  let gas: UInt256?
  let gasPrice: UInt256?
  let value: UInt256?
  let data: Data?
  let nonce: UInt256?
}

