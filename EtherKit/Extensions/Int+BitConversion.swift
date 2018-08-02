//
//  Int+BitConversion.swift
//  EtherKit
//
//  Created by Cole Potrocky on 8/2/18.
//

import CryptoSwift

extension Int {
  init(bits: [Bit]) {
    var bitPattern: UInt = 0
    for idx in bits.indices {
      if bits[idx] == Bit.one {
        let bit = UInt(UInt64(1) << UInt64(idx))
        bitPattern = bitPattern | bit
      }
    }
    self.init(bitPattern: bitPattern)
  }
}
