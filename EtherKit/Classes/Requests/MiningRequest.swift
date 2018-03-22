//
//  MiningRequest.swift
//  EtherKit
//
//  Created by Cole Potrocky on 3/21/18.
//

import JSONRPCKit

struct MiningRequest: Request {
  typealias Response = Bool
  
  var method = "eth_mining"
  
  func response(from resultObject: Any) throws -> Response {
    guard let isNodeMining = resultObject as? Bool else {
      throw JSONRPCError.unexpectedTypeObject(resultObject)
    }
    return isNodeMining
  }
}
