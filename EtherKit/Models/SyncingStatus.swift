//
//  SyncingStatus.swift
//  EtherKit
//
//  Created by Cole Potrocky on 3/21/18.
//

import Marshal

public enum SyncingStatus {
  case notSyncing
  case syncing(ActiveSync)
}

public struct ActiveSync {
  let startingBlock: UInt256
  let currentBlock: UInt256
  let highestBlock: UInt256
}

extension ActiveSync: Unmarshaling {
  public init(object: MarshaledObject) throws {
    startingBlock = try object.value(for: "startingBlock")
    currentBlock = try object.value(for: "currentBlock")
    highestBlock = try object.value(for: "highestBlock")
  }
}
