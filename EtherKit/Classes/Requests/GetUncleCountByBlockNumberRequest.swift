//
//  GetUncleCountByBlockNumberRequest.swift
//  EtherKit
//
//  Created by Cole Potrocky on 3/22/18.
//

import JSONRPCKit

struct GetUncleCountByBlockNumberRequest: Request {
  typealias Response = UInt256
  
  let blockNumber: BlockNumber
  
  var method = "eth_getUncleCountByBlockNumber"
  
  var parameters: Any? {
    return blockNumber
  }
  
  func response(from resultObject: Any) throws -> Response {
    guard let uncleCount = UInt256(resultObject) else {
      throw JSONRPCError.unexpectedTypeObject(resultObject)
    }
    return uncleCount
  }
}

