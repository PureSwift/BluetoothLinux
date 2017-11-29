//
//  LEScanTest.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 11/29/17.
//  Copyright © 2017 PureSwift. All rights reserved.
//

#if os(Linux)
    import BluetoothLinux
    import Glibc
#elseif os(macOS) || os(iOS)
    import Darwin.C
#endif

import Foundation
import Bluetooth

/// Tests the Scanning functionality
func LEScanTest(adapter: Adapter, duration: TimeInterval) {
    
    print("Scanning for \(duration) seconds...")
    
    let startDate = Date()
    let endDate = startDate + duration
    
    do { try adapter.lowEnergyScan(duration: duration,
                          shouldContinueScanning: { Date() < endDate },
                          foundDevice: { print($0.address) }) }
        
    catch { Error("Could not scan: \(error)") }
}
