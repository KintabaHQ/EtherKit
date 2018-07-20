//
//  Function.swift
//  Apollo
//
//  Created by Zac Morris on 2018-07-20.
//

import Foundation

public struct FunctionSelector {
    public var name: String
    public var parameterTypes: [String]
    
    public init(name: String, parameterTypes: [String]) {
        self.name = name
        self.parameterTypes = parameterTypes
    }
}

public struct Function {
    public var functionSelector: FunctionSelector
    public var parameters: [ABIValueType]
    
    public init(functionSelector: FunctionSelector, parameters: [ABIValueType]) {
        self.functionSelector = functionSelector
        self.parameters = parameters
    }
}
