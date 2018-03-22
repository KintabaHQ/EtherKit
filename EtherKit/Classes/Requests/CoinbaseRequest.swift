//
//  CoinbaseRequest.swift
//  EtherKit
//
//  Created by Cole Potrocky on 3/20/18.
//

import JSONRPCKit

struct CoinbaseRequest: Request {
  typealias Response = Int
  
  var method = "eth_coinbase"
  
  func response(from resultObject: Any) throws -> Response {
    fatalError()
  }
}
