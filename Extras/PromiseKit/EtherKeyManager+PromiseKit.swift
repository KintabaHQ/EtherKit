//
//  EtherKeyManager+PromiseKit.swift
//  EtherKit
//
//  Created by Cole Potrocky on 6/8/18.
//

import PromiseKit

extension EtherKeyManager {
  public func createKeyPair(_: PMKNamespacer) -> Promise<Address> {
    return Promise { seal in
      self.createKeyPair() { seal.resolve($0.value, $0.error) }
    }
  }
}
