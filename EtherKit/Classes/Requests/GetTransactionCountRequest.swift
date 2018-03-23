//
//  GetTransactionCountRequest.swift
//  BigInt
//
//  Created by Cole Potrocky on 3/22/18.
//

import JSONRPCKit

struct GetTransactionCountRequest: Request {
  typealias Response = UInt256
  
  let address: Address
  let blockNumber: BlockNumber
  
  var method = "eth_getTransactionCount"
  
  var parameters: Any? {
    return [address, blockNumber]
  }
  
  func response(from resultObject: Any) throws -> Response {
    guard let transactionCount = UInt256(describing: resultObject) else {
      throw JSONRPCError.unexpectedTypeObject(resultObject)
    }
    return transactionCount
  }
}


