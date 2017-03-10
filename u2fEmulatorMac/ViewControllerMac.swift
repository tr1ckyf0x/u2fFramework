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

  @IBOutlet weak var textView: NSScrollView!
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  @IBAction func startAdvertisment(_ sender: Any) {
    u2fEmulator = U2FEmulator(delegate: self)
  }
  
  @IBAction func reset(_ sender: Any) {
    u2fEmulator = nil
  }
  
}

extension ViewControllerMac: U2FEmulatorDelegate {
  func u2fEmulator(_ u2fEmulator: U2FEmulator, didSendDebugMessage debugMessage: String) {
    textView.documentView?.insertText(" - \(debugMessage)\n")
    print(debugMessage)
  }
}
