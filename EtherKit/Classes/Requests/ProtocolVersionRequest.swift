//
//  ProtocolVersionRequest.swift
//  EtherKit
//
//  Created by Cole Potrocky on 3/17/18.
//

import JSONRPCKit

struct ProtocolVersionRequest: Request {
  typealias Response = String
  
  var method = "eth_protocolVersion"
  
  func response(from resultObject: Any) throws -> String {
    guard let ethVersion = resultObject as? String else {
      throw JSONRPCError.unexpectedTypeObject(resultObject)
    }
    return ethVersion
  }
}
