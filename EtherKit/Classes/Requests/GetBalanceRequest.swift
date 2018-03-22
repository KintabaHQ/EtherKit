//
//  GetBalanceRequest.swift
//  EtherKit
//
//  Created by Cole Potrocky on 3/21/18.
//

import BigInt
import JSONRPCKit

struct GetBalanceRequest: Request {
  typealias Response = BigUInt
  
  var method = "eth_getBalance"
  
  func response(from resultObject: Any) throws -> Response {
    fatalError()
  }
}
