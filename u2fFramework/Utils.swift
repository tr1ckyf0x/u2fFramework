//
//  Utils.swift
//  u2fFramework
//
//  Created by Владислав Лисянский on 18.10.16.
//  Copyright © 2016 Владислав Лисянский. All rights reserved.
//

import Foundation

///Returns byte array of value
/// - returns: array of bytes in LittleEndian format.
/// If count > sizeof value appends 0 at the High bytes
/// - parameter count: Count of bytes
func getLSBytes<T: Integer>(value: T, count: Int = MemoryLayout<T>.size) -> [UInt8] {
  var input = value
  let data = NSData(bytes: &input, length: MemoryLayout<T>.size)
  var bytes = [UInt8](repeating: 0, count: count)
  data.getBytes(&bytes, length: count)
  return bytes.reversed()
}

public extension String {
  func hexToUInt8Array() -> [UInt8]? {
    let trimmedString = self.trimmingCharacters(in: CharacterSet(charactersIn: "<> ")).replacingOccurrences(of: " ", with: "")
    let regex = try! NSRegularExpression(pattern: "^[0-9a-f]*$", options: .caseInsensitive)
    let found = regex.firstMatch(in: trimmedString, options: [], range: NSMakeRange(0, trimmedString.characters.count))
    if found == nil || found?.range.location == NSNotFound || trimmedString.characters.count % 2 != 0 { return nil }
        
    var array: [UInt8] = []
    var index = trimmedString.startIndex
    while index < trimmedString.endIndex {
      let byteString = trimmedString.substring(with: Range<String.Index>(index ..< trimmedString.index(index, offsetBy: 2)))
      let num = UInt8(byteString, radix: 16)!
      array.append(num)
      index = trimmedString.index(index, offsetBy: 2)
    }
    return array
  }
}

extension Data {
  func hexEncodedString() -> String {
    return map { String(format: "%02hhx", $0) }.joined()
  }
}
