//
//  PeripheralTest.swift
//  BlueZ
//
//  Created by Alsey Coleman Miller on 2/28/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

#if os(Linux)
    import BlueZ
    import CBlueZ
    import Glibc
#elseif os(OSX) || os(iOS)
    import Darwin.C
#endif

import SwiftFoundation

func PeripheralTest(adapter: Adapter) {
    
    do {
        
        let ATT_CID: UInt16 = 4
        
        let ATT_PSM: UInt16 = 31
        
        let server = try L2CAPSocket(deviceIdentifier: adapter.identifier, port: ATT_PSM, channelIdentifier: ATT_CID)
        
        print("Created L2CAP server")
        
        while true {
            
            let newConnection = try server.waitForConnection()
            
            print("New \(newConnection.addressType) connection from \(newConnection.address)")
            
            let readData = try newConnection.recieve()
            
            print("Recieved data: \(String(UTF8Data: readData) ?? "<\(readData.byteValue.count) bytes>"))")
        }
    }
    
    catch { Error("Error: \(error)") }
}