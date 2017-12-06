//
//  GATTClientTest.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 12/02/17.
//  Copyright © 2017 PureSwift. All rights reserved.
//

import BluetoothLinux
import Foundation
import Bluetooth

func GATTClientTest(adapter: Adapter, address: Address) {
    
    do {
        
        let clientSocket = try L2CAPSocket.lowEnergyClient(adapterAddress: adapter.address ?? .any,
                                                           destination: (address, .lowEnergyPublic))
        
        print("Created L2CAP client socket, connected to \(address)")
        
        let client = GATTClient(socket: clientSocket)
        
        client.log = { print("[\(address)]: " + $0) }
        
        // queue operations
        
        var testChecklist = GATTClientTests()
        
        let characteristicUUIDs = TestProfile.TestService.characteristics.map { $0.uuid }
        
        client.discoverAllPrimaryServices {
            print("discoverAllPrimaryServices")
            dump($0)
            guard case let .value(value) = $0 else { return }
            
            testChecklist.discoverAllPrimaryServices = value.contains { $0.uuid == TestProfile.TestService.uuid }
        }
        
        client.discoverPrimaryServices(by: TestProfile.TestService.uuid) {
            print("discoverAllPrimaryServicesByUUID")
            dump($0)
            guard case let .value(value) = $0 else { return }
            
            testChecklist.discoverPrimaryServicesByUUID = value.count == 1
                && value.contains { $0.uuid == TestProfile.TestService.uuid }
            
            if let service = value.first {
                
                client.discoverAllCharacteristics(of: service) {
                    print("discoverAllCharacteristics")
                    dump($0)
                    guard case let .value(value) = $0 else { return }
                    
                    let uuids = value.map { $0.uuid }
                    
                    testChecklist.discoverAllCharacteristics = Set(uuids) == Set(characteristicUUIDs)
                }
            }
        }
        
        let start = Date()
        
        func didFinish() -> Bool {
            
            return (Date() >= (start + 30))
                && testChecklist.discoverAllPrimaryServices
                && testChecklist.discoverPrimaryServicesByUUID
                && testChecklist.discoverAllCharacteristics
        }
        
        // execute IO
        while didFinish() == false {
            
            var pendingWrite = true
            
            while pendingWrite {
                
                pendingWrite = try client.write()
            }
            
            try client.read()
        }
    }
    
    catch { Error("Error: \(error)") }
}

public struct TestProfile {
    
    public static let services = [TestProfile.TestService]
    
    public static let TestService = Service(uuid: BluetoothUUID(rawValue: "60F14FE2-F972-11E5-B84F-23E070D5A8C7")!, primary: true, characteristics: [TestProfile.Read, TestProfile.ReadBlob, TestProfile.Write, TestProfile.WriteBlob])
    
    public static let Read = Characteristic(uuid: BluetoothUUID(rawValue: "E77D264C-F96F-11E5-80E0-23E070D5A8C7")!, value: "Test Read-Only".toUTF8Data(), permissions: [.read], properties: [.read])
    
    public static let ReadBlob = Characteristic(uuid: BluetoothUUID(rawValue: "0615FF6C-0E37-11E6-9E58-75D7DC50F6B1")!, value: Data(bytes: [UInt8](repeating: UInt8.max, count: 512)), permissions: [.read], properties: [.read])
    
    public static let Write = Characteristic(uuid: BluetoothUUID(rawValue: "37BBD7D0-F96F-11E5-8EC1-23E070D5A8C7")!, value: Data(), permissions: [.write], properties: [.write])
    
    public static let WriteValue = "Test Write".toUTF8Data()
    
    public static let WriteBlob = Characteristic(uuid: BluetoothUUID(rawValue: "2FDDB448-F96F-11E5-A891-23E070D5A8C7")!, value: Data(), permissions: [.write], properties: [.write])
    
    public static let WriteBlobValue = Data(bytes: [UInt8](repeating: 1, count: 512))
}

public typealias Service = GATT.Service
public typealias Characteristic = GATT.Characteristic

internal struct GATTClientTests {
    
    var discoverAllPrimaryServices = false
    var discoverPrimaryServicesByUUID = false
    var discoverAllCharacteristics = false
}
