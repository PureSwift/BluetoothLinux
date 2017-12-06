//
//  PeripheralTest.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 2/28/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

import BluetoothLinux
import Foundation
import Bluetooth

func PeripheralTest(adapter: Adapter) {

    do {
        
        let address = adapter.address!
        
        let server = try L2CAPSocket(adapterAddress: address,
                                     channelIdentifier: ATT.CID,
                                     addressType: .lowEnergyPublic,
                                     securityLevel: .low)
        
        print("Created L2CAP server")
        
        let newConnection = try server.waitForConnection()
        
        print("New \(newConnection.addressType) connection from \(newConnection.address)")
        
        let readData = try newConnection.recieve()
        
        print("Recieved data: \(String(UTF8Data: readData) ?? "\(readData.map({ String($0, radix: 16, uppercase: false) }))" )")
    }

    catch { Error("Error: \(error)") }
}

