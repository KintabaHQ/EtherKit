//
//  Function.swift
//  Apollo
//
//  Created by Zac Morris on 2018-07-20.
//

import BigInt
import Foundation

public struct FunctionSelector {
  public var name: String
  public var parameterTypes: [ABIType]
  public var contract: Address?

  public init(name: String, parameterTypes: [ABIType], contract: Address? = nil) {
    self.name = name
    self.parameterTypes = parameterTypes
    self.contract = contract
  }
}

public struct Function {
  public var functionSelector: FunctionSelector
  public var parameters: [ABIValueType]

  public init(functionSelector: FunctionSelector, parameters: [ABIValueType]) {
    self.functionSelector = functionSelector
    self.parameters = parameters
  }

  public init(name: String, parameters: [ABIValueType]) {
    let parameterTypes: [ABIType] = parameters.compactMap { $0.abiType }
    functionSelector = FunctionSelector(name: name, parameterTypes: parameterTypes)
    self.parameters = parameters
  }

  public func encodeToCall() -> Data {
    var data = Data()
    data.append(functionSelector.abiType.encode())
    for parameter in parameters {
      data.append(parameter.abiType.encode())
    }
    return data
  }
}
