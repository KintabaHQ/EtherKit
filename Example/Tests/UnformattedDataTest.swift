//
//  UnformattedDataTest.swift
//  EtherKit_Tests
//
//  Created by Cole Potrocky on 3/22/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import EtherKit
import SwiftCheck
import XCTest

final class UnformattedDataTest: XCTestCase {
  func testAddressConversion() {
    property("A valid Address is the same after packing into, then unpacking from Address") <- forAll { (address: ArbitraryAddressStr) in
      let value = address.value
      guard let wrappedAddress = Address(describing: value) else {
        return false
      }

      return value.caseInsensitiveCompare(String(describing: wrappedAddress)) == ComparisonResult.orderedSame
    }
  }
  
  func testHashConversion() {
    property("A valid Hash is the same after packing into, then unpacking from Hash") <- forAll { (hash: ArbitraryHashStr) in
      let value = hash.value
      guard let wrappedHash = Hash(describing: value) else {
        return false
      }
      
      return value.caseInsensitiveCompare(String(describing: wrappedHash)) == ComparisonResult.orderedSame
    }
  }
  
  func testCodeConversion() {
    property("A valid Code sequence is the same after packing into, then unpacking from Code") <- forAll { (code: ArbitraryCodeStr) in
      let value = code.value
      print(value)
      guard let wrappedCode = Code(describing: value) else {
        return false
      }
      
      return value.caseInsensitiveCompare(String(describing: wrappedCode)) == ComparisonResult.orderedSame
    }
  }
}
