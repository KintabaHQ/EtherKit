//
//  EtherKitError.swift
//  EtherKit
//
//  Created by Cole Potrocky on 4/26/18.
//

public enum EtherKitError: Error {
  public enum KeyManagerFailureReason {
    case keychainStorageFailure
    case secureEnclaveCreationFailed
    case encryptionFailed
    case decryptionFailed
    case keyNotFound
    case signatureFailed
  }

  public enum JSONRPCFailureReason {
    case unsupportedVersion(String)
    case responseMismatch(requestID: String?, responseID: String?)
    case responseError(code: Int, message: String, data: Any?)
    case parseError(error: Error)
    case invalidRequestJSON
    case unknown
  }

  case keyManagerFailed(reason: KeyManagerFailureReason)
  case jsonRPCFailed(reason: JSONRPCFailureReason)
  case invalidDataSize(expected: Int, actual: Int)
  case unknown(error: Error)
}
