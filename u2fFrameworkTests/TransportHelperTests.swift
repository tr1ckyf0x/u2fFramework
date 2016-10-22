//
//  TransportHelperTests.swift
//  u2fFramework
//
//  Created by Владислав Лисянский on 18.10.16.
//  Copyright © 2016 Владислав Лисянский. All rights reserved.
//

import XCTest
@testable import u2fFramework

class TransportHelperTests: XCTestCase {
    
    func testSplitWithChunkSizeMoreThanData() {
        let data = Data(bytes: [0,1,2,3,4,5,6,7,8,9,10])
        guard let chunks = TransportHelper.split(data: data, command: .message, chunkSize: 20) else { XCTFail(); return }
        let controlData = [Data(bytes: [0x83,0x00,0x0B,0,1,2,3,4,5,6,7,8,9,10])]
        XCTAssertEqual(chunks, controlData)
    }
    
    func testSplitWithChunkSizeEqualData() {
        let data = Data(bytes: [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16])
        guard let chunks = TransportHelper.split(data: data, command: .message, chunkSize: 20) else { XCTFail(); return }
        let controlData = [Data(bytes: [0x83,0x00,0x11,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16])]
        XCTAssertEqual(chunks, controlData)
    }
    
    func testSplitWithChunkSizeLessThanData() {
        let data = Data(bytes: [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20])
        guard let chunks = TransportHelper.split(data: data, command: .message, chunkSize: 20) else { XCTFail(); return }
        let controlData = [Data(bytes: [0x83,0x00,0x15,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16]), Data(bytes: [0x00,17,18,19,20])]
        XCTAssertEqual(chunks, controlData)
    }
    
    func testJoinWithTwoChunks() {
        let chunks = [Data(bytes: [0x83,0x00,0x14,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16]), Data(bytes: [0x00,17,18,19])]
        guard let data = TransportHelper.join(chunks: chunks, command: .message) else { XCTFail(); return }
        let controlData = Data(bytes: [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19])
        XCTAssertEqual(data, controlData)
    }
    
    func testJoinWithOneChunk() {
        let chunks = [Data(bytes: [0x83,0x00,0xA,0,1,2,3,4,5,6,7,8,9])]
        guard let data = TransportHelper.join(chunks: chunks, command: .message) else { XCTFail(); return }
        let controlData = Data(bytes: [0,1,2,3,4,5,6,7,8,9])
        XCTAssertEqual(data, controlData)
    }
    
    func testJoinWithLengthMoreThanData() {
        let chunks = [Data(bytes: [0x83,0x00,0x09,0,1,2,3,4,5,6,7,8,9])]
        XCTAssertNil(TransportHelper.join(chunks: chunks, command: .message))
    }
    
    func testJoinWithLengthLessThanData() {
        let chunks = [Data(bytes: [0x83,0x00,0x0A,0,1,2,3,4,5,6,7,8,9,10])]
        XCTAssertNil(TransportHelper.join(chunks: chunks, command: .message))
    }
}
