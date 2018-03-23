//
//  CallRequest.swift
//  EtherKit
//
//  Created by Cole Potrocky on 3/23/18.
//

import JSONRPCKit

struct CallRequest: Request {
  typealias Response = Data
  
  let transaction: TransactionCall
  let blockNumber: BlockNumber
  
  var method = "eth_call"
  
  var parameters: Any? {
    return [transaction, blockNumber]
  }
  
  func response(from resultObject: Any) throws -> Response {
    guard let callReturnStr = resultObject as? String,
      let callReturn = Data(describing: callReturnStr) else {
      throw JSONRPCError.unexpectedTypeObject(resultObject)
    }
    return callReturn
  }
}

