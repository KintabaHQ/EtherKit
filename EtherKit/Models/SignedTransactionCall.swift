//
//  SignedTransactionCall.swift
//  EtherKit
//
//  Created by Cole Potrocky on 4/27/18.
//

import BigInt
import Marshal

public struct SignedTransactionCall {
  public struct Signature: Marshaling {
    public let v: UInt
    public let r: Data
    public let s: Data

    // MARK: - Marshaling

    public func marshaled() -> [String: Any] {
      return [
        "v": String(describing: GeneralData(data: v.packedData)),
        "r": String(describing: GeneralData(data: r)),
        "s": String(describing: GeneralData(data: s)),
      ]
    }
  }

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

    try manager.sign(RLPData.encode(from: fakeTransaction).data, for: address) { rawSignature, recoveryID in
      let rValueRaw = BigUInt(rawSignature.subdata(in: rawSignature.startIndex ..< (rawSignature.startIndex + 32)))
      let sValueRaw = BigUInt(rawSignature.subdata(in: rawSignature.startIndex + 32 ..< rawSignature.count))

      let signature = Signature(
        v: (recoveryID + 27) + (network.rawValue > 0 ? network.rawValue * 2 + 8 : 0),
        r: UInt256(rValueRaw).toPaddedData(),
        s: UInt256(sValueRaw).toPaddedData()
      )

      callback(SignedTransactionCall(call: call, signature: signature))
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
