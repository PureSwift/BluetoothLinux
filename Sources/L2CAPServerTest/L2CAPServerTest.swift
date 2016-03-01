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
        
        let server = try L2CAPSocket(deviceIdentifier: adapter.identifier, channelIdentifier: ATT.CID, addressType: .LowEnergyPublic, securityLevel: .Low)

        print("Created L2CAP server")
        
        let newConnection = try server.waitForConnection()
        
        print("New \(newConnection.addressType) connection from \(newConnection.address)")
        
        let readData = try newConnection.recieve()
        
        print("Recieved data: \(String(UTF8Data: readData) ?? "\(readData.byteValue.map({ String($0, radix: 16, uppercase: false) }))" )")
    }

    catch { Error("Error: \(error)") }
}

