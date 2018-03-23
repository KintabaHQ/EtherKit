//
//  CoinbaseRequest.swift
//  EtherKit
//
//  Created by Cole Potrocky on 3/20/18.
//

import JSONRPCKit

struct CoinbaseRequest: Request {
  typealias Response = Address
  
  var method = "eth_coinbase"
  
  func response(from resultObject: Any) throws -> Response {
    guard let coinbaseStr = resultObject as? String,
      let coinbase = Address(describing: coinbaseStr) else {
      throw JSONRPCError.unexpectedTypeObject(resultObject)
    }
    return coinbase
  }
}
