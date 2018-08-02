//
//  Data+BitConversion.swift
//  BigInt
//
//  Created by Cole Potrocky on 8/2/18.
//

import CryptoSwift

extension Data {
  var bits: [Bit] {
    return bytes.flatMap { $0.bits() }
  }
}
