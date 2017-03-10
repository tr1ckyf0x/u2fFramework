//
//  CryptoHelper.swift
//  u2fFramework
//
//  Created by Владислав Лисянский on 05/03/2017.
//  Copyright © 2017 Владислав Лисянский. All rights reserved.
//

import Foundation
import Security

@objc public final class CryptoHelper: NSObject {
  
  public static func verifyRegisterSignature(certificate: Data, signature: Data, keyHandle: Data, publicKey: Data, applicationParameter: Data, challenge: Data) ->  Bool {
    guard let extractedSignaturePoints = extractPointsFromSignature(signature: signature)
      else { return false }
    
    var trustRef: SecTrust? = nil
    let policy = SecPolicyCreateBasicX509()
    guard let certificateRef = SecCertificateCreateWithData(nil, certificate as CFData) else { return false }
    guard SecTrustCreateWithCertificates(certificateRef, policy, &trustRef) == errSecSuccess &&
        trustRef != nil
      else { return false }
    let key = SecTrustCopyPublicKey(trustRef!)
    guard let certificatePublicKey = getPublicKeyBitsFromKey(key) else { return false }
    
    // check signature
    let crypto = GMEllipticCurveCrypto(forKey: certificatePublicKey)
    var data = Data()
    data.append([0x00] as [UInt8], count: 1)
    data.append(applicationParameter)
    data.append(challenge)
    data.append(keyHandle)
    data.append(publicKey)
    var extractedSignature = Data()
    extractedSignature.append(extractedSignaturePoints.r)
    extractedSignature.append(extractedSignaturePoints.s)
    return crypto!.hashSHA256AndVerifySignature(extractedSignature, for: data)
  }
  
  public static func verifyAuthenticateSignature(publicKey: Data, userPresenceFlag: UInt8, counter: UInt32, signature: Data, applicationParameter: Data, challenge: Data) ->  Bool {
    guard let extractedSignaturePoints = extractPointsFromSignature(signature: signature)
      else { return false }
    
    // check signature
    let crypto = GMEllipticCurveCrypto(forKey: publicKey)
    let writer = DataWriter()
    writer.writeNextData(applicationParameter)
    writer.writeNextUInt8(userPresenceFlag)
    writer.writeNextBigEndianUInt32(counter)
    writer.writeNextData(challenge)
    var extractedSignature = Data()
    extractedSignature.append(extractedSignaturePoints.r)
    extractedSignature.append(extractedSignaturePoints.s)
    return crypto!.hashSHA256AndVerifySignature(extractedSignature, for: writer.data)
  }
  
  static func extractPointsFromSignature(signature: Data) -> (r: Data, s: Data)? {
    let reader = DataReader(data: signature)
    guard
      let _ = reader.readNextUInt8(), // 0x30
      let _ = reader.readNextUInt8(), // length
      let _ = reader.readNextUInt8(), // 0x20
      let rLength = reader.readNextUInt8(),
      var r = reader.readNextDataOfLength(Int(rLength)),
      let _ = reader.readNextUInt8(), // 0x20
      let sLength = reader.readNextUInt8(),
      var s = reader.readNextDataOfLength(Int(sLength))
      else { return nil }
    
    if r.first == 0x00 {
      r.removeFirst()
    }
    if s.first == 0x00 {
      s.removeFirst()
    }
    return (r, s)
  }
  
}
