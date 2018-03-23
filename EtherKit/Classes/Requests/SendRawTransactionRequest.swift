//
//  SendRawTransactionRequest.swift
//  EtherKit
//
//  Created by Cole Potrocky on 3/23/18.
//

import JSONRPCKit

struct SendRawTransactionRequest: Request {
  typealias Response = Hash
  
  let signedData: Data
  
  var method = "eth_sendRawTransaction"
  
  var parameters: Any? {
    return signedData
  }
  
  func response(from resultObject: Any) throws -> Response {
    guard let rawTransactionHashStr = resultObject as? String,
      let rawTransactionHash = Hash(describing: rawTransactionHashStr) else {
      throw JSONRPCError.unexpectedTypeObject(resultObject)
    }
    return rawTransactionHash
  }
}

