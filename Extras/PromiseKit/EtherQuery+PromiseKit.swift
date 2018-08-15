//
//  EtherQuery+PromiseKit.swift
//  EtherKit
//
//  Created by Cole Potrocky on 6/8/18.
//

import PromiseKit

extension EtherQuery {
  public func request<T: Request>(_ request: T) -> Promise<T.Result> {
    return Promise { seal in
      self.request(request) { seal.resolve($0.value, $0.error) }
    }
  }
  
  public func request<T1: Request, T2: Request>(_ request1: T1, _ request2: T2) -> Promise<(T1.Result, T2.Result)> {
    return Promise { seal in
      self.request(request1, request2) { seal.resolve($0.value, $0.error) }
    }
  }
  
  public func request<T1: Request, T2: Request, T3: Request>(
    _ request1: T1,
    _ request2: T2,
    _ request3: T3
  ) -> Promise<(T1.Result, T2.Result, T3.Result)> {
    return Promise { seal in
      self.request(request1, request2, request3) { seal.resolve($0.value, $0.error) }
    }
  }
  
  public func requestGasEstimate(
    for transaction: SendTransaction,
    from address: Address
  ) -> Promise<UInt256> {
    return Promise { seal in
      self.requestGasEstimate(for: transaction, from: address) { seal.resolve($0.value, $0.error) }
    }
  }
  
  public func send<T: PrivateKeyType>(
    using key: T,
    to: Address,
    value: UInt256,
    data: GeneralData? = nil
  ) -> Promise<Hash> {
    return Promise { seal in
      self.send(using: key, to: to, value: value, data: data) { seal.resolve($0.value, $0.error) }
    }
  }
}
