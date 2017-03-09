//
//  EndianConvertible.swift
//  u2fFramework
//
//  Created by Владислав Лисянский on 18.10.16.
//  Copyright © 2016 Владислав Лисянский. All rights reserved.
//

import Foundation

internal protocol EndianConvertible: Integer {
  var bigEndian: Self { get }
  var littleEndian: Self { get }
  var byteSwapped: Self { get }
}

extension Int16: EndianConvertible {}
extension UInt16: EndianConvertible {}
extension Int32: EndianConvertible {}
extension UInt32: EndianConvertible {}
extension Int64: EndianConvertible {}
extension UInt64: EndianConvertible {}
