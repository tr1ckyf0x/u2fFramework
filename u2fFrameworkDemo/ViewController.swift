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
  @IBOutlet weak var imageView: UIImageView!
  
  let challengeParameter = "4142D21C00D94FFB9D504ADA8F99B721F4B191AE4E37CA0140F696B6983CFACB".hexToUInt8Array()!
  let applicationParameter = "F0E6A6A97042A4F1F1C87F5F7D44315B2D852C2DF5C7991CC66241BF7072D1C4".hexToUInt8Array()!
  var keyHandle: [UInt8]?
  var publicKey: Data?
  
  
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
    guard bluetoothManager.state == .connected else {
      imageView.image = UIImage(named: "failure.png")
      Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(ViewController.purgeImage), userInfo: nil, repeats: false)
      return
    }
    let registerAPDU = APDU(challengeParameter: challengeParameter, applicationParameter: applicationParameter)
    bluetoothManager.exchangeAPDU(data: registerAPDU.getData())
  }
  
  @IBAction func authenticateButton(_ sender: Any) {
    guard let handle = keyHandle,
    bluetoothManager.state == .connected else {
      imageView.image = UIImage(named: "failure.png")
      Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(ViewController.purgeImage), userInfo: nil, repeats: false)
      return
    }
    let authenticateAPDU = APDU(challengeParameter: challengeParameter, applicationParameter: applicationParameter, keyHandle: handle)
    bluetoothManager.exchangeAPDU(data: authenticateAPDU.getData())
  }
  
  func appendLogMessage(_ message: String) {
    print(message)
    textView.text = textView.text + "- \(message)\n"
    let range = NSMakeRange(textView.text.characters.count - 1, 1)
    UIView.setAnimationsEnabled(false)
    textView.scrollRangeToVisible(range)
    UIView.setAnimationsEnabled(true)
  }
  
  func purgeImage() {
    imageView.image = nil
  }

}

extension ViewController: BluetoothManagerDelegate {
  
  func bluetoothManagerDidUpdateState(_ bluetoothManager: BluetoothManager) {
    print(bluetoothManager.state)
  }
  
  func bluetoothManager(_ deviceManager: BluetoothManager, didReceiveAPDU apdu: Data) {
    do {
      let registerResponse = try APDU.parseRegistrationResponse(apdu)
      appendLogMessage("Successfully parsed registration response")
      appendLogMessage("Certificate = \(registerResponse.attestationCertificate.hexEncodedString())")
      appendLogMessage("KeyHandle = \(registerResponse.keyHandle.hexEncodedString())")
      appendLogMessage("PublicKey = \(registerResponse.publicKey.hexEncodedString())")
      appendLogMessage("Signature = \(registerResponse.signature.hexEncodedString())")
      keyHandle = Array(registerResponse.keyHandle)
      publicKey = registerResponse.publicKey
      if CryptoHelper.verifyRegisterSignature(certificate: registerResponse.attestationCertificate, signature: registerResponse.signature, keyHandle: registerResponse.keyHandle, publicKey: registerResponse.publicKey, applicationParameter: Data(bytes: applicationParameter), challenge: Data(bytes: challengeParameter)) {
        appendLogMessage("-------- SUCCESSFULL REGISTRATION --------")
        imageView.image = UIImage(named: "success.png")
      }
      else { imageView.image = UIImage(named: "failure.png") }
      Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(ViewController.purgeImage), userInfo: nil, repeats: false)
    }
    catch {
      do {
        let authenticationResponse = try APDU.parseAuthenticationResponse(apdu)
        appendLogMessage("Successfully parsed authentication response")
        appendLogMessage("Counter = \(authenticationResponse.counter)")
        appendLogMessage("UserPresence = \(authenticationResponse.userPresence)")
        appendLogMessage("Signature = \(authenticationResponse.signature.hexEncodedString())")
        if CryptoHelper.verifyAuthenticateSignature(publicKey: publicKey!, userPresenceFlag: authenticationResponse.userPresence, counter: authenticationResponse.counter, signature: authenticationResponse.signature, applicationParameter: Data(bytes: applicationParameter), challenge: Data(bytes: challengeParameter)) {
          appendLogMessage("-------- SUCCESSFULL AUTHENTICATION --------")
          imageView.image = UIImage(named: "success.png")
        }
        else { imageView.image = UIImage(named: "failure.png") }
        Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(ViewController.purgeImage), userInfo: nil, repeats: false)
      } catch {
        appendLogMessage("Parse error occured")
        imageView.image = UIImage(named: "failure.png")
        Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(ViewController.purgeImage), userInfo: nil, repeats: false)
      }
    }
  }
  
  func bluetoothManager(_ deviceManager: BluetoothManager, didSendDebugMessage debugMessage: String) {
    appendLogMessage(debugMessage)
  }
  
}

