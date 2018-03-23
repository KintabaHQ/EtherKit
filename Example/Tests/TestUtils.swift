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

func glue(_ parts : [Gen<String>]) -> Gen<String> {
  return sequence(parts).map { $0.reduce("", +) }
}

let decimalDigits = Gen<Character>.fromElements(in: "0"..."9")

let allowedHexCharacters: Gen<Character> = Gen<Character>.one(of: [
  Gen<Character>.fromElements(in: "0"..."9"),
  Gen<Character>.fromElements(in: "A"..."F"),
  Gen<Character>.fromElements(in: "a"..."f")
])

let validAddressGen = glue([Gen.pure("0x"), allowedHexCharacters.proliferate(withSize: 40).map { String($0) }])
let validHashGen = glue([Gen.pure("0x"), allowedHexCharacters.proliferate(withSize: 64).map { String($0) }])
let validCodeGen = glue([
  Gen.pure("0x"),
  allowedHexCharacters.proliferate
    .suchThat { $0.count % 2 == 0 }
    .map { String($0) }
])

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

struct ArbitraryCodeStr: Arbitrary {
  static var arbitrary: Gen<ArbitraryCodeStr> {
    return validCodeGen.map(ArbitraryCodeStr.init)
  }
  let value: String
}

extension BigUInt: Arbitrary {
  public static var arbitrary: Gen<BigUInt> {
    return decimalDigits.proliferate.map { BigUInt(String($0), radix: 10)! }
  }
}

/*
extension UInt256: Arbitrary {
  public static var arbitrary: Gen<UInt256> {
    return Gen<BigUInt>.map { UInt256($0) }
  }
}
 */
