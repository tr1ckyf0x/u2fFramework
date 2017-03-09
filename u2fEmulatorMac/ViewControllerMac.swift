//
//  ViewController.swift
//  u2fEmulatorMac
//
//  Created by Владислав Лисянский on 09/03/2017.
//  Copyright © 2017 Владислав Лисянский. All rights reserved.
//

import Cocoa
import CoreBluetooth

class ViewControllerMac: NSViewController {
  
  var u2fEmulator: U2FEmulator?

  override func viewDidLoad() {
    super.viewDidLoad()
    u2fEmulator = U2FEmulator(delegate: self)
  }
  
}

extension ViewControllerMac: U2FEmulatorDelegate {
  func u2fEmulator(_ u2fEmulator: U2FEmulator, didSendDebugMessage debugMessage: String) {
    print(debugMessage)
  }
}
