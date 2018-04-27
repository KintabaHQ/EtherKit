//
//  Data+Conversions.swift
//  EtherKit
//
//  Created by Cole Potrocky on 4/26/18.
//

extension Data {
  var paddedHexString: String {
    return reduce("0x") { "\($0)\(String(format: "%02x", $1))" }
  }
}
