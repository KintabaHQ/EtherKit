//
//  UInt256.swift
//  EtherKit
//
//  Created by Cole Potrocky on 3/21/18.
//

import BigInt

public struct UInt256: Encodable {
  public let describing: BigUInt
  
  public init(_ value: BigUInt) {
    self.describing = value
  }
  
  public init?(describing: String) {
    guard let value = BigUInt(describing.dropHexPrefix, radix: 16) else {
      return nil
    }
    self.init(value)
  }
  
  public init?(describing: Any) {
    guard let strValue = describing as? String else {
      return nil
    }
    
    self.init(describing: strValue)
  }
}

extension UInt256: CustomStringConvertible {
  public var description: String {
    return "0x\(String(describing, radix: 16))"
  }
}

