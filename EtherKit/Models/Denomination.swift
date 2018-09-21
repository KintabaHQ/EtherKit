//
//  Denomination.swift
//  EtherKit
//
//  Created by Cole Potrocky on 7/24/18.
//

import BigInt

public enum Denomination: BigUInt {
  case wei = 1
  case kwei = 1000
  case mwei = 1_000_000
  case gwei = 1_000_000_000
  case microether = 1_000_000_000_000
  case milliether = 1_000_000_000_000_000
  case ether = 1_000_000_000_000_000_000

  public var abbreviation: String {
    switch self {
    case .wei:
      return "wei"
    case .kwei:
      return "Kwei"
    case .mwei:
      return "Mwei"
    case .gwei:
      return "Gwei"
    case .microether:
      return "µEth"
    case .milliether:
      return "mEth"
    case .ether:
      return "eth"
    }
  }

  public var informalName: String {
    switch self {
    case .wei:
      return "wei"
    case .kwei:
      return "babbage"
    case .mwei:
      return "lovelace"
    case .gwei:
      return "shannon"
    case .microether:
      return "szabo"
    case .milliether:
      return "finney"
    case .ether:
      return "ether"
    }
  }

  public static var defaultNumberFormatter: NumberFormatter {
    let numberFormatter = NumberFormatter()
    numberFormatter.numberStyle = .decimal
    numberFormatter.maximumSignificantDigits = 8
    numberFormatter.minimumSignificantDigits = 4
    numberFormatter.locale = Locale.current
    return numberFormatter
  }

  public static func formatNumber(
    _ value: UInt256,
    for denomination: Denomination,
    with numberFormatter: NumberFormatter = Denomination.defaultNumberFormatter
  ) -> String {
    let formattedNumber = numberFormatter.string(
      from: NSNumber(value: convert(value, to: denomination))
    )
    return "\(formattedNumber) \(denomination.abbreviation)"
  }

  public static func convert(
    _ value: UInt256,
    to denomination: Denomination
  ) -> Double {
    let (quotient, remainder) = value.value.quotientAndRemainder(dividingBy: denomination.rawValue)
    return Double(quotient) + Double(remainder) / Double(denomination.rawValue)
  }

  public static func convert(
    _ value: Double,
    from denomination: Denomination
  ) -> UInt256 {
    return UInt256(BigUInt(value * Double(denomination.rawValue)))
  }
}
