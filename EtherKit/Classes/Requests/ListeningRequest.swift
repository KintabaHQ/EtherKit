//
//  ListeningRequest.swift
//  EtherKit
//
//  Created by Cole Potrocky on 3/17/18.
//

import JSONRPCKit

struct ListeningRequest: Request {
  typealias Response = Bool
  
  var method = "net_listening"
  
  func response(from resultObject: Any) throws -> Response {
    guard let isListening = resultObject as? Bool else {
      throw JSONRPCError.unexpectedTypeObject(resultObject)
    }
    return isListening
  }
}
