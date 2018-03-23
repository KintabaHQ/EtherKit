//
//  GetUncleCountByBlockHashRequest.swift
//  EtherKit
//
//  Created by Cole Potrocky on 3/22/18.
//

import JSONRPCKit

struct GetUncleCountByBlockHashRequest: Request {
  typealias Response = UInt256
  
  let hash: UInt256
  
  var method = "eth_getUncleCountByBlockHash"
  
  var parameters: Any? {
    return hash
  }
  
  func response(from resultObject: Any) throws -> Response {
    guard let uncleCount = UInt256(describing: resultObject) else {
      throw JSONRPCError.unexpectedTypeObject(resultObject)
    }
    return uncleCount
  }
}

