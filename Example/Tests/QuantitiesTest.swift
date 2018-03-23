//
//  UInt256Test.swift
//  EtherKit_Example
//
//  Created by Cole Potrocky on 3/23/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import BigInt
import EtherKit
import XCTest
import SwiftCheck

final class QuantitiesTest: XCTestCase {
  func testInt256Conversion() {
    property("An Int256 packs and unpacks to the same String representation") <- forAll { (uint256: ArbitraryUInt256Str) in
      let value = uint256.value
      guard let wrappedUInt256 = UInt256(value) else {
        return false
      }

      return value.caseInsensitiveCompare(String(describing: wrappedUInt256)) == ComparisonResult.orderedSame
    }
  }
}
