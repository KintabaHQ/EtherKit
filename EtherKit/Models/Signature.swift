//
//  Signature.swift
//  EtherKit
//
//  Created by Zac Morris on 2018-05-10.
//

import BigInt
import Marshal
import Result

public protocol Signable {
  func signatureData(_ network: Network?) -> Data

  var usesReplayProtection: Bool { get }

  func sign<T: PrivateKeyImplType>(
    using impl: T,
    network: Network?
  ) -> Result<Signature, EtherKitError>
}

public extension Signable {
  public func sign<T: PrivateKeyImplType>(
    using impl: T,
    network: Network?
  ) -> Result<Signature, EtherKitError> {
    return impl.sign(signatureData(network)).map {
      let (signature, recoveryID) = $0

      let rValueRaw = BigUInt(signature.subdata(in: signature.startIndex ..< signature.startIndex + 32))
      let sValueRaw = BigUInt(signature.subdata(in: signature.startIndex + 32 ..< signature.count))

      let networkValue = network?.rawValue ?? 0
      return Signature(
        v: UInt(recoveryID) + 27 + ((self.usesReplayProtection && networkValue > 0) ? networkValue * 2 + 8 : 0),
        r: UInt256(rValueRaw).toPaddedData(),
        s: UInt256(sValueRaw).toPaddedData()
      )
    }
  }

  public func sign<T: PrivateKeyType>(
    using key: T,
    network: Network?,
    queue: DispatchQueue = DispatchQueue.global(qos: .default),
    completion: @escaping (Result<Signature, EtherKitError>) -> Void
  ) {
    return key.unlocked(queue: queue) {
      completion($0.flatMap { impl in self.sign(using: impl, network: network) })
    }
  }
}

extension Data: Signable {
  public func signatureData(_: Network?) -> Data {
    return self
  }

  public var usesReplayProtection: Bool {
    return false
  }
}

extension String: Signable {
  public func signatureData(_: Network?) -> Data {
    let message: Data
    if hasHexPrefix, let messageData = self.hexToBytes {
      message = messageData
    } else {
      message = data(using: .utf8)!
    }

    let prefix = "\u{19}Ethereum Signed Message:\n\(message.count)".data(using: .utf8)!
    return prefix + message
  }

  public var usesReplayProtection: Bool {
    return false
  }
}

extension RLPData: Signable {
  public func signatureData(_: Network?) -> Data {
    return data
  }

  public var usesReplayProtection: Bool {
    return false
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
