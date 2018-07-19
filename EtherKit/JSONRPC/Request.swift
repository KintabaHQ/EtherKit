//
//  Request.swift
//  Pods
//
//  Created by Cole Potrocky on 4/11/18.
//

import Marshal

private var requestIDAssociatedObjectHandle = 97_923_045

struct Response: Unmarshaling {
  let id: String
  let version: String
  let result: Any?
  let error: ErrorResult?

  init(object: MarshaledObject) throws {
    id = try object.value(for: "id")
    version = try object.value(for: "jsonrpc")
    result = try object.optionalAny(for: "result")
    error = try object.value(for: "error")
  }
}

public protocol Request: AnyObject, Marshaling {
  associatedtype Parameters
  associatedtype Result

  var version: String { get }
  var method: String { get }
  var parameters: Parameters { get }
  var id: String? { get }

  func result(from result: Any?) throws -> Result
  func response(from response: Any) throws -> Result
}

extension Request {
  public var version: String {
    return "2.0"
  }

  public func response(from response: Any) throws -> Result {
    guard let wrappedResponse = try? Response.value(from: response) else {
      throw EtherKitError.jsonRPCFailed(
        reason: .parseError(error: MarshalError.typeMismatch(expected: Response.self, actual: type(of: response)))
      )
    }

    guard wrappedResponse.id == id!, wrappedResponse.version == version else {
      throw EtherKitError.jsonRPCFailed(reason: .responseMismatch(requestID: id, responseID: wrappedResponse.id))
    }

    if let error = wrappedResponse.error {
      throw EtherKitError.jsonRPCFailed(
        reason: .responseError(code: error.code, message: error.message, data: error.data)
      )
    }

    return try result(from: wrappedResponse.result)
  }
}

extension Request where Parameters == Dictionary<String, Any> {

  // MARK: - Marshaling

  func marshaled() -> [String: Any] {
    return [
      "jsonrpc": version,
      "params": parameters,
      "method": method,
      "id": id!,
    ]
  }
}

extension Request where Parameters: Marshaling {

  // MARK: - Marshaling

  public func marshaled() -> [String: Any] {
    return [
      "jsonrpc": version,
      "params": parameters.marshaled(),
      "method": method,
      "id": id!,
    ]
  }
}

extension Request where Parameters == Void {
  public var parameters: Void {
    return ()
  }

  public func marshaled() -> [String: Any] {
    return [
      "jsonrpc": version,
      "method": method,
      "id": id!,
    ]
  }
}

extension Request where Result: ValueType {
  public var id: String? {
    if let id = objc_getAssociatedObject(self, &requestIDAssociatedObjectHandle) as? UUID {
      return id.uuidString
    } else {
      let requestID = UUID()
      objc_setAssociatedObject(
        self,
        &requestIDAssociatedObjectHandle,
        requestID,
        objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC
      )
      return requestID.uuidString
    }
  }

  public func result(from result: Any?) throws -> Result.Value {
    guard let nonNullableResult = result else {
      throw MarshalError.typeMismatch(expected: Any.self, actual: type(of: result))
    }
    return try Result.value(from: nonNullableResult)
  }
}

// A Notification Type, which doesn't request a response from the server.
extension Request where Result == Void {
  var id: String? {
    return nil
  }

  func response(from _: Any) throws -> Result {
    return ()
  }
}
