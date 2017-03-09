//
//  ViewController.swift
//  u2fFrameworkDemo
//
//  Created by Владислав Лисянский on 06/03/2017.
//  Copyright © 2017 Владислав Лисянский. All rights reserved.
//

import UIKit
import u2fFramework

class ViewController: UIViewController {
  
  @IBOutlet weak var textView: UITextView!
  
  let challengeParameter = "4142D21C00D94FFB9D504ADA8F99B721F4B191AE4E37CA0140F696B6983CFACB".hexToUInt8Array()!
  let applicationParameter = "F0E6A6A97042A4F1F1C87F5F7D44315B2D852C2DF5C7991CC66241BF7072D1C4".hexToUInt8Array()!
  var keyHandle: [UInt8]?
  
  
  private lazy var bluetoothManager: BluetoothManager = {
    let manager = BluetoothManager()
    manager.delegate = self
    return manager
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
  }
  
  @IBAction func connectButton(_ sender: Any) {
    bluetoothManager.scanForDevice()
  }
  
  @IBAction func registerButton(_ sender: Any) {
    let registerAPDU = APDU(challengeParameter: challengeParameter, applicationParameter: applicationParameter)
    bluetoothManager.exchangeAPDU(data: registerAPDU.getData())
  }
  
  @IBAction func authenticateButton(_ sender: Any) {
    guard let handle = keyHandle else { return }
    let authenticateAPDU = APDU(challengeParameter: challengeParameter, applicationParameter: applicationParameter, keyHandle: handle)
    bluetoothManager.exchangeAPDU(data: authenticateAPDU.getData())
  }

}

extension ViewController: BluetoothManagerDelegate {
  
  func bluetoothManagerDidUpdateState(_ bluetoothManager: BluetoothManager) {
    print(bluetoothManager.state)
  }
  
  func bluetoothManager(_ deviceManager: BluetoothManager, didReceiveAPDU apdu: Data) {
    print(#function)
  }
  
  func bluetoothManager(_ deviceManager: BluetoothManager, didSendDebugMessage debugMessage: String) {
    print(debugMessage)
    textView.text = textView.text + "- \(debugMessage)\n"
    let range = NSMakeRange(textView.text.characters.count - 1, 1)
    UIView.setAnimationsEnabled(false)
    textView.scrollRangeToVisible(range)
    UIView.setAnimationsEnabled(true)
  }
  
}

