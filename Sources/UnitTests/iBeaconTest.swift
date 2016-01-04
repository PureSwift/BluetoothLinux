//
//  iBeaconTest.swift
//  BlueZ
//
//  Created by Alsey Coleman Miller on 1/3/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

#if os(Linux)
    import CBlueZ
    import Glibc
    import BlueZ
#elseif os(OSX) || os(iOS)
    import Darwin.C
#endif

import SwiftFoundation


/// Test iBeacon
func iBeacon(adapter: BluetoothAdapter) {
    
    let uuid = UUID()
    
    print("Enabling iBeacon: \(uuid)")
    
    do { try adapter.enableBeacon(uuid, mayor: 1, minor: 1, RSSI: unsafeBitCast(Int8(-59), UInt8.self)) }
    
    catch { print("Error enabling iBeacon: \(error)"); exit(1) }
}