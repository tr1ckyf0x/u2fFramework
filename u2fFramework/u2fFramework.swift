//
//  u2fFramework.swift
//  u2fFramework
//
//  Created by Владислав Лисянский on 17.10.16.
//  Copyright © 2016 Владислав Лисянский. All rights reserved.
//

import Foundation

enum U2FFrameworkError: Error {
    case wrongParameter
}

final class u2fFramework {
    
    func register(_ challengeParameter: [UInt8], _ applicationParameter: [UInt8]) throws -> (publicKey: Data, keyHandle: Data, attestationCertificate: Data, signature: Data) {
        
        guard challengeParameter.count == 32,
            applicationParameter.count == 32
        else { throw U2FFrameworkError.wrongParameter }
        
        let _ = APDU(INS: .register, P1: .registerHashID, DATA: challengeParameter + applicationParameter).getData()
        
        return (Data(), Data(), Data(), Data()) //Заглушка
    }
    
    func authenticate(_ challengeParameter: [UInt8], _ applicationParameter: [UInt8], keyHandle: [UInt8]) throws -> (userPresence: UInt8, counter: UInt32, signature: Data) {
        
        guard challengeParameter.count == 32,
            applicationParameter.count == 32
        else { throw U2FFrameworkError.wrongParameter }
        
        let _ = APDU(INS: .authenticate, P1: .authEnforce, DATA: challengeParameter + applicationParameter + [UInt8(keyHandle.count)] + keyHandle)
        
        return (0,0,Data()) //Заглушка
    }
}
