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
      generatedKey.unlocked(queue: DispatchQueue.global()) { key in
        DispatchQueue.main.async {
          self.addressField.text = key.value?.publicKey.address.description
        }
      }
    }
  }

  private var toAddress: Address!
  private var confirmCallback: ((String?) -> Void)?
  private lazy var confirmViewController: UIViewController = {
    let viewController = UIViewController()
    let confirmButton = UIButton()
    confirmButton.addTarget(self, action: #selector(self.onPasswordConfirm), for: .touchUpInside)
    confirmButton.setTitle("Send Password 0000", for: .normal)
    confirmButton.frame = CGRect(
      x: UIScreen.main.bounds.width / 2 - 200,
      y: UIScreen.main.bounds.height / 2 - 200,
      width: 400,
      height: 50
    )

    viewController.view.addSubview(confirmButton)

    return viewController
  }()

  @IBOutlet var addressField: UITextField!
  @IBOutlet var signedTransactionField: UITextView!

  override func viewDidLoad() {
    super.viewDidLoad()

    
    let walletStorage = PasswordStorageStrategy(identifier: "etherkit.example") { finished in
      DispatchQueue.main.async {
        self.present(self.confirmViewController, animated: true)
        self.confirmCallback = finished
      }
    }
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
    }
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  @IBAction func onTap(_: UIButton) {
    let fakeTransaction = SendTransaction(
      to: try! Address(describing: self.addressField.text ?? ""),
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

  @IBAction func onPasswordConfirm(_: UIButton) {
    dismiss(animated: true)
    confirmCallback?("0000")
    confirmCallback = nil
  }
}
