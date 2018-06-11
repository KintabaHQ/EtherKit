//
//  Signature.swift
//  EtherKit
//
//  Created by Zac Morris on 2018-05-10.
//

import BigInt
import Result
import Marshal

public protocol Signable {
  func signatureData(_ network: Network?) -> Data
  
  func sign(
    using manager: EtherKeyManager,
    with address: Address,
    network: Network?,
    completion: @escaping (Result<Signature, EtherKitError>) -> Void
  ) throws
}

public extension Signable {
  public func sign(
    using manager: EtherKeyManager,
    with address: Address,
    network: Network?,
    completion: @escaping (Result<Signature, EtherKitError>) -> Void
  ) {
    do {
      try manager.signRaw(signatureData(network), for: address) { rawSignature, recoveryID in
        let rValueRaw = BigUInt(rawSignature.subdata(in: rawSignature.startIndex ..< (rawSignature.startIndex + 32)))
        let sValueRaw = BigUInt(rawSignature.subdata(in: rawSignature.startIndex + 32 ..< rawSignature.count))

        let networkValue = network?.rawValue ?? 0
        completion(.success(Signature(
          v: recoveryID + 27 + (networkValue > 0 ? networkValue * 2 + 8 : 0),
          r: UInt256(rValueRaw).toPaddedData(),
          s: UInt256(sValueRaw).toPaddedData()
        )))
      }
    } catch let error as EtherKitError {
      completion(.failure(error))
    } catch {
      completion(.failure(.unknown(error: error)))
    }
  }
}

extension Data: Signable {
  public func signatureData(_: Network?) -> Data {
    return self
  }
}

extension String: Signable {
  public func signatureData(_: Network?) -> Data {
    let message = data(using: .utf8)!
    let prefix = "\u{19}Ethereum Signed Message:\n\(message.count)".data(using: .utf8)!
    return prefix + message
  }
}

extension RLPData: Signable {
  public func signatureData(_: Network?) -> Data {
    return data
  }
}

public struct Signature: Marshaling, RLPComplexType, CustomStringConvertible {
  public var v: UInt
  public var r: Data
  public var s: Data
  
  public init(v: UInt, r: Data, s: Data) {
    self.v = v
    self.r = r
    self.s = s
  }

  // MARK: - Marshaling

  public func marshaled() -> [String: Any] {
    return [
      "v": String(describing: GeneralData(data: v.packedData)),
      "r": String(describing: GeneralData(data: r)),
      "s": String(describing: GeneralData(data: s)),
    ]
  }

  public var description: String {
    let sigData = r + s + v.packedData
    return sigData.paddedHexString
  }
  
  // MARK: - RLPComplexType
  
  public func toRLPValue() -> [RLPValueType] {
    return [v, r, s]
  }
}
