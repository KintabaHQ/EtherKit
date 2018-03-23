//
//  SendTransactionRequest.swift
//  EtherKit
//
//  Created by Cole Potrocky on 3/23/18.
//

import JSONRPCKit

struct SendTransactionRequest: Request {
  typealias Response = Hash
  
  let transaction: Transaction
  
  var method = "eth_sendTransaction"
  
  var parameters: Any? {
    return transaction
  }
  
  func response(from resultObject: Any) throws -> Response {
    guard let transactionHashStr = resultObject as? String,
      let transactionHash = Hash(describing: transactionHashStr) else {
      throw JSONRPCError.unexpectedTypeObject(resultObject)
    }
    return transactionHash
  }
}

