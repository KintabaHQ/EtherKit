//
//  GetCodeRequest.swift
//  EtherKit
//
//  Created by Cole Potrocky on 3/23/18.
//

import JSONRPCKit

struct GetCodeRequest: Request {
  typealias Response = Data
  
  let address: Address
  let blockNumber: BlockNumber
  
  var method = "eth_getCode"
  
  var parameters: Any? {
    return [address, blockNumber]
  }
  
  func response(from resultObject: Any) throws -> Response {
    guard let dataStr = resultObject as? String,
      let data = Data(describing: dataStr) else {
      throw JSONRPCError.unexpectedTypeObject(resultObject)
    }
    return data
  }
}

