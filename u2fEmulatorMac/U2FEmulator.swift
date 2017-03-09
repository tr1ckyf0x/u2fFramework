//
//  U2FEmulator.swift
//  u2fFramework
//
//  Created by Владислав Лисянский on 09/03/2017.
//  Copyright © 2017 Владислав Лисянский. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol U2FEmulatorDelegate {
  func u2fEmulator(_ u2fEmulator: U2FEmulator, didSendDebugMessage debugMessage: String)
}

final class U2FEmulator: NSObject {
  
  let deviceName = "U2F Key"
  let u2fServiceUUID = CBUUID(string: "FDFF")
  let controlPointUUID = CBUUID(string: "F1D0FFF1-DEAA-ECEE-B42F-C9BA7ED623BB")
  let statusUUID = CBUUID(string: "F1D0FFF2-DEAA-ECEE-B42F-C9BA7ED623BB")
  let controlPointLengthUUID = CBUUID(string: "F1D0FFF3-DEAA-ECEE-B42F-C9BA7ED623BB")
  
  var peripheralManager: CBPeripheralManager?
  var u2fService: CBMutableService?
  var controlPointCharacteristic: CBMutableCharacteristic?
  var statusCharacteristic: CBMutableCharacteristic?
  var controlPointLengthCharacteristic: CBMutableCharacteristic?
  var central: CBCentral?
  
  var delegate: U2FEmulatorDelegate?
  
  init(delegate: U2FEmulatorDelegate?) {
    super.init()
    self.delegate = delegate
    delegate?.u2fEmulator(self, didSendDebugMessage: "U2F Emulator Initialized")
    delegate?.u2fEmulator(self, didSendDebugMessage: "Initializing peipheral manager")
    peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
  }
  
}

extension U2FEmulator: CBPeripheralManagerDelegate {
  
  func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
    guard peripheral.state == .poweredOn else { return }
    delegate?.u2fEmulator(self, didSendDebugMessage: "Peripheral Manager Initialized")
    delegate?.u2fEmulator(self, didSendDebugMessage: "Initializing characteristics")
    
    controlPointCharacteristic = CBMutableCharacteristic(type: controlPointUUID, properties: [.write], value: nil, permissions: [.writeable])
    statusCharacteristic = CBMutableCharacteristic(type: statusUUID, properties: [.notify], value: nil, permissions: [])
    controlPointLengthCharacteristic = CBMutableCharacteristic(type: controlPointLengthUUID, properties: .read, value: Data(bytes: [0x00, 0x14]), permissions: [.readable])
    u2fService = CBMutableService(type: u2fServiceUUID, primary: true)
    guard
      let _ = controlPointCharacteristic,
      let _ = statusCharacteristic,
      let _ = controlPointLengthCharacteristic,
      let _ = u2fService
      else { return }
    delegate?.u2fEmulator(self, didSendDebugMessage: "Characteristics initialized")
    delegate?.u2fEmulator(self, didSendDebugMessage: "Adding service")
    u2fService?.characteristics = [controlPointCharacteristic!, statusCharacteristic!, controlPointLengthCharacteristic!]
    peripheralManager?.add(u2fService!)
  }
  
  func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
    if let err = error {
      delegate?.u2fEmulator(self, didSendDebugMessage: "\(err)")
    }
    
    guard service == u2fService else { return }
    delegate?.u2fEmulator(self, didSendDebugMessage: "Service was added")
    delegate?.u2fEmulator(self, didSendDebugMessage: "Starting advertising")
    peripheralManager?.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [service.uuid], CBAdvertisementDataLocalNameKey: (deviceName as NSString)])
    
  }
  
  func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
    if let err = error {
      delegate?.u2fEmulator(self, didSendDebugMessage: "\(err)")
      return
    }
    delegate?.u2fEmulator(self, didSendDebugMessage: "Advertising started")
  }
  
  func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
    print(#function)
  }
  
  func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
    delegate?.u2fEmulator(self, didSendDebugMessage: "Central \(central.identifier.uuidString) subscribed to characteristic \(characteristic.uuid.uuidString)")
    self.central = central
  }
  
  func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
    print(#function)
    peripheral.respond(to: request, withResult: .success)
  }
  
  func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
    guard let request = requests.first,
      let value = request.value,
      request.characteristic == controlPointCharacteristic
      else { return }
    
    delegate?.u2fEmulator(self, didSendDebugMessage: "Received value: \(value.hexEncodedString())")
    peripheral.respond(to: requests.first!, withResult: .success)
  }
  
  func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
    delegate?.u2fEmulator(self, didSendDebugMessage: "Central \(central.identifier.uuidString) unsubscribed from characteristic \(characteristic.uuid.uuidString)")
  }
  
}
