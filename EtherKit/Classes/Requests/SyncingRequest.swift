//
//  SyncingRequest.swift
//  EtherKit
//
//  Created by Cole Potrocky on 3/17/18.
//

import JSONRPCKit
import MoreCodable

struct SyncingRequest: Request {
  typealias Response = SyncingStatus
  
  let address: Address
  let blockNumber: BlockNumber
  
  var method = "eth_syncing"
  
  func response(from resultObject: Any) throws -> Response {
    if resultObject is Bool {
      return .notSyncing
    }
    
    guard let jsonResponse = resultObject as? [String: Any] else {
      throw JSONRPCError.unexpectedTypeObject(resultObject)
    }
    
    do {
      let activeSync = try DictionaryDecoder().decode(ActiveSync.self, from: jsonResponse)
      return .syncing(activeSync)
    } catch {
      throw JSONRPCError.unexpectedTypeObject(resultObject)
    }
  }
}
