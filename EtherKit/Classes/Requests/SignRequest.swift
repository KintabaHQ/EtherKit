//
//  SignRequest.swift
//  EtherKit
//
//  Created by Cole Potrocky on 3/23/18.
//

import JSONRPCKit

struct SignRequest: Request {
  typealias Response = Data
  
  let address: Address
  let message: Data
  
  var method = "eth_sign"
  
  var parameters: Any? {
    return [address, message]
  }
  
  func response(from resultObject: Any) throws -> Response {
    guard let dataStr = resultObject as? String,
      let data = Data(describing: dataStr) else {
      throw JSONRPCError.unexpectedTypeObject(resultObject)
    }
    return data
  }
}

