//
//  Extensions.swift
//  u2fFramework
//
//  Created by Владислав Лисянский on 09/03/2017.
//  Copyright © 2017 Владислав Лисянский. All rights reserved.
//

import Foundation

extension Data {
  func hexEncodedString() -> String {
    return map { String(format: "%02hhx", $0) }.joined()
  }
}
