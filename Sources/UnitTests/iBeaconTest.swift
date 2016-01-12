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
    
    let uuid = UUID(rawValue: "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0")!
    
    print("Enabling iBeacon: \(uuid)")
    
    do { try adapter.enableBeacon(uuid, mayor: 1, minor: 1, RSSI: unsafeBitCast(Int8(-59), UInt8.self)) }
    
    catch { print("Error enabling iBeacon: \(error)"); exit(1) }
}

func manualBeaconEnable() {
    
    print("Enabling iBeacon Manually...")
    
    let deviceID = hci_get_route(nil)
    
    let deviceHandle = hci_open_dev(deviceID)
    
    guard deviceHandle != -1 else { "Could not open device"; exit(1) }
    
    var advParam = le_set_advertising_parameters_cp()
    
    memset(&advParam, 0, sizeof(le_set_advertising_parameters_cp))
    
    advParam.min_interval = UInt16(100).littleEndian
    
    advParam.max_interval = UInt16(100).littleEndian
    
    advParam.chan_map = 7
    
    var status = Byte()
    
    var request = hci_request()
    
    memset(&request, 0, sizeof(request.dynamicType))
    
    request.ogf = 0x08
    
    request.ocf = UInt16(OCF_LE_SET_ADVERTISING_PARAMETERS)
    
    withUnsafePointer(&advParam) { (pointer) in
        
        request.cparam = UnsafeMutablePointer<Void>(pointer)
    }
    
    request.clen = LE_SET_ADVERTISING_PARAMETERS_CP_SIZE
    
    withUnsafePointer(&status) { (pointer) in
        
        request.rparam = UnsafeMutablePointer<Void>(pointer)
    }
    
    request.rlen = 1
    
    guard hci_send_req(deviceHandle, &request, 1000) != -1 else { print("Cant send request"); exit(1) }
    
    
    
    sleep(1000)
}

