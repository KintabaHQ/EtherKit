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

    try? kit.request(
      kit.balanceOf(Address(describing: "0xe375873f25f589726bbf200187aa5fb07f5f7451")!),
      kit.balanceOf(Address(describing: "0xfb385836bcad905d17ef32873ef17f22bbc7b2da")!),
      kit.balanceOf(Address(describing: "0x4044bb3d4a4c9afd530217067bb5921eeb182e4b")!)
    ) { result1, result2, result3 in
      print("parsed results", result1, result2, result3)
    }
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
}
