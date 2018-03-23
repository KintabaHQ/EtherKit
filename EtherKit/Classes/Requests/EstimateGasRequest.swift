//
//  EstimateGasRequest.swift
//  EtherKit
//
//  Created by Cole Potrocky on 3/23/18.
//

import JSONRPCKit

struct EstimateGasRequest: Request {
  typealias Response = UInt256
  
  let transaction: TransactionCall
  let blockNumber: BlockNumber
  
  var method = "eth_estimateGas"
  
  var parameters: Any? {
    return [transaction, blockNumber]
  }
  
  func response(from resultObject: Any) throws -> Response {
    guard let gasEstimate = UInt256(describing: resultObject) else {
      throw JSONRPCError.unexpectedTypeObject(resultObject)
    }
    return gasEstimate
  }
}

