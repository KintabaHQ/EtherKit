//
//  JSONRPCError.swift
//  Pods
//
//  Created by Cole Potrocky on 4/11/18.
//

enum JSONRPCError: Error {
  case unsupportedVersion(String)
  case responseMismatch(requestID: String?, responseID: String?)
  case responseError(code: Int, message: String, data: Any?)
  case parseError(Error)
  case unknown
}
