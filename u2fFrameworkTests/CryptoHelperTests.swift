//
//  CryptoHelperTests.swift
//  u2fFramework
//
//  Created by Владислав Лисянский on 05/03/2017.
//  Copyright © 2017 Владислав Лисянский. All rights reserved.
//

import XCTest
@testable import u2fFramework
class CryptoHelperTests: XCTestCase {
  
  let applicationParameter = Data(bytes: "F0E6A6A97042A4F1F1C87F5F7D44315B2D852C2DF5C7991CC66241BF7072D1C4".hexToUInt8Array()!)
  let challengeParameter = Data(bytes: "4142D21C00D94FFB9D504ADA8F99B721F4B191AE4E37CA0140F696B6983CFACB".hexToUInt8Array()!)
  
  func testExtractPointsFromSignature() {
    let signature = Data(bytes: "304502200dfb6fcbeafa1e616c6a5cc1b8d62d6075735ec612984ebf779f57d923642980022100846ef0c928ffcac78c28ddc314e34c58ddf60e671547af385f4ae85e9203fe2e".hexToUInt8Array()!)
    let r = Data(bytes: "0dfb6fcbeafa1e616c6a5cc1b8d62d6075735ec612984ebf779f57d923642980".hexToUInt8Array()!)
    let s = Data(bytes: "846ef0c928ffcac78c28ddc314e34c58ddf60e671547af385f4ae85e9203fe2e".hexToUInt8Array()!)
    XCTAssert(CryptoHelper.extractPointsFromSignature(signature: signature)! == (r: r, s: s))
  }
  
  func testVerifyRegistrationResponseSignature() {
    let userPublicKey = Data(bytes: "045ed35e834856fa4c30b0cb254839ca74e64a2feda17f358032bc4041ab1204ccb0e172ba4944d7a603ddb93db3cafe507b4a4970c5b29762b6bf1ec50fa99d9e".hexToUInt8Array()!)
    let keyHandle = Data(bytes: "6aa5617037b423e6c6d9e9860de534a638b1652c5eb6ea22b91868edc2d7afc19c513f305c0af9326bf5c2c1f790b39d420adc656e18fa94810244269efafa18".hexToUInt8Array()!)
    let attestationCertificate = Data(bytes: "3082013c3081e4a003020102020a47901280001155957352300a06082a8648ce3d0403023017311530130603550403130c476e756262792050696c6f74301e170d3132303831343138323933325a170d3133303831343138323933325a3031312f302d0603550403132650696c6f74476e756262792d302e342e312d34373930313238303030313135353935373335323059301306072a8648ce3d020106082a8648ce3d03010703420004181be2627f3add0d35bb1cd63facba88d9687f62a8164708d2c4d18b4d306586dbc0f8387829e75b00c894c27f79e70c8e90cb169a7a9ec11a76ebe4b2bae2b1300a06082a8648ce3d0403020347003044022060cdb6061e9c22262d1aac1d96d8c70829b2366531dda268832cb836bcd30dfa0220631b1459f09e6330055722c8d89b7f48883b9089b88d60d1d9795902b30410df".hexToUInt8Array()!)
    let signature = Data(bytes: "304502200dfb6fcbeafa1e616c6a5cc1b8d62d6075735ec612984ebf779f57d923642980022100846ef0c928ffcac78c28ddc314e34c58ddf60e671547af385f4ae85e9203fe2e".hexToUInt8Array()!)
    
    XCTAssert(CryptoHelper.verifyRegisterSignature(certificate: attestationCertificate, signature: signature, keyHandle: keyHandle, publicKey: userPublicKey, applicationParameter: applicationParameter, challenge: challengeParameter))
  }
  
  func testVerifyAuthenticateSignature() {
    let userPresence = UInt8("01")!
    let counter = UInt32("00000004")!
    let signature = Data(bytes: "3045022100AC5708327BA162EC71AF28D41C19F13135A02462B05C8EC4B98DF5D7D41BA574022027CC9982028A7D2ADF9863898C34FBEEEACF35699FD8B2569F7AFCCE6C6881EC".hexToUInt8Array()!)
    let publicKey = Data(bytes: "04843dc11044915a50b198a26ed9a836e1a0405edf1c040d7fd27b9242d2a89af4a29df078a3350eb7b1d74f646664377bdf7ea07989d3a29d25076634237f2ce9".hexToUInt8Array()!)
    
    XCTAssert(CryptoHelper.verifyAuthenticateSignature(publicKey: publicKey, userPresenceFlag: userPresence, counter: counter, signature: signature, applicationParameter: applicationParameter, challenge: challengeParameter))
  }
  
}
