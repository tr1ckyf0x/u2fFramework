//
//  DeviceManager.swift
//  u2fFramework
//
//  Created by Владислав Лисянский on 04/03/2017.
//  Copyright © 2017 Владислав Лисянский. All rights reserved.
//

import Foundation
import CoreBluetooth

enum DeviceManagerState: String {
  case notBound
  case binding
  case bound
}

protocol DeviceManagerDelegate {
  func deviceManagerDidUpdateState(_ deviceManager: DeviceManager)
  func deviceManager(_ deviceManager: DeviceManager, didSendDebugMessage debugMessage: String)
  func deviceManager(_ deviceManager: DeviceManager, didReceiveAPDU apdu: Data)
}

final class DeviceManager: NSObject {
  
  //static let deviceServiceUUID = "0000FFFD-0000-1000-8000-00805F9B34FB"
  static let deviceServiceUUID = "FDFF"
  static let writeCharacteristicUUID = "F1D0FFF1-DEAA-ECEE-B42F-C9BA7ED623BB"
  static let notifyCharacteristicUUID = "F1D0FFF2-DEAA-ECEE-B42F-C9BA7ED623BB"
  static let controlpointLengthCharacteristicUUID = "F1D0FFF3-DEAA-ECEE-B42F-C9BA7ED623BB"
  
  let peripheral: CBPeripheral
  var deviceName: String? { return peripheral.name }
  var delegate: DeviceManagerDelegate?
    
  fileprivate var chunksize = 0
  fileprivate var pendingChunks = [Data]()
  fileprivate var writeCharacteristic: CBCharacteristic?
  fileprivate var notifyCharacteristic: CBCharacteristic?
  fileprivate var controlpointLengthCharacteristic: CBCharacteristic?
  fileprivate(set) var state = DeviceManagerState.notBound {
    didSet { delegate?.deviceManagerDidUpdateState(self) }
  }
  
  init(peripheral: CBPeripheral) {
    self.peripheral = peripheral
    super.init()
    self.peripheral.delegate = self
  }
  
  func bind() {
    guard state == .notBound else {
      delegate?.deviceManager(self, didSendDebugMessage: "Trying to bind but alreay busy")
      return
    }
    
    delegate?.deviceManager(self, didSendDebugMessage: "Discovering services...")
    state = .binding
    let serviceUUID = CBUUID(string: type(of: self).deviceServiceUUID)
    peripheral.discoverServices([serviceUUID])
  }
    
  func exchangeAPDU(data: Data) {
    guard state == .bound else {
      delegate?.deviceManager(self, didSendDebugMessage: "Trying to send APDU \(data) but not bound yet")
      return
    }
    
    delegate?.deviceManager(self, didSendDebugMessage: "Trying to split APDU into chunks...")
    guard let chunks = TransportHelper.split(data: data, command: .message, chunkSize: chunksize), chunks.count > 0 else {
      delegate?.deviceManager(self, didSendDebugMessage: "Unable to split APDU into chunks")
      resetState()
      return
    }
    
    delegate?.deviceManager(self, didSendDebugMessage: "Successfully split APDU into \(chunks.count) part(s)")
    pendingChunks = chunks
    writeNextPendingChunk()
  }
    
  fileprivate func writeNextPendingChunk() {
    guard pendingChunks.count > 0 else {
      delegate?.deviceManager(self, didSendDebugMessage: "Trying to write pending chunk but nothing left to write")
      return
    }
    
    let chunk = pendingChunks.removeFirst()
    delegate?.deviceManager(self, didSendDebugMessage: "Writing pending chunk = \(chunk)")
    peripheral.writeValue(chunk, for: writeCharacteristic!, type: .withResponse)
  }
    
  fileprivate func handleReceivedChunk(chunk: Data) {
    switch TransportHelper.getChunkType(data: chunk) {
    case .continuation:
      delegate?.deviceManager(self, didSendDebugMessage: "Received CONTINUATION chunk")
    case .message:
      delegate?.deviceManager(self, didSendDebugMessage: "Received MESSAGE chunk")
    case .error:
      delegate?.deviceManager(self, didSendDebugMessage: "Received ERROR chunk")
    case .keepAlive:
      delegate?.deviceManager(self, didSendDebugMessage: "Received KEEPALIVE chunk")
    default:
      delegate?.deviceManager(self, didSendDebugMessage: "Received UNKNOWN chunk")
    }
    
    pendingChunks.append(chunk)
    guard let APDU = TransportHelper.join(chunks: pendingChunks, command: .message) else { return }
    delegate?.deviceManager(self, didSendDebugMessage: "Successfully joined APDU = \(APDU)")
    pendingChunks.removeAll()
    delegate?.deviceManager(self, didReceiveAPDU: APDU)
  }
  
  fileprivate func resetState() {
    writeCharacteristic = nil
    notifyCharacteristic = nil
    controlpointLengthCharacteristic = nil
    chunksize = 0
    state = .notBound
  }
}

extension DeviceManager: CBPeripheralDelegate {
  
  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    guard state == .binding else { return }
    guard let services = peripheral.services, services.count > 0,
      let service = services.first else {
        delegate?.deviceManager(self, didSendDebugMessage: "Unable to discover services")
        resetState()
        return
    }
    
    delegate?.deviceManager(self, didSendDebugMessage: "Successfully discovered services")
    let writeCharacteristicUUID = CBUUID(string: type(of: self).writeCharacteristicUUID)
    let notifyCharacteristicUUID = CBUUID(string: type(of: self).notifyCharacteristicUUID)
    let controlpointLengthCharacteristicUUID = CBUUID(string: type(of: self).controlpointLengthCharacteristicUUID)
    peripheral.discoverCharacteristics([writeCharacteristicUUID, notifyCharacteristicUUID, controlpointLengthCharacteristicUUID], for: service)
  }
  
  func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
    guard state == .binding else { return }
    guard
      let characteristics = service.characteristics, characteristics.count >= 3,
      let writeCharacteristic = characteristics.filter({ $0.uuid.uuidString == type(of: self).writeCharacteristicUUID }).first,
      let notifyCharacteristic = characteristics.filter({ $0.uuid.uuidString == type(of: self).notifyCharacteristicUUID }).first,
      let controlpointLengthCharacteristic = characteristics.filter({ $0.uuid.uuidString == type(of: self).controlpointLengthCharacteristicUUID }).first
      else {
        delegate?.deviceManager(self, didSendDebugMessage: "Unable to discover characteristics")
        resetState()
        return
    }
    
    self.writeCharacteristic = writeCharacteristic
    self.notifyCharacteristic = notifyCharacteristic
    self.controlpointLengthCharacteristic = controlpointLengthCharacteristic
    
    delegate?.deviceManager(self, didSendDebugMessage: "Enabling notifications...")
    peripheral.setNotifyValue(true, for: notifyCharacteristic)
  }
  
  func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
    guard state == .binding else { return }
    guard characteristic == notifyCharacteristic, characteristic.isNotifying, error == nil else {
      delegate?.deviceManager(self, didSendDebugMessage: "Unable to enable notifications, error = \(error)")
      resetState()
      return
    }
    
    delegate?.deviceManager(self, didSendDebugMessage: "Successfully enabled notifications")
    delegate?.deviceManager(self, didSendDebugMessage: "Reading chunksize...")
    peripheral.readValue(for: self.controlpointLengthCharacteristic!)
  }
  
  func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
    guard state == .bound || state == .binding else { return }
    guard characteristic == notifyCharacteristic || characteristic == controlpointLengthCharacteristic, error == nil,
      let data = characteristic.value
      else {
        delegate?.deviceManager(self, didSendDebugMessage: "Unable to read data, error = \(error), data = \(characteristic.value)")
        resetState()
        return
    }
    
    delegate?.deviceManager(self, didSendDebugMessage: "Received data of size \(data.count) = \(data.hexEncodedString())")
    
    if characteristic == controlpointLengthCharacteristic {
      let reader = DataReader(data: data)
      guard let chunksize = reader.readNextBigEndianUInt16() else {
        delegate?.deviceManager(self, didSendDebugMessage: "Unable to read chunksize")
        resetState()
        return
      }
      
      delegate?.deviceManager(self, didSendDebugMessage: "Successfully read chuncksize = \(chunksize)")
      self.chunksize = Int(chunksize)
      state = .bound
    }
    else if characteristic == notifyCharacteristic {
      handleReceivedChunk(chunk: data)
    }
    else {
      delegate?.deviceManager(self, didSendDebugMessage: "Received data from unknown characteristic, ignoring")
    }
  }
  
  func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
    guard state == .bound else { return }
    guard characteristic == writeCharacteristic, error == nil else {
      delegate?.deviceManager(self, didSendDebugMessage: "Unable to write data, error = \(error)")
      resetState()
      return
    }
    writeNextPendingChunk()
  }
}
