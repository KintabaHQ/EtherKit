//
//  UnformattedDataType.swift
//  BigInt
//
//  Created by Cole Potrocky on 3/22/18.
//

enum UnformattedDataMode {
  case constrained(UInt)
  case unlimited
}

protocol UnformattedDataType: CustomStringConvertible, Encodable {
  static var byteCount: UnformattedDataMode { get }
  var describing: [UInt8] { get }

  init(describing: [UInt8])
  init?(describing: String)
}

extension UnformattedDataType {
  public var description: String {
    return describing.reduce("0x") { return "\($0)\(String(format: "%02x", $1))" }
  }
  
  public init?(describing: String) {
    guard let describing = describing.hexToBytes else {
      return nil
    }
    
    switch Self.byteCount {
    case .constrained(let by):
      guard describing.count == by else {
        return nil
      }
    case .unlimited:
      break
    }
    
    self.init(describing: describing)
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(String(describing: describing))
  }
}

