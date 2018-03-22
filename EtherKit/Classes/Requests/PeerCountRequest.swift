//
//  PeerCountRequest.swift
//  EtherKit
//
//  Created by Cole Potrocky on 3/17/18.
//

import JSONRPCKit

struct PeerCountRequest: Request {
  typealias Response = UInt256
  
  var method = "net_peerCount"
  
  func response(from resultObject: Any) throws -> Response {
    guard let peerCount = UInt256(resultObject) else {
      throw JSONRPCError.unexpectedTypeObject(resultObject)
    }
    return peerCount
  }
}
