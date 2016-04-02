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

func GATTServerTest(adapter: Adapter) {
    
    let database = generateDB()
    
    print("GATT Database:")
    
    for attribute in database.attributes {
        
        let typeText: String
        
        if let gatt = GATT.UUID(UUID: attribute.UUID) {
            
            typeText = "\(gatt)"
            
        } else {
            
            typeText = "\(attribute.UUID)"
        }
        
        print("\(attribute.handle) - \(typeText)")
        print("Permissions: \(attribute.permissions)")
        print("Value: \(attribute.value)")
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
    
    let uuid = { Bluetooth.UUID.Bit128(SwiftFoundation.UUID()) }
    
    var services: [GATTDatabase.Service] = []
    
    do {
        
        let characteristic = GATTDatabase.Characteristic(UUID: uuid(), value: "Hey".toUTF8Data().byteValue, permissions: [.Read, .Write], properties: [.Read, .Write])
        
        let characteristic2 = GATTDatabase.Characteristic(UUID: uuid(), value: "Hola".toUTF8Data().byteValue, permissions: [.Read, .Write], properties: [.Read, .Write])
        
        let service = GATTDatabase.Service(characteristics: [characteristic, characteristic2], UUID: uuid())
        
        services.append(service)
    }
    
    do {
        
        let characteristic = GATTDatabase.Characteristic(UUID: uuid(), value: "Bye".toUTF8Data().byteValue, permissions: [.Read, .Write], properties: [.Read, .Write])
        
        let characteristic2 = GATTDatabase.Characteristic(UUID: uuid(), value: "Chau".toUTF8Data().byteValue, permissions: [.Read, .Write], properties: [.Read, .Write])
        
        let service = GATTDatabase.Service(characteristics: [characteristic, characteristic2], UUID: uuid())
        
        services.append(service)
    }
    
    do {
        
        let characteristic = GATTDatabase.Characteristic(UUID: uuid(), value: "Read Only".toUTF8Data().byteValue, permissions: [.Read], properties: [.Read])
        
        let characteristic2 = GATTDatabase.Characteristic(UUID: uuid(), value: "Write Only".toUTF8Data().byteValue, permissions: [.Write], properties: [.Write])
        
        let service = GATTDatabase.Service(characteristics: [characteristic, characteristic2], UUID: uuid())
        
        services.append(service)
    }
    
    return GATTDatabase(services: services)
}
