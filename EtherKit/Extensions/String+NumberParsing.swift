//
//  String+NumberParsing.swift
//  EtherKit
//
//  Created by Cole Potrocky on 3/20/18.
//

extension String {
  var dropHexPrefix: String {
    return hasHexPrefix ? String(dropFirst(2)) : self
  }

  var hexToUInt256: UInt256? {
    return try? UInt256(from: self)
  }

  public var hexToBytes: Data? {
    let str = dropHexPrefix.lowercased()
    guard str.count % 2 == 0 else {
      return nil
    }

    let numOfBytes = str.count / 2
    var bytes = Data(capacity: numOfBytes)

    var index = str.startIndex
    for _ in 0 ..< numOfBytes {
      let offsetIndex = str.index(index, offsetBy: 2)
      guard let byte = UInt8(str[index ..< offsetIndex], radix: 16) else {
        return nil
      }
      bytes.append(byte)
      index = offsetIndex
    }

    return bytes
  }

  public var hasHexPrefix: Bool {
    return hasPrefix("0x")
  }
}
