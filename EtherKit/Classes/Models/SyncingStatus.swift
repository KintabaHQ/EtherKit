//
//  SyncingStatus.swift
//  EtherKit
//
//  Created by Cole Potrocky on 3/21/18.
//

enum SyncingStatus {
  case notSyncing
  case syncing(ActiveSync)
}

struct ActiveSync {
  let startingBlock: UInt256
  let currentBlock: UInt256
  let highestBlock: UInt256
}

extension ActiveSync: Decodable {
  enum CodingKeys: String, CodingKey {
    case startingBlock
    case currentBlock
    case highestBlock
  }
  
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    
    guard let startingBlock = try container.decode(String.self, forKey: .startingBlock).hexToUInt256,
      let currentBlock = try container.decode(String.self, forKey: .currentBlock).hexToUInt256,
      let highestBlock = try container.decode(String.self, forKey: .highestBlock).hexToUInt256 else {
      throw DecodingError.dataCorrupted(DecodingError.Context(
        codingPath: [],
        debugDescription: "`startingBlock`, `currentBlock`, or `highestBlock` was not a valid unsigned integer."
      ))
    }
    
    self.startingBlock = startingBlock
    self.currentBlock = currentBlock
    self.highestBlock = highestBlock
  }
}

