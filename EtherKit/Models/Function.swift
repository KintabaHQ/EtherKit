//
//  Function.swift
//  Apollo
//
//  Created by Zac Morris on 2018-07-20.
//

import BigInt
import Foundation

public struct Function {
  public var name: String
  public var parameters: [ABIType]
  public var contract: Address?

  public init(name: String, parameters: [ABIType], contract: Address? = nil) {
    self.name = name
    self.parameters = parameters
    self.contract = contract
  }

  public init(name: String, parameters: [ABIValueType], contract: Address? = nil) {
    self.name = name
    self.parameters = parameters.compactMap { $0.abiType }
    self.contract = contract
  }

  public func encodeToCall() -> Data {
    var data = Data()
    data.append(abiType.encode())

    var paramTuple = ABIType.tuple(value: parameters)
    data.append(paramTuple.encode())
    return data
  }
}
