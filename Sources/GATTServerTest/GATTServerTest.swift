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
        
        let type: Any = GATT.UUID(UUID: attribute.UUID) ?? attribute.UUID
        
        let value: Any = Bluetooth.UUID(data: attribute.value) ?? String(UTF8Data: attribute.value) ?? attribute.value
        
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
    
    do {
        
        let characteristic = GATTDatabase.Characteristic(value: "Hey".toUTF8Data(), permissions: [.Read, .Write], properties: [.Read, .Write])
        
        let characteristic2 = GATTDatabase.Characteristic(value: "Hola".toUTF8Data(), permissions: [.Read, .Write], properties: [.Read, .Write])
        
        let service = GATTDatabase.Service(characteristics: [characteristic, characteristic2])
        
        database.add(service)
    }
    
    do {
        
        let characteristic = GATTDatabase.Characteristic(value: "Bye".toUTF8Data(), permissions: [.Read, .Write], properties: [.Read, .Write])
        
        let characteristic2 = GATTDatabase.Characteristic(value: "Chau".toUTF8Data(), permissions: [.Read, .Write], properties: [.Read, .Write])
        
        let service = GATTDatabase.Service(characteristics: [characteristic, characteristic2])
        
        database.add(service)
    }
    
    do {
        
        let characteristic = GATTDatabase.Characteristic(value: "Read Only".toUTF8Data(), permissions: [.Read], properties: [.Read])
        
        let characteristic2 = GATTDatabase.Characteristic(value: "Write Only".toUTF8Data(), permissions: [.Write], properties: [.Write])
        
        let service = GATTDatabase.Service(characteristics: [characteristic, characteristic2])
        
        database.add(service)
    }
    
    return database
}
