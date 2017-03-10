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
  
  var chunks = [Data]()
  
  init(delegate: U2FEmulatorDelegate?) {
    super.init()
    self.delegate = delegate
    delegate?.u2fEmulator(self, didSendDebugMessage: "U2F Emulator Initialized")
    delegate?.u2fEmulator(self, didSendDebugMessage: "Initializing peipheral manager")
    peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
  }
  
  deinit {
    delegate?.u2fEmulator(self, didSendDebugMessage: "Advertisment stopped")
    peripheralManager?.stopAdvertising()
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
    while writeNextPendingChunk() {}
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
    
    chunks.append(value)
    peripheral.respond(to: request, withResult: .success)
    if let response = TransportHelper.join(chunks: chunks, command: .message) {
      delegate?.u2fEmulator(self, didSendDebugMessage: "Received response: \(response.hexEncodedString())")
      chunks.removeAll()
      switch response {
      case Data(bytes: "008100000000404142d21c00d94ffb9d504ada8f99b721f4b191ae4e37ca0140f696b6983cfacbf0e6a6a97042a4f1f1c87f5f7d44315b2d852c2df5c7991cc66241bf7072d1c4".hexToUInt8Array()!):
        chunks = TransportHelper.split(data: Data(bytes: "0504843DC11044915A50B198A26ED9A836E1A0405EDF1C040D7FD27B9242D2A89AF4A29DF078A3350EB7B1D74F646664377BDF7EA07989D3A29D25076634237F2CE9404E307D46E7E11077CB3218346CCC56540BE727575D99AA16C3DF933D0AD3852C9EEC6726AA647E64ED4DC96F531249E94877C814174A51CB7C675F72FAC34DE63082013C3081E4A003020102020A47901280001155957352300A06082A8648CE3D0403023017311530130603550403130C476E756262792050696C6F74301E170D3132303831343138323933325A170D3133303831343138323933325A3031312F302D0603550403132650696C6F74476E756262792D302E342E312D34373930313238303030313135353935373335323059301306072A8648CE3D020106082A8648CE3D03010703420004BA4D3F903986F6DD36FA8A9995FF64CC3AAA54C79495757CA0884EC648AD2F89B7283E16037F9532110E671926F9253CD35AE49CD7FA00E190C0533F2E7A02D1300A06082A8648CE3D0403020347003044022060CDB6061E9C22262D1AAC1D96D8C70829B2366531DDA268832CB836BCD30DFA0220631B1459F09E6330055722C8D89B7F48883B9089B88D60D1D9795902B30410DF30440220636F9BCD1463DE6655D1316E4DD3B8E8DE30C846673BCC02F76C2AB84D620149022037FB96E9AF3E9DDECD81C24950538E73D7C6F554BAC29295A49644B39BD910789000".hexToUInt8Array()!), command: .message, chunkSize: 20)!
        while writeNextPendingChunk() { }
        case Data(bytes: "008203000000814142d21c00d94ffb9d504ada8f99b721f4b191ae4e37ca0140f696b6983cfacbf0e6a6a97042a4f1f1c87f5f7d44315b2d852c2df5c7991cc66241bf7072d1c4404e307d46e7e11077cb3218346ccc56540be727575d99aa16c3df933d0ad3852c9eec6726aa647e64ed4dc96f531249e94877c814174a51cb7c675f72fac34de6".hexToUInt8Array()!):
          chunks = TransportHelper.split(data: Data(bytes: "01000000043045022100AC5708327BA162EC71AF28D41C19F13135A02462B05C8EC4B98DF5D7D41BA574022027CC9982028A7D2ADF9863898C34FBEEEACF35699FD8B2569F7AFCCE6C6881EC9000".hexToUInt8Array()!), command: .message, chunkSize: 20)!
          while writeNextPendingChunk() { }
      default: break
      }
    }
  }
  
  func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
    delegate?.u2fEmulator(self, didSendDebugMessage: "Central \(central.identifier.uuidString) unsubscribed from characteristic \(characteristic.uuid.uuidString)")
  }
  
  func writeNextPendingChunk() -> Bool {
    guard chunks.count > 0 else {
      delegate?.u2fEmulator(self, didSendDebugMessage: "Trying to write pending chunk but nothing left to write")
      return false
    }
    let chunk = chunks.removeFirst()
    if !(peripheralManager?.updateValue(chunk, for: statusCharacteristic!, onSubscribedCentrals: nil))! {
      chunks.insert(chunk, at: 0)
      return false
    }
    delegate?.u2fEmulator(self, didSendDebugMessage: "Writing pending chunk = \(chunk.hexEncodedString())")
    return true
  }
  
}
