//
//  GATTServerTest.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 3/13/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

#if os(Linux)
    import BluetoothLinux
    import Glibc
#elseif os(OSX) || os(iOS)
    import Darwin.C
#endif

import SwiftFoundation
import Bluetooth

func GATTServerTest(adapter: Adapter) {
    
    let database = generateDB()
    
    print("GATT Database:")
    
    for attribute in database.attributes {
        
        let type: Any = GATT.UUID.init(UUID: attribute.UUID as BluetoothUUID) ?? attribute.UUID
        
        let value: Any = BluetoothUUID(littleEndian: attribute.value.bytes) ?? String(UTF8Data: attribute.value) ?? attribute.value
        
        print("\(attribute.handle) - \(type)")
        print("Permissions: \(attribute.permissions)")
        print("Value: \(value)")
    }
    
    do {
        
        let address = adapter.address!
        
        let serverSocket = try L2CAPSocket(adapterAddress: address, channelIdentifier: ATT.CID, addressType: .LowEnergyPublic, securityLevel: .Low)
        
        print("Created L2CAP server")
        
        let newSocket = try serverSocket.waitForConnection()
        
        print("New \(newSocket.addressType) connection from \(newSocket.address)")
        
        let server = GATTServer(socket: newSocket)
        
        server.log = { print("[\(newSocket.address)]: " + $0) }
        
        server.database = database
        
        while true {
            
            var pendingWrite = true
            
            while pendingWrite {
                
                pendingWrite = try server.write()
            }
            
            try server.read()
        }
    }
        
    catch { Error("Error: \(error)") }
}

private func generateDB() -> GATTDatabase {
    
    var database = GATTDatabase()
    
    for service in TestProfile.services {
        
        let _ = database.add(service: service)
    }
    
    return database
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

