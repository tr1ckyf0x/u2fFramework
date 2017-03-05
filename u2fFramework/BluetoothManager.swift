//
//  BluetoothManager.swift
//  u2fFramework
//
//  Created by Владислав Лисянский on 04/03/2017.
//  Copyright © 2017 Владислав Лисянский. All rights reserved.
//

import Foundation
import CoreBluetooth

enum BluetoothManagerState: String {
  case scanning
  case connecting
  case connected
  case disconnecting
  case disconnected
}

protocol BluetoothManagerDelegate {
  func bluetoothManagerDidUpdateState(_ bluetoothManager: BluetoothManager)
  func bluetoothManager(_ deviceManager: BluetoothManager, didSendDebugMessage debugMessage: String)
  func bluetoothManager(_ deviceManager: BluetoothManager, didReceiveAPDU apdu: Data)
}

final class BluetoothManager: NSObject {
  fileprivate var centralManager: CBCentralManager?
  fileprivate var deviceManager: DeviceManager?
  fileprivate(set) var state = BluetoothManagerState.disconnected {
    didSet {
      delegate?.bluetoothManagerDidUpdateState(self)
      delegate?.bluetoothManager(self, didSendDebugMessage: "New state: \(state.rawValue)")
    }
  }
  var delegate: BluetoothManagerDelegate?
  var deviceName: String? { return deviceManager?.deviceName }
  
  func scanForDevice() {
    guard centralManager == nil else { return }
    centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: NSNumber(value: true)])
    state = .scanning
  }
  
  func stopSession() {
    guard let centralManager = centralManager else { return }
    
    switch state {
    case .scanning:
      centralManager.stopScan()
      self.centralManager = nil
      state = .disconnected
    case .connecting, .connected:
      guard let device = deviceManager?.peripheral else { break }
      centralManager.cancelPeripheralConnection(device)
      state = .disconnecting
    default: break
    }
  }
  
  func exchangeAPDU(data: Data) {
    guard state == .connected else { return }
    delegate?.bluetoothManager(self, didSendDebugMessage: "Exchanging APDU = \(data)")
    deviceManager?.exchangeAPDU(data: data)
  }
    
  fileprivate func resetState() {
    deviceManager = nil
    centralManager = nil
    state = .disconnected
  }
  
}

extension BluetoothManager: DeviceManagerDelegate {
  
  func deviceManagerDidUpdateState(_ deviceManager: DeviceManager) {
    switch deviceManager.state {
    case .bound:
      delegate?.bluetoothManager(self, didSendDebugMessage: "Successfully connected device \(deviceManager.peripheral.identifier.uuidString)")
      state = .connected
    case .binding:
      delegate?.bluetoothManager(self, didSendDebugMessage: "Binding to device \(deviceManager.peripheral.identifier.uuidString)...")
    case .notBound:
      delegate?.bluetoothManager(self, didSendDebugMessage: "Something when wrong with device \(deviceManager.peripheral.identifier.uuidString)")
      stopSession()
    }
  }
  
  func deviceManager(_ deviceManager: DeviceManager, didReceiveAPDU apdu: Data) {
    delegate?.bluetoothManager(self, didReceiveAPDU: apdu)
  }
  
  func deviceManager(_ deviceManager: DeviceManager, didSendDebugMessage debugMessage: String) {
    delegate?.bluetoothManager(self, didSendDebugMessage: debugMessage)
  }
  
}

extension BluetoothManager: CBCentralManagerDelegate {
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    if central.state == .poweredOn && state == .scanning {
      delegate?.bluetoothManager(self, didSendDebugMessage: "Bluetooth stack is ready, scanning devices...")
      let serviceUUID = CBUUID(string: DeviceManager.deviceServiceUUID)
      central.scanForPeripherals(withServices: [serviceUUID], options: nil)
    }
  }
  
  func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
    guard state == .scanning else { return }
    guard let connectable = advertisementData[CBAdvertisementDataIsConnectable] as? NSNumber, connectable.boolValue else { return }
    
    delegate?.bluetoothManager(self, didSendDebugMessage: "Found connectable device \"\(peripheral.name)\", connecting \(peripheral.identifier.uuidString)...")
    deviceManager = DeviceManager(peripheral: peripheral)
    deviceManager?.delegate = self
    central.stopScan()
    central.connect(peripheral, options: nil)
    state = .connecting
  }
  
  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    guard state == .connecting, let deviceManager = deviceManager else { return }
    deviceManager.bind()
  }
  
  func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
    guard state == .connecting, let _ = deviceManager else { return }
    delegate?.bluetoothManager(self, didSendDebugMessage: "Failed to connect device \(peripheral.identifier.uuidString), error: \(error?.localizedDescription)")
    resetState()
  }
  
  func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
    switch state {
    case .connecting, .connected, . disconnecting:
      guard let _ = deviceManager else { return }
      delegate?.bluetoothManager(self, didSendDebugMessage: "Disconnected device \(peripheral.identifier.uuidString), error: \(error?.localizedDescription)")
      resetState()
    default: return
    }
  }
}
