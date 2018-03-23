//
//  HashRateRequest.swift
//  EtherKit
//
//  Created by Cole Potrocky on 3/21/18.
//

import JSONRPCKit

struct HashRateRequest: Request {
  typealias Response = UInt256
  
  var method = "eth_hashrate"
  
  func response(from resultObject: Any) throws -> Response {
    guard let hashRate = UInt256(describing: resultObject) else {
      throw JSONRPCError.unexpectedTypeObject(resultObject)
    }
    return hashRate
  }
}
