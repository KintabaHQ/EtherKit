//
//  TestUtils.swift
//  EtherKit_Example
//
//  Created by Cole Potrocky on 3/23/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import BigInt
import EtherKit
import SwiftCheck

func glue(_ parts: [Gen<String>]) -> Gen<String> {
  return sequence(parts).map { $0.reduce("", +) }
}

let decimalDigits = Gen<Character>.fromElements(in: "0" ... "9")

let allowedHexCharacters: Gen<Character> = Gen<Character>.one(of: [
  Gen<Character>.fromElements(in: "0" ... "9"),
  Gen<Character>.fromElements(in: "A" ... "F"),
  Gen<Character>.fromElements(in: "a" ... "f"),
])

let validAddressGen = glue([Gen.pure("0x"), allowedHexCharacters.proliferate(withSize: 40).map { String($0) }])
let validHashGen = glue([Gen.pure("0x"), allowedHexCharacters.proliferate(withSize: 64).map { String($0) }])
let validDataGen = glue([
  Gen.pure("0x"),
  allowedHexCharacters.proliferate
    .suchThat { $0.count % 2 == 0 }
    .map { String($0) },
])
let validUInt256Gen = allowedHexCharacters.proliferate(withSize: 64).map { String($0).lowercased() }

struct ArbitraryAddressStr: Arbitrary {
  static var arbitrary: Gen<ArbitraryAddressStr> {
    return validAddressGen.map(ArbitraryAddressStr.init)
  }

  let value: String
}

struct ArbitraryHashStr: Arbitrary {
  static var arbitrary: Gen<ArbitraryHashStr> {
    return validHashGen.map(ArbitraryHashStr.init)
  }

  let value: String
}

struct ArbitraryDataStr: Arbitrary {
  static var arbitrary: Gen<ArbitraryDataStr> {
    return validDataGen.map(ArbitraryDataStr.init)
  }

  let value: String
}

struct ArbitraryUInt256Str: Arbitrary {
  static var arbitrary: Gen<ArbitraryUInt256Str> {
    return validUInt256Gen.map({
      ArbitraryUInt256Str(value: "0x\(String(BigUInt($0, radix: 16)!, radix: 16))")
    })
  }

  let value: String
}

extension UInt256: Arbitrary {
  public static var arbitrary: Gen<UInt256> {
    return ArbitraryUInt256Str.arbitrary.map { try! UInt256(describing: $0.value) }
  }
}

struct ArbitraryLongStr: Arbitrary {
  static var arbitrary: Gen<ArbitraryLongStr> {
    return Gen<Character>
      .choose((Character("!"), Character("~")))
      .proliferate
      .suchThat { $0.count > 200 && $0.count <= 1200 }
      .map { ArbitraryLongStr(value: String($0)) }
  }

  let value: String
}
