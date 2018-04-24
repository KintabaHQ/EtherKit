//
//  Address.swift
//  EtherKit
//
//  Created by Cole Potrocky on 3/21/18.
//

import CryptoSwift
import secp256k1

public struct Address: UnformattedDataType {
  static var byteCount: UnformattedDataMode {
    return .constrained(20)
  }

  let describing: [UInt8]

  // EIP55: Mixed-case checksum address encoding:
  // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-55.md
  public var description: String {
    let addressString = String.bytesToPaddedHex(describing).dropHexPrefix
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

  init(describing: [UInt8]) {
    self.describing = describing
  }

  init(from publicKey: secp256k1_pubkey) {
    var publicKey = publicKey
    let bytes: [UInt8] = withUnsafeBytes(of: &publicKey.data) { ptr in
      return (0 ..< 64).map { ptr[$0] }
    }
    self.init(describing: [UInt8](Data(bytes: bytes).sha3(.keccak256)[12 ..< 32]))
  }
}
