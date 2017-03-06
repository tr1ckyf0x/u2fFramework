//
//  UtilsTests.swift
//  u2fFramework
//
//  Created by Владислав Лисянский on 18.10.16.
//  Copyright © 2016 Владислав Лисянский. All rights reserved.
//

import XCTest
@testable import u2fFramework

class UtilsTests: XCTestCase {
  func testGettingLSBytesWithDefaultCount() {
    let controlArrayForInt64: [UInt8] = [0,0,0,0,0,0,0x07,0xD0]
    let controlArrayForInt32: [UInt8] = [0,0,0x07,0xD0]
    XCTAssert(controlArrayForInt32 == getLSBytes(value: 2000) || controlArrayForInt64 == getLSBytes(value: 2000))
  }
  func testGettingLSBytesWithHigherCount() {
    let controlArray: [UInt8] = [0,0,0,0,0,0,0,0,0x07,0xD0]
    XCTAssertEqual(controlArray, getLSBytes(value: 2000, count: 10))
  }
  
  func testGettingLSBytesWithLessCount() {
    let controlArray: [UInt8] = [0,0x07,0xD0]
    XCTAssertEqual(controlArray, getLSBytes(value: 2000, count: 3))
  }
  
  func testHexToUInt8() {
    let string = "00ffab030405fe"
    guard let checkingArray = string.hexToUInt8Array() else { XCTFail(); return }
    let controlArray: [UInt8] = [0, 0xFF, 0xAB, 0x03, 0x04, 0x05, 0xFE]
    XCTAssertEqual(controlArray, checkingArray)
  }
}
