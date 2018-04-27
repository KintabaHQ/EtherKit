//
//  RLPTest.swift
//  EtherKit_Tests
//
//  Created by Cole Potrocky on 4/26/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import BigInt
import EtherKit
import XCTest

final class RLPTest: XCTestCase {
  func testBasicStringEncoding() {
    let smallString = RLPData.value(from: "dog").data
    XCTAssertEqual(smallString.count, 4)
    XCTAssertEqual(smallString[0], 131)
    XCTAssertEqual(smallString[1], 100)
    XCTAssertEqual(smallString[2], 111)
    XCTAssertEqual(smallString[3], 103)

    let singleChar = RLPData.value(from: "a").data
    XCTAssertEqual(singleChar.count, 1)
    XCTAssertEqual(singleChar[0], 97)

    let emptyStr = RLPData.value(from: "").data
    XCTAssertEqual(emptyStr.count, 1)
    XCTAssertEqual(emptyStr[0], 128)
  }

  func testBasicListEncoding() {
    let arr: Array<Int> = []
    let emptyList = RLPData.value(from: arr).data
    XCTAssertEqual(emptyList.count, 1)
    XCTAssertEqual(emptyList[0], 192)

    let nonTrivialList = Array(RLPData.value(from: ["cat", "dog"]).data)
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
    let longString = Array(RLPData.value(from: "Lorem ipsum dolor sit amet, consectetur adipisicing elit").data)
    XCTAssertEqual(longString.count, 58)
    XCTAssertEqual(longString[0], 184)
    XCTAssertEqual(longString[1], 56)
  }

  func testBasicIntegers() {
    let basicInt = Array(RLPData.value(from: 1024).data)
    XCTAssertEqual(basicInt.count, 3)
    XCTAssertEqual(basicInt[0], 130)
    XCTAssertEqual(basicInt[1], 4)
    XCTAssertEqual(basicInt[2], 0)

    let basicInt2 = Array(RLPData.value(from: 0).data)
    XCTAssertEqual(basicInt2.count, 1)
    XCTAssertEqual(basicInt2[0], 128)

    let basicInt3 = Array(RLPData.value(from: 15).data)
    XCTAssertEqual(basicInt3.count, 1)
    XCTAssertEqual(basicInt3[0], 15)
  }
}
