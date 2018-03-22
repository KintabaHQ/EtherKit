//
//  Address.swift
//  EtherKit
//
//  Created by Cole Potrocky on 3/21/18.
//

struct Address {
  private static let validAddressRegex = "[0-9][A-F][a-f]{40}"
  static func isValid(from: String) -> Bool {
    guard from.hasHexPrefix else {
      return false
    }
    
    let hexNumber = from.dropHexPrefix
    let rgx = try? NSRegularExpression(pattern: validAddressRegex, options: [])
    
    guard let numMatches = rgx?.numberOfMatches(in: hexNumber, options: [], range: NSRangeFromString(hexNumber)) else {
      return false
    }
    
    return numMatches > 0
  }
  
  // Since addresses are almost exclusively displayed and stored as
  // 40 character hexadecimal strings, we're just storing them within
  // a struct as such so that they are effectively are immutable strings.
  let value: String
  
  init?(_ value: String) {
    guard Address.isValid(from: value) else {
      return nil
    }
    self.value = value
  }
}

extension Address: CustomStringConvertible {
  var description: String {
    return value
  }
}

// We should not call this as a top-level JSON fragment, see:
// https://bugs.swift.org/browse/SR-6163
// ... while "blah" is valid JSON, Swift doesn't think so.
extension Address: Encodable {
  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(value)
  }
}

extension Address: Decodable {
  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let maybeValue = try container.decode(String.self)
    
    guard Address.isValid(from: maybeValue) else {
      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Address \(maybeValue) is not a valid String representation for an Ethereum Address."
      )
    }
    
    value = maybeValue
  }
}
