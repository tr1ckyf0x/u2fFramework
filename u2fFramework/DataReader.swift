//
//  DataReader.swift
//  u2fFramework
//
//  Created by Владислав Лисянский on 18.10.16.
//  Copyright © 2016 Владислав Лисянский. All rights reserved.
//

import Foundation

internal class DataReader {
  private(set) var data: Data
  var remainingBytesCount: Int { return data.count }
    
  // MARK: Read methods
  
  func readNextInt8() -> Int8? {
    return readNextInteger()
  }
    
  func readNextUInt8() -> UInt8? {
    return readNextInteger()
  }
  
  func readNextBigEndianUInt16() -> UInt16? {
    return readNextInteger(bigEndian: true)
  }

  func readNextLittleEndianUInt16() -> UInt16? {
    return readNextInteger(bigEndian: false)
  }
    
  func readNextBigEndianInt16() -> Int16? {
    return readNextInteger(bigEndian: true)
  }
    
  func readNextLittleEndianInt16() -> Int16? {
    return readNextInteger(bigEndian: false)
  }
    
  func readNextBigEndianUInt32() -> UInt32? {
    return readNextInteger(bigEndian: true)
  }
    
  func readNextLittleEndianUInt32() -> UInt32? {
    return readNextInteger(bigEndian: false)
  }
    
  func readNextBigEndianInt32() -> Int32? {
    return readNextInteger(bigEndian: true)
  }
    
  func readNextLittleEndianInt32() -> Int32? {
    return readNextInteger(bigEndian: false)
  }
    
  func readNextBigEndianUInt64() -> UInt64? {
    return readNextInteger(bigEndian: true)
  }
    
  func readNextLittleEndianUInt64() -> UInt64? {
    return readNextInteger(bigEndian: false)
  }
    
  func readNextBigEndianInt64() -> Int64? {
    return readNextInteger(bigEndian: true)
  }
    
  func readNextLittleEndianInt64() -> Int64? {
    return readNextInteger(bigEndian: false)
  }

  func readNextAvailableData() -> Data? {
    return readNextDataOfLength(remainingBytesCount)
  }

  func readNextDataOfLength(_ count: Int) -> Data? {
    guard count > 0, count <= self.data.count else { return nil }
    
    let data = self.data.subdata(in: 0 ..< count)
    self.data.removeSubrange(0 ..< count)
    return data
  }

  // MARK: Internal methods
    
  private func readNextInteger<T: Integer>() -> T? {
    guard let data = readNextDataOfLength(MemoryLayout<T>.size) else { return nil }
        
    var value: T = 0
    let _ = data.copyBytes(to: UnsafeMutableBufferPointer(start: &value, count: 1))
    return value
  }
    
  private func readNextInteger<T: EndianConvertible>(bigEndian: Bool) -> T? {
    guard let data = readNextDataOfLength(MemoryLayout<T>.size) else { return nil }
        
    var value: T = 0
    let _ = data.copyBytes(to: UnsafeMutableBufferPointer(start: &value, count: 1))
    return bigEndian ? value.bigEndian : value.littleEndian
  }
    
  // MARK: Initialization
    
  init(data: Data) {
    self.data = Data(data)
  }
}
