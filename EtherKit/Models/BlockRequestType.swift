//
//  BlockRequestType.swift
//  EtherKit
//
//  Created by Cole Potrocky on 3/28/18.
//

public enum BlockRequestType {
  case onlyHashes
  case fullTransactions
}

extension BlockRequestType: RawRepresentable {
  public typealias RawValue = Bool

  public init?(rawValue: Bool) {
    switch rawValue {
    case false: self = .onlyHashes
    case true: self = .fullTransactions
    }
  }

  public var rawValue: Bool {
    switch self {
    case .onlyHashes: return false
    case .fullTransactions: return true
    }
  }
}
