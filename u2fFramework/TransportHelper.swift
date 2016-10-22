//
//  TransportHelper.swift
//  u2f-ble-test-ios
//
//  Created by Nicolas Bigot on 16/05/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

internal class TransportHelper {
    
    internal enum CommandType: UInt8 {
        case ping = 0x81
        case keepAlive = 0x82
        case message = 0x83
        case error = 0xbf
    }
    
    internal enum ChunkType {
        case ping
        case keepAlive
        case message
        case error
        case continuation
        case unknown
    }
    
    static func getChunkType(data: Data) -> ChunkType {
        let reader = DataReader(data: data)
        guard let byte = reader.readNextUInt8() else { return .unknown }
        if byte & 0x80 == 0 { return .continuation }
        guard let type = CommandType(rawValue: byte) else { return .unknown }
        
        switch type {
        case .ping: return .ping
        case .keepAlive: return .keepAlive
        case .message: return .message
        case .error: return .error
        }
    }
    
    static func split(data: Data, command: CommandType, chunkSize: Int) -> [Data]? {
        guard chunkSize >= 8, data.count > 0, data.count <= Int(UInt16.max) else { return nil }
        var chunks: [Data] = []
        var remainingLength = data.count
        var firstChunk = true
        var sequence: UInt8 = 0
        var offset = 0
        
        while remainingLength > 0 {
            var length = 0
            let writer = DataWriter()
            
            if firstChunk {
                writer.writeNextUInt8(command.rawValue)
                writer.writeNextBigEndianUInt16(UInt16(remainingLength))
                length = min(chunkSize - 3, remainingLength)
            }
            else {
                writer.writeNextUInt8(sequence)
                length = min(chunkSize - 1, remainingLength)
            }
            writer.writeNextData(data.subdata(in: offset ..< offset + length))
            remainingLength -= length
            offset += length
            chunks.append(writer.data)
            if !firstChunk { sequence += 1 }
            firstChunk = false
        }
        return chunks
    }
    
    static func join(chunks: [Data], command: CommandType) -> Data? {
        let writer = DataWriter()
        var sequence: UInt8 = 0
        var length = -1
        var firstChunk = true
        
        for chunk in chunks {
            let reader = DataReader(data: chunk)
            if firstChunk {
                guard let readCommand = reader.readNextUInt8(),
                      let readLength = reader.readNextBigEndianUInt16(),
                      readCommand == command.rawValue
                else { return nil }
                
                length = Int(readLength)
                writer.writeNextData(chunk.subdata(in: 3 ..< chunk.count))
                length -= chunk.count - 3
                firstChunk = false
            }
            else {
                guard let readSequence = reader.readNextUInt8(), readSequence == sequence
                else { return nil }
                writer.writeNextData(chunk.subdata(in: 1 ..< chunk.count))
                length -= chunk.count - 1
                sequence += 1
            }
        }
        if length != 0 { return nil }
        return writer.data
    }
    
}
