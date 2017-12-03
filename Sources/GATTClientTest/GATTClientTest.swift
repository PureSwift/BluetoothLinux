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
                                                           destination: (address, .LowEnergyPublic))
        
        print("Created L2CAP client socket, connected to \(address)")
        
        let client = GATTClient(socket: clientSocket)
        
        client.log = { print("[\(address)]: " + $0) }
        
        // queue operations
        
        client.discoverAllPrimaryServices()
        
        func didFinish() -> Bool {
            
            return false
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
    
    public static let TestService = Service(UUID: .bit128(UUID(rawValue: "60F14FE2-F972-11E5-B84F-23E070D5A8C7")!), primary: true, characteristics: [TestProfile.Read, TestProfile.ReadBlob, TestProfile.Write, TestProfile.WriteBlob])
    
    public static let Read = Characteristic(UUID: .bit128(UUID(rawValue: "E77D264C-F96F-11E5-80E0-23E070D5A8C7")!), value: "Test Read-Only".toUTF8Data(), permissions: [.Read], properties: [.Read])
    
    public static let ReadBlob = Characteristic(UUID: .bit128(UUID(rawValue: "0615FF6C-0E37-11E6-9E58-75D7DC50F6B1")!), value: Data(bytes: [UInt8](repeating: UInt8.max, count: 512)), permissions: [.Read], properties: [.Read])
    
    public static let Write = Characteristic(UUID: .bit128(UUID(rawValue: "37BBD7D0-F96F-11E5-8EC1-23E070D5A8C7")!), value: Data(), permissions: [.Write], properties: [.Write])
    
    public static let WriteValue = "Test Write".toUTF8Data()
    
    public static let WriteBlob = Characteristic(UUID: .bit128(UUID(rawValue: "2FDDB448-F96F-11E5-A891-23E070D5A8C7")!), value: Data(), permissions: [.Write], properties: [.Write])
    
    public static let WriteBlobValue = Data(bytes: [UInt8](repeating: 1, count: 512))
}

public typealias Service = GATT.Service
public typealias Characteristic = GATT.Characteristic
