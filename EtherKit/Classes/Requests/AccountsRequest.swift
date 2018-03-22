//
//  AccountsRequest.swift
//  EtherKit
//
//  Created by Cole Potrocky on 3/21/18.
//

import JSONRPCKit

struct AccountsRequest: Request {
  typealias Response = [Address]
  
  var method = "eth_accounts"
  
  func response(from resultObject: Any) throws -> Response {
    guard let maybeAddresses = resultObject as? [String] else {
      throw JSONRPCError.unexpectedTypeObject(resultObject)
    }
    
    return try maybeAddresses.map { addrStr in
      guard let address = Address(addrStr) else {
        throw JSONRPCError.unexpectedTypeObject(addrStr)
      }
      return address
    }
  }
}
