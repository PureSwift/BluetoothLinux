//
//  iBeaconTest.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 1/3/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

import BluetoothLinux
import Foundation

/// Well known iBeacon UUID
let iBeaconUUID = Foundation.UUID(rawValue: "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0")!

/// Test iBeacon
func iBeaconTest(adapter: Adapter, timeout: Int) {
    
    print("Enabling iBeacon \(iBeaconUUID) for \(timeout) seconds")
    
    do { try adapter.enableBeacon(UUID: iBeaconUUID, major: 1, minor: 1, RSSI: -29) }
    
    catch { Error("Error enabling iBeacon: \(error)") }
    
    // sleep
    sleep(UInt32(timeout))
    
    do { try adapter.enableLowEnergyAdvertising(false) }
    
    catch { Error("Error disabling iBeacon") }
}
