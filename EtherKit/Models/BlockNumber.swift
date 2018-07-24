//
//  BlockNumber.swift
//  EtherKit
//
//  Created by Cole Potrocky on 3/22/18.
//

public enum BlockNumber {
  case earliest
  case latest
  case pending

  case specific(UInt256)
}

extension BlockNumber: RawRepresentable {
  public typealias RawValue = String

  public var rawValue: RawValue {
    switch self {
    case .earliest: return "earliest"
    case .latest: return "latest"
    case .pending: return "pending"
    case let .specific(blockNumber): return String(describing: blockNumber)
    }
  }

  public init?(rawValue: RawValue) {
    switch rawValue {
    case "earliest": self = .earliest
    case "latest": self = .latest
    case "pending": self = .pending
    default:
      guard let blockNumber = try? UInt256(from: rawValue) else {
        return nil
      }
      self = .specific(blockNumber)
    }
  }
}
