//
//  Web3.swift
//  Apollo
//
//  Created by Zac Morris on 2018-06-14.
//

import Foundation
import Marshal

public enum Web3Method: String {
  case signTransaction
  case signPersonalMessage
  case signMessage
  case signTypedMessage
  case unknown

  init(string: String) {
    self = Web3Method(rawValue: string) ?? .unknown
  }
}

public struct Web3CommandObject: ValueType {
  public var value: String?
  public var typedData: TypedData?

  public static func value(from object: Any) throws -> Web3CommandObject {
    var commandObject = Web3CommandObject()
    if let valueString = object as? String {
      commandObject.value = valueString
    } else if let typedDataValue = try? TypedData.value(from: object) {
      commandObject.typedData = typedDataValue
    } else {
      throw EtherKitError.web3Failure(reason: .parsingFailure)
    }

    return commandObject
  }
}

public struct Web3Command: ValueType {
  public var name: Web3Method
  public var id: Int
  public var object: [String: Web3CommandObject]

  // This will take in the message.body returned in userContentController for WKScriptMessageHandler
  public static func value(from object: Any) throws -> Web3Command {
    guard let raw = object as? [String: Any],
      let name: Web3Method = try? raw.value(for: "name"),
      let id: Int = try? raw.value(for: "id"),
      let object: [String: Web3CommandObject] = try? raw.value(for: "object") else {
      throw EtherKitError.web3Failure(reason: .parsingFailure)
    }

    return Web3Command(name: name, id: id, object: object)
  }
}
