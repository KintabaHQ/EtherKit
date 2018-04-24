//
//  KeyManagerError.swift
//  EtherKit
//
//  Created by Cole Potrocky on 4/23/18.
//

enum KeyManagerError: Error {
  case keychainStorageFailure
  case secureEnclaveCreationFailure
  case encryptionFailure
  case decryptionFailure
  case keyNotFound
  case signFailure
}
