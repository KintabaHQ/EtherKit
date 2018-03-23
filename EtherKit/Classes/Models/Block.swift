//
//  Block.swift
//  EtherKit
//
//  Created by Cole Potrocky on 3/23/18.
//

struct Block {
  let number: UInt256
  let hash: Hash
  // Hash of the parent block
  let parentHash: Hash
  // let nonce: Nonce
  let sha3Uncles: Hash
  // let logsBloom: 256BytesData
  let transactionsRoot: Hash
  let stateRoot: Hash
  let receiptsRoot: Hash
  let miner: Address
  let difficulty: UInt256
  let totalDifficulty: UInt256
  let extraData: Data
  let size: UInt256
  let gasLimit: UInt256
  let gasUsed: UInt256
  let timestamp: UInt256
  // let transactions:
  // let uncles
  
}
