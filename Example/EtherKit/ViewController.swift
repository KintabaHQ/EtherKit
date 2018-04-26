//
//  ViewController.swift
//  EtherKit
//
//  Created by Cole Potrocky on 03/20/2018.
//  Copyright (c) 2018 Cole Potrocky. All rights reserved.
//

import EtherKit
import UIKit

class ViewController: UIViewController {
  var kit: EtherKit = EtherKit(URL(string: "http://localhost:8545")!, connectionMode: .websocket)
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    let manager = KeyManager(applicationTag: "com.cole.yay")
    do {
      let address = try manager.create(config: KeyManager.PairConfig(
        keyLabel: "cool",
        operationPrompt: "Yayayaya"
      ))
      print(address)
      try manager.sign("foo bar".data(using: .utf8)!, for: address) {
        print(String(describing: GeneralData(describing: [UInt8]($0))), "cole")
        try? manager.verify($0, address: address, digest: "foo bar".data(using: .utf8)!.sha3(.keccak256)) {
          if $0 {
            print("valid signature")
          } else {
            print("invalid signature")
          }
        }
      }
    } catch {
      print(error)
    }

    try? kit.request(
      kit.networkVersion(),
      kit.balanceOf(Address(describing: "0xe375873f25f589726bbf200187aa5fb07f5f7451")!),
      kit.balanceOf(Address(describing: "0xfb385836bcad905d17ef32873ef17f22bbc7b2da")!)
    ) { result1, result2, result3 in
      print("parsed results", result1, result2, result3)
    }
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
}
