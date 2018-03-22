//
//  GasPriceRequest.swift
//  EtherKit
//
//  Created by Cole Potrocky on 3/21/18.
//

import BigInt
import JSONRPCKit

struct GasPriceRequest: Request {
  typealias Response = UInt256
  
  var method = "eth_gasPrice"
  
  func response(from resultObject: Any) throws -> Response {
    guard let gasPrice = UInt256(resultObject) else {
      throw JSONRPCError.unexpectedTypeObject(resultObject)
    }
    return gasPrice
  }
}
