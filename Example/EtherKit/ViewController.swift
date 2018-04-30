//
//  ViewController.swift
//  EtherKit
//
//  Created by Cole Potrocky on 03/20/2018.
//  Copyright (c) 2018 Cole Potrocky. All rights reserved.
//

import BigInt
import EtherKit
import UIKit

class ViewController: UIViewController {
  // Keep one reference to EtherKit per app.
  private lazy var etherKit: EtherKit = {
    EtherKit(
      URL(string: "http://localhost:8545")!,
      connectionMode: .http,
      applicationTag: "io.vault.etherkit.example"
    )
  }()

  private lazy var generatedAddress: Address = {
    try! etherKit.createKeyPair()
  }()

  private lazy var toAddress: Address = {
    try! etherKit.createKeyPair()
  }()

  @IBOutlet var addressField: UITextField!
  @IBOutlet var signedTransactionField: UITextView!

  override func viewDidLoad() {
    super.viewDidLoad()

    addressField.text = String(describing: generatedAddress)
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  @IBAction func onTap(_: UIButton) {
    etherKit.sign(
      with: generatedAddress,
      transaction: TransactionCall(
        nonce: UInt256(0),
        to: toAddress,
        gasLimit: UInt256(describing: "0xff")!,
        gasPrice: UInt256(describing: "0xfacefaceface")!,
        value: UInt256(describing: "0xffffface")!
      ),
      network: .main
    ) {
      self.signedTransactionField.text = String(describing: $0.value!.marshaled())
    }
  }
}
