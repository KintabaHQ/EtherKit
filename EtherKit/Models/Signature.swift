//
//  Signature.swift
//  EtherKit
//
//  Created by Zac Morris on 2018-05-10.
//

import BigInt
import Marshal

public struct Signature: Marshaling {
  public var v: UInt
  public var r: Data
  public var s: Data

  // MARK: - Marshaling

  public func marshaled() -> [String: Any] {
    return [
      "v": String(describing: GeneralData(data: v.packedData)),
      "r": String(describing: GeneralData(data: r)),
      "s": String(describing: GeneralData(data: s)),
    ]
  }

  public func toString() -> String {
    let sigData = r + s + v.packedData
    return sigData.paddedHexString
  }

  public static func create(
    message: Data,
    manager: KeyManager,
    network _: Network,
    for address: Address,
    callback: @escaping (Signature) -> Void
  ) throws {
    try manager.sign(message, for: address) { rawSignature, recoveryID in
      let rValueRaw = BigUInt(rawSignature.subdata(in: rawSignature.startIndex ..< (rawSignature.startIndex + 32)))
      let sValueRaw = BigUInt(rawSignature.subdata(in: rawSignature.startIndex + 32 ..< rawSignature.count))

      callback(Signature(
        v: (recoveryID + 27),
        r: UInt256(rValueRaw).toPaddedData(),
        s: UInt256(sValueRaw).toPaddedData()
      ))
    }
  }

  public static func create(
    transaction: SignedTransactionCall,
    manager: KeyManager,
    network: Network,
    for address: Address,
    callback: @escaping (Signature) -> Void
  ) throws {
    let message = RLPData.encode(from: transaction).data

    try manager.sign(message, for: address) { rawSignature, recoveryID in
      let rValueRaw = BigUInt(rawSignature.subdata(in: rawSignature.startIndex ..< (rawSignature.startIndex + 32)))
      let sValueRaw = BigUInt(rawSignature.subdata(in: rawSignature.startIndex + 32 ..< rawSignature.count))

      callback(Signature(
        v: (recoveryID + 27) + (network.rawValue > 0 ? network.rawValue * 2 + 8 : 0),
        r: UInt256(rValueRaw).toPaddedData(),
        s: UInt256(sValueRaw).toPaddedData()
      ))
    }
  }
}
