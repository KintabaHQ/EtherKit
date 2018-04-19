//
//  Block.swift
//  EtherKit
//
//  Created by Cole Potrocky on 3/23/18.
//

import Marshal

enum BlockTransactions {
  case hashes([Hash])
  case transactions([Transaction])
}

extension BlockTransactions: ValueType {
  static func value(from object: Any) throws -> BlockTransactions {
    if let valueAsHash = object as? [String] {
      return try .hashes(valueAsHash.map {
        guard let hash = Hash(describing: $0) else {
          throw MarshalError.typeMismatch(expected: Hash.self, actual: type(of: $0))
        }
        return hash
      })
    }

    guard let transactionMaps = object as? [[String: Any]] else {
      throw MarshalError.typeMismatch(expected: [[String: Any]].self, actual: type(of: object))
    }

    return try .transactions(transactionMaps.map {
      try Transaction(object: $0)
    })
  }
}

extension BlockTransactions: RawRepresentable {
  public typealias RawValue = [Any]

  init?(rawValue: [Any]) {
    if let valueAsHash = rawValue as? [String] {
      guard let hashes = try? valueAsHash.map(Hash.value) else {
        return nil
      }
      self = .hashes(hashes)
    }

    guard let transactions = try? rawValue.map(Transaction.value) else {
      return nil
    }
    self = .transactions(transactions)
  }

  var rawValue: [Any] {
    switch self {
    case let .hashes(hashes):
      return hashes.map { String(describing: $0) }
    case let .transactions(transactions):
      return transactions.map { $0.marshaled() }
    }
  }
}

public struct Block: Unmarshaling, Marshaling {
  let number: UInt256
  let hash: Hash
  let parentHash: Hash
  let nonce: Nonce
  let sha3Uncles: Hash
  let logsBloom: BloomFilter
  let transactionsRoot: Hash
  let stateRoot: Hash
  let receiptsRoot: Hash
  let miner: Address
  let difficulty: UInt256
  let totalDifficulty: UInt256
  let extraData: GeneralData
  let size: UInt256
  let gasLimit: UInt256
  let gasUsed: UInt256
  let timestamp: UInt256
  let uncles: [Hash]
  let transactions: BlockTransactions

  public init(object: MarshaledObject) throws {
    number = try object.value(for: "number")
    hash = try object.value(for: "hash")
    parentHash = try object.value(for: "parentHash")
    nonce = try object.value(for: "nonce")
    sha3Uncles = try object.value(for: "sha3Uncles")
    logsBloom = try object.value(for: "logsBloom")
    transactionsRoot = try object.value(for: "transactionsRoot")
    stateRoot = try object.value(for: "stateRoot")
    receiptsRoot = try object.value(for: "receiptsRoot")
    miner = try object.value(for: "miner")
    difficulty = try object.value(for: "difficulty")
    totalDifficulty = try object.value(for: "totalDifficulty")
    extraData = try object.value(for: "extraData")
    size = try object.value(for: "size")
    gasLimit = try object.value(for: "gasLimit")
    gasUsed = try object.value(for: "gasUsed")
    timestamp = try object.value(for: "timestamp")
    uncles = try object.value(for: "uncles")
    transactions = try object.value(for: "transactions")
  }

  public func marshaled() -> [String: Any] {
    return [
      "number": String(describing: number),
      "hash": String(describing: hash),
      "parentHash": String(describing: parentHash),
      "nonce": String(describing: nonce),
      "sha3Uncles": String(describing: sha3Uncles),
      "logsBloom": String(describing: logsBloom),
      "transactionsRoot": String(describing: transactionsRoot),
      "stateRoot": String(describing: stateRoot),
      "receiptsRoot": String(describing: receiptsRoot),
      "miner": String(describing: miner),
      "difficulty": String(describing: difficulty),
      "totalDifficulty": String(describing: totalDifficulty),
      "extraData": String(describing: extraData),
      "size": String(describing: size),
      "gasLimit": String(describing: gasLimit),
      "gasUsed": String(describing: gasUsed),
      "timestamp": String(describing: timestamp),
      "uncles": String(describing: uncles),
      "transactions": transactions.rawValue,
    ]
  }
}
