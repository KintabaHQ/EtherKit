//
//  Int+Bytes.swift
//  EtherKit
//
//  Created by Cole Potrocky on 8/13/18.
//

import Foundation

// Adapted from:
// https://stackoverflow.com/questions/29970204/split-uint32-into-uint8-in-swift
protocol ByteConvertibleType: BinaryInteger {
  var bytes: Data { get }
}

extension ByteConvertibleType {
  var bytes: Data {
    var num = self

    let size = MemoryLayout<Self>.size
    let ptr = withUnsafePointer(to: &num) {
      $0.withMemoryRebound(to: UInt8.self, capacity: size) {
        UnsafeBufferPointer(start: $0, count: size)
      }
    }

    return Data(bytes: [UInt8](ptr))
  }
}

extension UInt16: ByteConvertibleType {}
extension UInt32: ByteConvertibleType {}
