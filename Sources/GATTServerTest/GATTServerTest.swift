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
    
    let characteristic = GATTDatabase.Characteristic(UUID: BluetoothUUID.Bit128(UUID()), value: "Hey".toUTF8Data().byteValue)
    
    let database = GATTDatabase(services: [GATTDatabase.Service(characteristics: [characteristic], UUID: BluetoothUUID.Bit128(UUID()))])
    
    print("GATT Database: \(database)")
    
    do {
        
        let address = adapter.address!
        
        let serverSocket = try L2CAPSocket(adapterAddress: address, channelIdentifier: ATT.CID, addressType: .LowEnergyPublic, securityLevel: .Low)
        
        print("Created L2CAP server")
        
        let newSocket = try serverSocket.waitForConnection()
        
        print("New \(newSocket.addressType) connection from \(newSocket.address)")
        
        let server = GATTServer()
        
        server.log = { print("[\(newSocket.address)]: " + $0) }
        
        server.database = database
        
        while true {
            
            try server.read(newSocket)
            
            try server.write(newSocket)
        }
    }
        
    catch { Error("Error: \(error)") }
}