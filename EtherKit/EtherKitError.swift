//
//  EtherKitError.swift
//  EtherKit
//
//  Created by Cole Potrocky on 4/26/18.
//

enum EtherKitError: Error {
  case invalidDataSize(expected: Int, actual: Int)
}
