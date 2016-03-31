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
    
    var database = GATTDatabase()
    
    let serviceUUID = BluetoothUUID.Bit128(UUID())
    
    guard let serviceAttribute = database.insertService(1, UUID: serviceUUID, primary: true, handleCount: 1)
        else { Error("Could not insert service 1: \(serviceUUID)") }
    
    print("Service 1: \(serviceAttribute)")
    
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
            
            try server.connection.read(newSocket)
            
            try server.connection.write(newSocket)
        }
    }
        
    catch { Error("Error: \(error)") }
}