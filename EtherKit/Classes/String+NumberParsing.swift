//
//  String+NumberParsing.swift
//  EtherKit
//
//  Created by Cole Potrocky on 3/20/18.
//

extension String {
  var dropHexPrefix: String {
    return hasHexPrefix ? String(dropFirst(2)) : self
  }
  
  var hexToUInt256: UInt256? {
    return UInt256(self)
  }
  
  var hasHexPrefix: Bool {
    return hasPrefix("0x")
  }
}
