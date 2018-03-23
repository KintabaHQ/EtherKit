//
//  GetBlockTransactionCountByHashRequest.swift
//  EtherKit
//
//  Created by Cole Potrocky on 3/22/18.
//

import JSONRPCKit

struct GetBlockTransactionCountByHashRequest: Request {
  typealias Response = UInt256
  
  let hash: UInt256
  
  var method = "eth_getBlockTransactionCountByHash"
  
  var parameters: Any? {
    return hash
  }
  
  func response(from resultObject: Any) throws -> Response {
    guard let transactionCount = UInt256(resultObject) else {
      throw JSONRPCError.unexpectedTypeObject(resultObject)
    }
    return transactionCount
  }
}

