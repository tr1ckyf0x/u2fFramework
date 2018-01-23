//
//  APDU.swift
//  u2fFramework
//
//  Created by Владислав Лисянский on 17.10.16.
//  Copyright © 2016 Владислав Лисянский. All rights reserved.
//

import Foundation

public enum APDUError: Error {
  case parseError
}

public enum U2FNativeCommands: UInt8 {
  case register =             0x81 /* Registration command */
  case authenticate =         0x82 /* Authenticate/sign command */
  case version =              0x83 /* Read version string command */
  case checkRegister =        0x84 /* Registration command that incorporates checking key handles */
  case authenticateBatch =    0x85 /* Authenticate/sign command for a batch of key handles */
}

public enum P1Parameter: UInt8 {
  case registerHashID = 0x00 /* Version 2 hash identintifier */
  case registerID = 0x05 /* Version 2 registration identifier */
  case authEnforce = 0x03 /* Enforce user presence and sign */
  case authCheckOnly =  0x07 /* Check only */
  case authFlagTup =    0x01 /* Test of user presence set */
}

public struct APDU {
  private static let reservedByte: UInt8 = 0x05
  private static let derSeqByte: UInt8 = 0x30
  private static let derLen1Byte: UInt8 = 0x81
  private static let derLen2Byte: UInt8 = 0x82
  
  private let CLA: UInt8 = 0x00
  private var INS: UInt8
  private var P1: UInt8
  private var P2: UInt8
  private var LC1: UInt8
  private var LC2: UInt8
  private var LC3: UInt8
  private var DATA: [UInt8]
  
  public init(challengeParameter: [UInt8], applicationParameter: [UInt8]) {
    self.init(INS: .register, P1: .registerHashID, DATA: challengeParameter + applicationParameter)
  }
  
  public init(challengeParameter: [UInt8], applicationParameter: [UInt8], keyHandle: [UInt8]) {
    self.init(INS: .authenticate, P1: .authEnforce, DATA: challengeParameter + applicationParameter + [UInt8(keyHandle.count)] + keyHandle)
  }
  
  public init(INS: U2FNativeCommands, P1: P1Parameter, P2: UInt8 = 0, DATA: [UInt8]) {
    self.INS = INS.rawValue
    self.P1 = P1.rawValue
    self.P2 = P2
    let dataSizeBytes = getLSBytes(value: DATA.count, count: 3)
    LC1 = dataSizeBytes[0]
    LC2 = dataSizeBytes[1]
    LC3 = dataSizeBytes[2]
    self.DATA = DATA
  }
    
  public func getData() -> Data {
    return Data(bytes: [CLA, INS, P1, P2, LC1, LC2, LC3] + DATA)
  }
    
  public static func parseRegistrationResponse(_ data: Data) throws -> (publicKey: Data, keyHandle: Data, attestationCertificate: Data, signature: Data) {
    let reader = DataReader(data: data)
    guard
      let reservedByte = reader.readNextUInt8(), reservedByte == APDU.reservedByte,
      let publicKey = reader.readNextDataOfLength(65),
      let keyHandleLength = reader.readNextUInt8(),
      let keyHandle = reader.readNextDataOfLength(Int(keyHandleLength))
      else { throw APDUError.parseError }
        
    // certificate
    guard
      let derSequence1 = reader.readNextUInt8(), derSequence1 == APDU.derSeqByte,
      let derCertificateLengthKind = reader.readNextUInt8()
      else { throw APDUError.parseError }
    
    var certificateLength = 0
    switch derCertificateLengthKind {
    case APDU.derLen1Byte:
      guard let readLength = reader.readNextUInt8() else { throw APDUError.parseError }
      certificateLength = Int(readLength)
    case APDU.derLen2Byte:
      guard let readLength = reader.readNextBigEndianUInt16() else { throw APDUError.parseError }
      certificateLength = Int(readLength)
    default: throw APDUError.parseError
    }
    guard let certificate = reader.readNextDataOfLength(certificateLength)
      else { throw APDUError.parseError }
    
    let writer = DataWriter()
    writer.writeNextUInt8(derSequence1)
    writer.writeNextUInt8(derCertificateLengthKind)
    
    switch derCertificateLengthKind {
    case APDU.derLen1Byte: writer.writeNextUInt8(UInt8(certificateLength))
    case APDU.derLen2Byte: writer.writeNextBigEndianUInt16(UInt16(certificateLength))
    default: throw APDUError.parseError
    }

    writer.writeNextData(certificate)
    let finalCertificate = writer.data
        
    // signature
    guard
      let derSequence2 = reader.readNextUInt8(), derSequence2 == APDU.derSeqByte,
      let signatureLength = reader.readNextUInt8(),
      let signature = reader.readNextDataOfLength(Int(signatureLength))
      else { throw APDUError.parseError }
    
    var finalSignature = Data()
    finalSignature.append([derSequence2], count: 1)
    finalSignature.append([signatureLength], count: 1)
    finalSignature.append(signature)
    
    return (publicKey, keyHandle, finalCertificate, finalSignature)
  }
  
  public static func parseAuthenticationResponse(_ data: Data) throws -> (userPresence: UInt8, counter: UInt32, signature: Data) {
    
    let reader = DataReader(data: data)
    
    guard
      let userPresence = reader.readNextUInt8(),
      let counter = reader.readNextBigEndianUInt32()
      else { throw APDUError.parseError }
    
    guard
      let derSequence = reader.readNextUInt8(), derSequence == APDU.derSeqByte,
      let signatureLength = reader.readNextUInt8(),
      let signature = reader.readNextDataOfLength(Int(signatureLength))
      else { throw APDUError.parseError }
        
    var finalSignature = Data()
    finalSignature.append([derSequence], count: 1)
    finalSignature.append([signatureLength], count: 1)
    finalSignature.append(signature)
        
    return (userPresence,counter,finalSignature)
  }
}
