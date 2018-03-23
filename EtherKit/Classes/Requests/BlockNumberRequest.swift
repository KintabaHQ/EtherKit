//
//  BlockNumberRequest.swift
//  EtherKit
//
//  Created by Cole Potrocky on 3/21/18.
//

import BigInt
import JSONRPCKit

struct BlockNumberRequest: Request {
  typealias Response = UInt256
  
  var method = "eth_blockNumber"
  
  func response(from resultObject: Any) throws -> Response {
    guard let blockNumber = UInt256(describing: resultObject) else {
      throw JSONRPCError.unexpectedTypeObject(resultObject)
    }
    return blockNumber
  }
}
