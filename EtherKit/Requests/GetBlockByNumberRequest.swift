//
//  GetBlockByNumberRequest.swift
//  EtherKit
//
//  Created by Cole Potrocky on 6/12/18.
//

import Marshal

public class GetBlockByNumberRequest: Request {
  public struct Parameters: Marshaling {
    let blockNumber: BlockNumber
    let fullTransactionObjects: Bool
    
    // MARK: - Marshaling
    
    public func marshaled() -> [Any] {
      return [blockNumber.rawValue, fullTransactionObjects]
    }
  }
  
  public typealias Result = Block
  
  public var parameters: Parameters
  
  public var method: String {
    return "eth_getBlockByNumber"
  }
  
  init(_ parameters: Parameters) {
    self.parameters = parameters
  }
}

