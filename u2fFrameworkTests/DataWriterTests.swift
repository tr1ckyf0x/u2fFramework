//
//  DataWriterTests.swift
//  u2fFramework
//
//  Created by Владислав Лисянский on 18.10.16.
//  Copyright © 2016 Владислав Лисянский. All rights reserved.
//

import XCTest
@testable import u2fFramework

class DataWriterTests: XCTestCase {
    
    func testWriteNextUInt8() {
        let writer = DataWriter()
        writer.writeNextUInt8(0xFF)
        let controlData = Data(bytes: [0xFF])
        XCTAssertEqual(controlData, writer.data)
    }
    
    func testWriteNextInt8() {
        let writer = DataWriter()
        writer.writeNextInt8(Int8(123))
        let controlData = Data(bytes: [123])
        XCTAssertEqual(controlData, writer.data)
    }
    
    func testWriteNextBigEndianUInt16() {
        let writer = DataWriter()
        writer.writeNextBigEndianUInt16(0x587A)
        let controlData = Data(bytes: [0x58, 0x7A])
        XCTAssertEqual(controlData, writer.data)
    }
    
    func testWriteNextLittleEndianUInt16() {
        let writer = DataWriter()
        writer.writeNextLittleEndianUInt16(0x587A)
        let controlData = Data(bytes: [0x7A, 0x58])
        XCTAssertEqual(controlData, writer.data)
    }
    
    func testWriteNextBigEndianUInt64() {
        let writer = DataWriter()
        writer.writeNextBigEndianUInt64(0x587A)
        let controlData = Data(bytes: [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x58, 0x7A])
        XCTAssertEqual(controlData, writer.data)
    }
    
    func testWriteNextLittleEndianUInt64() {
        let writer = DataWriter()
        writer.writeNextLittleEndianUInt64(0x587A)
        let controlData = Data(bytes: [0x7A, 0x58, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        XCTAssertEqual(controlData, writer.data)
    }
}
