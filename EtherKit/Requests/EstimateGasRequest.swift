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

    public func marshaled() -> [Any] {
      let dictionary: [String: Any] = [
        "from": from,
        "to": to,
        "gasLimit": gasLimit,
        "gasPrice": gasPrice,
        "value": value,
        "data": data,
      ].compactMapValues { (value: Any?) in
        guard let value = value else { return nil }
        return String(describing: value)
      }
      return [dictionary]
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
