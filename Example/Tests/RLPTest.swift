//
//  RLPTest.swift
//  EtherKit_Tests
//
//  Created by Cole Potrocky on 4/26/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import BigInt
import EtherKit
import SwiftCheck
import XCTest

final class RLPTest: XCTestCase {
  func testBasicStringEncoding() {
    let smallString = RLPData.encode(from: "dog").data
    XCTAssertEqual(smallString.count, 4)
    XCTAssertEqual(smallString[0], 131)
    XCTAssertEqual(smallString[1], 100)
    XCTAssertEqual(smallString[2], 111)
    XCTAssertEqual(smallString[3], 103)

    let singleChar = RLPData.encode(from: "a").data
    XCTAssertEqual(singleChar.count, 1)
    XCTAssertEqual(singleChar[0], 97)

    let emptyStr = RLPData.encode(from: "").data
    XCTAssertEqual(emptyStr.count, 1)
    XCTAssertEqual(emptyStr[0], 128)
  }

  func testBasicListEncoding() {
    let emptyList = RLPData.encode(from: []).data
    XCTAssertEqual(emptyList.count, 1)
    XCTAssertEqual(emptyList[0], 192)

    let nonTrivialList = Array(RLPData.encode(from: ["cat", "dog"]).data)
    XCTAssertEqual(nonTrivialList.count, 9)
    XCTAssertEqual(nonTrivialList[0], 200)
    XCTAssertEqual(nonTrivialList[1], 131)
    XCTAssertEqual(nonTrivialList[2], 99)
    XCTAssertEqual(nonTrivialList[3], 97)
    XCTAssertEqual(nonTrivialList[4], 116)
    XCTAssertEqual(nonTrivialList[5], 131)
    XCTAssertEqual(nonTrivialList[6], 100)
    XCTAssertEqual(nonTrivialList[7], 111)
    XCTAssertEqual(nonTrivialList[8], 103)
  }

  func testLongString() {
    let longString = Array(RLPData.encode(from: "Lorem ipsum dolor sit amet, consectetur adipisicing elit").data)
    XCTAssertEqual(longString.count, 58)
    XCTAssertEqual(longString[0], 184)
    XCTAssertEqual(longString[1], 56)
  }

  func testBasicIntegers() {
    let basicInt = Array(RLPData.encode(from: 1024).data)
    XCTAssertEqual(basicInt.count, 3)
    XCTAssertEqual(basicInt[0], 130)
    XCTAssertEqual(basicInt[1], 4)
    XCTAssertEqual(basicInt[2], 0)

    let basicInt2 = Array(RLPData.encode(from: 0).data)
    XCTAssertEqual(basicInt2.count, 1)
    XCTAssertEqual(basicInt2[0], 128)

    let basicInt3 = Array(RLPData.encode(from: 15).data)
    XCTAssertEqual(basicInt3.count, 1)
    XCTAssertEqual(basicInt3[0], 15)
  }

  func testBasicList() {
    let intListUnder55Bytes = Array(RLPData.encode(from: [1, 4, 5, 233, 44]).data)
    XCTAssertEqual(intListUnder55Bytes.count, 7)
    XCTAssertEqual(intListUnder55Bytes[0], 198)
    XCTAssertEqual(intListUnder55Bytes[1], 1)
    XCTAssertEqual(intListUnder55Bytes[2], 4)
    XCTAssertEqual(intListUnder55Bytes[3], 5)

    XCTAssertEqual(intListUnder55Bytes[4], 129)
    XCTAssertEqual(intListUnder55Bytes[5], 233)

    XCTAssertEqual(intListUnder55Bytes[6], 44)

    let emptyArray: Array<RLPValueType> = []
    let listOver55Bytes: Array<RLPValueType> = [
      43,
      44_444_444,
      "the quick brown fox jumps over the lazy dog",
      BigUInt("36b673c6d9e5c39c092051d502ee3d3b8dc70d532a7873547c1d92359d5cb026", radix: 16)!,
      "last item",
      emptyArray,
    ]
    let largeList = Array(RLPData.encode(from: listOver55Bytes).data)
    XCTAssertEqual(largeList.count, 96)
    XCTAssertEqual(largeList[0], 248)
    XCTAssertEqual(largeList[1], 94)
  }

  func testArbitrarlyLargeStrs() {
    property("Large strings encode lengths properly into rlp") <- forAll { (longStr: ArbitraryLongStr) in
      let str = longStr.value
      let rlpDataForStr = Array(RLPData.encode(from: str).data)

      let strCountBytes = str.count.packedData.count
      return
        rlpDataForStr[0] == (183 + strCountBytes) &&
        rlpDataForStr[1 ..< 1 + strCountBytes].elementsEqual(Array(str.count.packedData)) &&
        rlpDataForStr[1 + strCountBytes ..< rlpDataForStr.count].elementsEqual(str.data(using: .utf8)!)
    }
  }
}
