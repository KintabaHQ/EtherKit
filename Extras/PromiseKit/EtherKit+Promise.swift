
import PromiseKit

extension EtherKit {
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

  public func sign(
    with sender: Address,
    transaction: TransactionCall,
    network: Network
  ) -> Promise<SignedTransactionCall> {
    return Promise { seal in
      self.sign(with: sender, transaction: transaction, network: network) { seal.resolve($0.value, $0.error) }
    }
  }

  public func sign(
    message: Data,
    network: Network,
    for address: Address
  ) -> Promise<Signature> {
    return Promise { seal in
      self.sign(message: message, network: network, for: address) { seal.resolve($0.value, $0.error) }
    }
  }

  public func sign(
    message: String,
    network: Network,
    for address: Address
  ) -> Promise<Signature> {
    return Promise { seal in
      self.sign(message: message, network: network, for: address) { seal.resolve($0.value, $0.error) }
    }
  }
    
    public func sign(
        datas: [TypedData],
        network: Network,
        for address: Address
        ) -> Promise<Signature> {
        return Promise { seal in
            self.sign(datas: datas, network: network, for: address) { seal.resolve($0.value, $0.error) }
        }
    }

  public func send(with sender: Address, to: Address, value: UInt256) -> Promise<Hash> {
    return Promise { seal in
      self.send(with: sender, to: to, value: value) { seal.resolve($0.value, $0.error) }
    }
  }

  public func send(
    with sender: Address,
    to: Address,
    value: UInt256,
    data: GeneralData,
    gas: UInt256 = UInt256(21000)
  ) -> Promise<Hash> {
    return Promise { seal in
      self.send(with: sender, to: to, value: value, data: data, gas: gas) { seal.resolve($0.value, $0.error) }
    }
  }

  public func createKeyPair(
    _: PMKNamespacer,
    _ config: KeyManager.PairConfig = KeyManager.PairConfig(operationPrompt: nil)
  ) -> Promise<Address> {
    return Promise { seal in
      self.createKeyPair(config) { seal.resolve($0.value, $0.error) }
    }
  }
}
