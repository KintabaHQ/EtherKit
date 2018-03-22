//
//  UInt256.swift
//  EtherKit
//
//  Created by Cole Potrocky on 3/21/18.
//

import BigInt

struct UInt256 {
  let value: BigUInt
  
  init(_ value: BigUInt) {
    self.value = value
  }
  
  init?(_ value: String) {
    guard let value = BigUInt(value.dropHexPrefix, radix: 16) else {
      return nil
    }
    self.init(value)
  }
  
  init?(_ value: Any) {
    guard let strValue = value as? String else {
      return nil
    }
    
    self.init(strValue)
  }
}

extension UInt256: CustomStringConvertible {
  var description: String {
    return "0x\(value)"
  }
}
