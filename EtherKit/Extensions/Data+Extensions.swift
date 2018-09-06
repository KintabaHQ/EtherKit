//
//  Data+Extensions.swift
//  EtherKit
//
//  Created by Cole Potrocky on 4/26/18.
//

import CryptoSwift

extension Data {
  public var bits: [Bit] {
    return bytes.flatMap { $0.bits() }
  }

  public var paddedHexString: String {
    return reduce("0x") { "\($0)\(String(format: "%02x", $1))" }
  }

  public static func randomBytes(count: Int) -> Data {
    var bytes = Data(count: count)
    _ = bytes.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, count, $0) }
    return bytes
  }
}
