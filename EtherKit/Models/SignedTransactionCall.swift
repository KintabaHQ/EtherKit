//
//  SignedTransactionCall.swift
//  EtherKit
//
//  Created by Cole Potrocky on 4/27/18.
//

import BigInt
import Marshal

public struct SignedTransactionCall {
  public let call: TransactionCall
  public let signature: Signature

  public static func create(
    manager: KeyManager,
    sign call: TransactionCall,
    network: Network,
    with address: Address,
    callback: @escaping (SignedTransactionCall) -> Void
  ) throws {
    let fakeTransaction = SignedTransactionCall(
      call: call,
      signature: Signature(v: network.rawValue, r: 0.packedData, s: 0.packedData)
    )

    try Signature.create(
      message: RLPData.encode(from: fakeTransaction).data,
      manager: manager,
      network: network,
      for: address
    ) { sig in
      callback(SignedTransactionCall(call: call, signature: sig))
    }
  }
}

extension SignedTransactionCall: RLPComplexType {
  public func toRLPValue() -> [RLPValueType] {
    return call.toRLPValue() + [signature.v, signature.r, signature.s]
  }
}

extension SignedTransactionCall: Marshaling {
  public func marshaled() -> [String: Any] {
    return call.marshaled().merging(signature.marshaled()) { _, last in last }
  }
}
