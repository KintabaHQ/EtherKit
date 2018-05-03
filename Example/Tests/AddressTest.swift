//
//  AddressTest.swift
//  EtherKit_Tests
//
//  Created by Cole Potrocky on 4/20/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import EtherKit
import XCTest

final class AddressTest: XCTestCase {
  func testAddressChecksumming() {
    let addresses = [
      "0x52908400098527886E0F7030069857D2E4169EE7",
      "0x8617E340B3D01FA5F11F306F4090FD50E238070D",
      "0xde709f2102306220921060314715629080e2fb77",
      "0x27b1fdb04752bbc536007a920d24acb045561c26",
      "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed",
      "0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359",
      "0xdbF03B407c01E7cD3CBea99509d93f8DDDC8C6FB",
      "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb",
    ]

    for address in addresses {
      XCTAssertEqual(
        address,
        String(describing: try! Address(describing: address)),
        "A parsed address should be stringified back into its EIP55 checksummed representation."
      )
    }
  }
}
