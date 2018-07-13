//
//  EstimateGasRequest.swift
//  EtherKit
//
//  Created by Cole Potrocky on 7/12/18.
//

import Marshal

public class EstimateGasRequest: Request {
  public struct Parameters: Marshaling {
    let from: Address?
    let to: Address
    let gasLimit: UInt256?
    let gasPrice: UInt256?
    let value: UInt256?
    let data: GeneralData?

    // MARK: - Marshaling

    public func marshaled() -> [String: Any] {
      return [
        "from": from as Any?,
        "to": to,
        "gasLimit": gasLimit,
        "gasPrice": gasPrice,
        "value": value,
        "data": data,
      ].compactMapValues { value in
        guard let value = value else { return nil }
        return String(describing: value)
      }
    }
  }

  public typealias Result = UInt256

  public var parameters: Parameters

  public var method: String {
    return "eth_estimateGas"
  }

  init(_ parameters: Parameters) {
    self.parameters = parameters
  }
}
