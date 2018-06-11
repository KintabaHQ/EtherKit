//
//  Signable+PromiseKit.swift
//  BigInt
//
//  Created by Cole Potrocky on 6/11/18.
//

import PromiseKit

extension Signable {
  public func sign(
    using manager: EtherKeyManager,
    with address: Address,
    network: Network?
  ) -> Promise<Signature> {
    return Promise { seal in
      sign(using: manager, with: address, network: network) { seal.resolve($0.value, $0.error) }
    }
  }
}
