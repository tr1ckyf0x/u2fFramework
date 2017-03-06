//
//  DataReaderTests.swift
//  u2fFramework
//
//  Created by Владислав Лисянский on 18.10.16.
//  Copyright © 2016 Владислав Лисянский. All rights reserved.
//

import XCTest
@testable import u2fFramework

class DataReaderTests: XCTestCase {
    
  func testReadNextUInt8() {
    let controlArray: [UInt8] = [0,1,2,3,4,5]
    let reader = DataReader(data: Data(bytes: controlArray))
    var testableArray: [UInt8] = []
    for _ in 0 ..< controlArray.count {
      guard let value = reader.readNextUInt8() else { XCTFail(); return }
      testableArray.append(value)
    }
    XCTAssertEqual(controlArray, testableArray)
  }
    
  func testReadNextBigEndianUInt32() {
    let controlArray: [UInt32] = [0x99887766,0x55443322]
    let reader = DataReader(data: Data(bytes: [0x99,0x88,0x77,0x66,0x55,0x44,0x33,0x22]))
    var testableArray: [UInt32] = []
    for _ in 0 ..< controlArray.count {
      guard let value = reader.readNextBigEndianUInt32() else { XCTFail(); return }
      testableArray.append(value)
    }
    XCTAssertEqual(controlArray, testableArray)
  }
  
  func testReadNextLittleEndianUInt32() {
    let controlArray: [UInt32] = [0x66778899,0x22334455]
    let reader = DataReader(data: Data(bytes: [0x99,0x88,0x77,0x66,0x55,0x44,0x33,0x22]))
    var testableArray: [UInt32] = []
    for _ in 0 ..< controlArray.count {
      guard let value = reader.readNextLittleEndianUInt32() else { XCTFail(); return }
      testableArray.append(value)
    }
    XCTAssertEqual(controlArray, testableArray)
  }
    
  func testReadNextAvailableData() {
    let reader = DataReader(data: Data(bytes: [0x99,0x88,0x77,0x66,0x55,0x44,0x33,0x22]))
    let _ = reader.readNextBigEndianUInt16()
    
    guard let value = reader.readNextAvailableData() else { XCTFail(); return }
    XCTAssertEqual(value, Data(bytes: [0x77,0x66,0x55,0x44,0x33,0x22]))
  }
    
  func testReadNextDataOfLength() {
    let reader = DataReader(data: Data(bytes: [0x99,0x88,0x77,0x66,0x55,0x44,0x33,0x22]))
    guard let firstValue = reader.readNextDataOfLength(3),
      let secondValue = reader.readNextDataOfLength(5)
      else { XCTFail(); return }
    XCTAssertEqual(firstValue, Data(bytes: [0x99, 0x88, 0x77]))
    XCTAssertEqual(secondValue, Data(bytes: [0x66,0x55,0x44,0x33,0x22]))
  }
}
