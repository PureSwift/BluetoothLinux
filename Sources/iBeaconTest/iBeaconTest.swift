//
//  iBeaconTest.swift
//  BlueZ
//
//  Created by Alsey Coleman Miller on 1/3/16.
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

let iBeaconUUID = SwiftFoundation.UUID(rawValue: "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0")!

/// Test iBeacon
func iBeaconTest(adapter: Adapter, timeout: Int) {
    
    print("Enabling iBeacon \(iBeaconUUID) for \(timeout) seconds")
    
    do { try adapter.enableBeacon(iBeaconUUID, mayor: 1, minor: 1, RSSI: unsafeBitCast(Int8(-59), UInt8.self)) }
    
    catch { Error("Error enabling iBeacon: \(error)") }
    
    // sleep
    sleep(UInt32(timeout))
    
    do { try adapter.disableBeacon() }
    
    catch { Error("Error disabling iBeacon") }
}
