//
//  GetBlockTransactionCountByNumberRequest.swift
//  BigInt
//
//  Created by Cole Potrocky on 3/22/18.
//

import JSONRPCKit

struct GetBlockTransitionCountByNumberRequest: Request {
  typealias Response = UInt256
  
  let blockNumber: BlockNumber
  
  var method = "eth_getBlockTransactionCountByNumber"
  
  var parameters: Any? {
    return blockNumber
  }
  
  func response(from resultObject: Any) throws -> Response {
    guard let transactionCount = UInt256(describing: resultObject) else {
      throw JSONRPCError.unexpectedTypeObject(resultObject)
    }
    return transactionCount
  }
}

