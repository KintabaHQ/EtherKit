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
  private var generatedKey: HDKey.Private! {
    didSet {
      generatedKey.unlocked(queue: DispatchQueue.main) {
        self.addressField.text = $0.value?.publicKey.address.description
      }
    }
  }

  private var toAddress: Address!

  @IBOutlet var addressField: UITextField!
  @IBOutlet var signedTransactionField: UITextView!

  override func viewDidLoad() {
    super.viewDidLoad()

    let walletStorage = KeychainStorageStrategy(identifier: "etherkit.example")
    _ = walletStorage.delete()
    HDKey.Private.create(
      with: MnemonicStorageStrategy(walletStorage),
      mnemonic: Mnemonic.create(with: .twelve, language: .english),
      network: .main,
      path: [
        KeyPathNode(at: 44, hardened: true),
        KeyPathNode(at: 60, hardened: true),
        KeyPathNode(at: 0, hardened: true),
        KeyPathNode(at: 0),
      ]
    ) {
      self.generatedKey = $0.value!
      HDKey.Private(walletStorage, network: .main, path: [
        KeyPathNode(at: 44, hardened: true),
        KeyPathNode(at: 60, hardened: true),
        KeyPathNode(at: 0, hardened: true),
        KeyPathNode(at: 1),
      ]).unlocked { value in
        DispatchQueue.main.async {
          _ = value.map { key in self.toAddress = key.publicKey.address }
        }
      }
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
      gasPrice: UInt256(400_000_000_000),
      nonce: UInt256(1),
      data: GeneralData(data: Data())
    )

    fakeTransaction.sign(using: generatedKey, network: .main) { value in
      DispatchQueue.main.async {
        self.signedTransactionField.text = value.value?.description ?? ""
      }
    }
  }

  @IBAction func onPMTap(_: UIButton) {
    "this is a test message to sign".sign(using: generatedKey, network: .main) { value in
      DispatchQueue.main.async {
        self.signedTransactionField.text = value.value?.description ?? ""
      }
    }
  }
}
