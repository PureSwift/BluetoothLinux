//
//  LEScanTest.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 11/29/17.
//  Copyright © 2017 PureSwift. All rights reserved.
//

import BluetoothLinux
import Foundation
import Bluetooth

/// Tests the Scanning functionality
func LECreateConnection(adapter: Adapter, peerAddress: Address) {
    
    typealias ConnectionInterval = LowEnergyCommand.CreateConnectionParameter.ConnectionInterval
    
    let connectionParameters = LowEnergyCommand.CreateConnectionParameter
        .init(scanInterval: .min, // 0x0004
              scanWindow: .min, // 0x0004
              initiatorFilterPolicy: .peerAddress,
              peerAddressType: .public,
              peerAddress: peerAddress,
              ownAddressType: .public,
              connectionInterval: ConnectionInterval(rawValue: (0x000F ... 0x000F))!,
              connectionLatency: .zero,
              supervisionTimeout: .max,
              connectionLength: .init(rawValue: 0x0001 ... 0x0001))
    
    do {
        
        print("Connecting to \(peerAddress)")
        
        let handle = try adapter.lowEnergyCreateConnection(parameters: connectionParameters, commandTimeout: 25000)
        
        print("Connection handle \(handle)")
    }
    
    catch { Error("Could not scan: \(error)") }
}
