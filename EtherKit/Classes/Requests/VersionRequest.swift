//
//  VersionRequest.swift
//  EtherKit
//
//  Created by Cole Potrocky on 3/17/18.
//

import JSONRPCKit

struct VersionRequest: Request {
  typealias Response = Network
  
  var method = "net_version"

  func response(from resultObject: Any) throws -> Network {
    guard let rawResult = resultObject as? String,
      let network = Network(rawValue: rawResult) else {
        throw JSONRPCError.unexpectedTypeObject(resultObject)
    }
    return network
  }
}
