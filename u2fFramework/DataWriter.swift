//
//  DataWriter.swift
//  u2fFramework
//
//  Created by Владислав Лисянский on 18.10.16.
//  Copyright © 2016 Владислав Лисянский. All rights reserved.
//

import Foundation

internal class DataWriter {
  private(set) var data = Data()
  var count: Int { return data.count }
    
  // MARK: Write methods

  func writeNextUInt8(_ value: UInt8) {
    writeNextInteger(value: value)
  }
    
  func writeNextInt8(_ value: Int8) {
    writeNextInteger(value: value)
  }
    
  func writeNextBigEndianUInt16(_ value: UInt16) {
    writeNextInteger(value: value, bigEndian: true)
  }
    
  func writeNextLittleEndianUInt16(_ value: UInt16) {
    writeNextInteger(value: value, bigEndian: false)
  }
    
  func writeNextBigEndianInt16(_ value: Int16) {
    writeNextInteger(value: value, bigEndian: true)
  }
    
  func writeNextLittleEndianInt16(_ value: Int16) {
    writeNextInteger(value: value, bigEndian: false)
  }
    
  func writeNextBigEndianUInt32(_ value: UInt32) {
    writeNextInteger(value: value, bigEndian: true)
  }

  func writeNextLittleEndianUInt32(_ value: UInt32) {
    writeNextInteger(value: value, bigEndian: false)
  }
    
  func writeNextBigEndianInt32(_ value: Int32) {
    writeNextInteger(value: value, bigEndian: true)
  }
    
  func writeNextLittleEndianInt32(_ value: Int32) {
    writeNextInteger(value: value, bigEndian: false)
  }
    
  func writeNextBigEndianUInt64(_ value: UInt64) {
    writeNextInteger(value: value, bigEndian: true)
  }
    
  func writeNextLittleEndianUInt64(_ value: UInt64) {
    writeNextInteger(value: value, bigEndian: false)
  }
    
  func writeNextBigEndianInt64(_ value: Int64) {
    writeNextInteger(value: value, bigEndian: true)
  }
    
  func writeNextLittleEndianInt64(_ value: Int64) {
    writeNextInteger(value: value, bigEndian: false)
  }
    
  func writeNextData(_ data: Data) {
    self.data.append(data)
  }
    
  private func writeNextInteger<T: Integer>(value: T) {
    var value = value
    self.data.append(UnsafeBufferPointer(start: &value, count: 1))
  }
    
  private func writeNextInteger<T: EndianConvertible>(value: T, bigEndian: Bool) {
    var value = value
    value = bigEndian ? value.bigEndian : value.littleEndian
    self.data.append(UnsafeBufferPointer(start: &value, count: 1))
  }
}
