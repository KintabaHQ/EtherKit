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
    case keyDerivationFailed
  }

  public enum JSONRPCFailureReason {
    case unsupportedVersion(String)
    case responseMismatch(requestID: String?, responseID: String?)
    case responseError(code: Int, message: String, data: Any?)
    case parseError(error: Error)
    case invalidRequestJSON
    case unknown
  }

  public enum DataConversionFailureReason {
    case wrongSize(expected: Int, actual: Int)
    case scalarConversionFailed(forValue: Any, toType: Any)
  }

  public enum Web3FailureReason {
    case parsingFailure
  }

  case keyManagerFailed(reason: KeyManagerFailureReason)
  case jsonRPCFailed(reason: JSONRPCFailureReason)
  case dataConversionFailed(reason: DataConversionFailureReason)
  case web3Failure(reason: Web3FailureReason)
  case unknown(error: Error)
}
