//
//  ErrorResult.swift
//  Pods
//
//  Created by Cole Potrocky on 4/11/18.
//

import Marshal

struct ErrorResult {
  let code: Int
  let message: String
  let data: Any?
}

extension ErrorResult: Unmarshaling {
  init(object: MarshaledObject) throws {
    code = try object.value(for: "code")
    message = try object.value(for: "message")
    data = object.optionalAny(for: "data")
  }
}
