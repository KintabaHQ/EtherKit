//
//  ViewController.swift
//  EtherKit
//
//  Created by Cole Potrocky on 03/20/2018.
//  Copyright (c) 2018 Cole Potrocky. All rights reserved.
//

import BigInt
import EtherKit
import PromiseKit
import UIKit

class ViewController: UIViewController {
  private lazy var etherKeyManager: EtherKeyManager = {
    EtherKeyManager(applicationTag: "org.cocoapods.demo.EtherKit-Example")
  }()

  private var generatedAddress: Address! {
    didSet {
      addressField.text = String(describing: generatedAddress!)
    }
  }

  private var toAddress: Address!

  @IBOutlet var addressField: UITextField!
  @IBOutlet var signedTransactionField: UITextView!

  override func viewDidLoad() {
    super.viewDidLoad()

    _ = firstly {
      when(fulfilled: etherKeyManager.createKeyPair(.promise), etherKeyManager.createKeyPair(.promise))
    }.done { address1, address2 in
      self.generatedAddress = address1
      self.toAddress = address2
    }
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  @IBAction func onTap(_: UIButton) {
    
    let fakeTransaction = SendTransaction(
      to: toAddress,
      value: UInt256(45),
      gasLimit: UInt256(90000),
      gasPrice: UInt256(400000000000),
      nonce: UInt256(1)
    )
    
    fakeTransaction.sign(using: etherKeyManager, with: generatedAddress, network: .main) { signature in
      var transactionValues = fakeTransaction.marshaled()
      transactionValues.merge(signature.value!.marshaled(), uniquingKeysWith: { a, _ in a })
      self.signedTransactionField.text = String(describing: transactionValues)
    }
  }

  @IBAction func onPMTap(_: UIButton) {
    "this is a test message to sign".sign(using: etherKeyManager, with: generatedAddress, network: .main) { signature in
      self.signedTransactionField.text = String(describing: signature.value!.marshaled())
    }
  }
}
