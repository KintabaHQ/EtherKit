//
//  GetBlockByHash.swift
//  EtherKit
//
//  Created by Cole Potrocky on 3/23/18.
//

import JSONRPCKit

struct GetBlockByHashRequest: Request {
  typealias Response = Any
  
  let hash: Hash
  
  var method = "eth_getBlockByHash"
  
  var parameters: Any? {
    return hash
  }
  
  func response(from resultObject: Any) throws -> Response {
    fatalError()
  }
}

