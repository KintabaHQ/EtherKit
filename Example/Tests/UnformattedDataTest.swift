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
      guard let wrappedAddress = try? Address(describing: value) else {
        return false
      }

      return value.caseInsensitiveCompare(String(describing: wrappedAddress)) == ComparisonResult.orderedSame
    }
  }

  func testHashConversion() {
    property("A valid Hash is the same after packing into, then unpacking from Hash") <- forAll { (hash: ArbitraryHashStr) in
      let value = hash.value
      guard let wrappedHash = try? Hash(describing: value) else {
        return false
      }

      return value.caseInsensitiveCompare(String(describing: wrappedHash)) == ComparisonResult.orderedSame
    }
  }

  func testCodeConversion() {
    property("A valid Data sequence is the same after packing into, then unpacking from Code") <- forAll { (data: ArbitraryDataStr) in
      let value = data.value
      guard let wrappedData = try? GeneralData(describing: value) else {
        return false
      }

      return value.caseInsensitiveCompare(String(describing: wrappedData)) == ComparisonResult.orderedSame
    }
  }
}
