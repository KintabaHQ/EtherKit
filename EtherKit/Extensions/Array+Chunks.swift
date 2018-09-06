//
//  Array+Chunks.swift
//  BigInt
//
//  Created by Cole Potrocky on 8/2/18.
//

import Foundation

// Taken from:
// https://stackoverflow.com/questions/26395766/swift-what-is-the-right-way-to-split-up-a-string-resulting-in-a-string-wi/38156873#38156873
extension Array {
  func chunks(_ chunkSize: Int) -> [[Element]] {
    return stride(from: 0, to: count, by: chunkSize).map {
      Array(self[$0 ..< Swift.min($0 + chunkSize, self.count)])
    }
  }
}
