//
//  Address.swift
//  EtherKit
//
//  Created by Cole Potrocky on 3/21/18.
//

import CryptoSwift
import secp256k1

public struct Address: UnformattedDataType {
  public static var byteCount: UnformattedDataMode {
    return .constrained(20)
  }

  public let data: Data

  // EIP55: Mixed-case checksum address encoding:
  // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-55.md
  public var description: String {
    let addressString = data.paddedHexString.dropHexPrefix
    // The hash needs to include the zero-padded String.
    let hashString = addressString.data(using: .utf8)!.sha3(.keccak256).toHexString()

    var address = ""
    for (index, character) in addressString.enumerated() {
      let hashChar = String(hashString[hashString.index(hashString.startIndex, offsetBy: index)])
      guard let hashInt = Int(hashChar, radix: 16), hashInt >= 8 else {
        address += String(character)
        continue
      }

      address += String(character).uppercased()
    }
    return "0x\(address)"
  }

  public init(data: Data) {
    self.data = data
  }
}
