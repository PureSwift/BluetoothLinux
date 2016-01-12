//
//  ScanTest.swift
//  BlueZ
//
//  Created by Alsey Coleman Miller on 1/2/16.
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

/// Tests the Scanning functionality
func ScanTest(adapter: BluetoothAdapter, timeout: Int) {
    
    let scanDate = Date()
    
    print("Scanning for ~\(timeout) seconds...")
    
    let scanResults: [inquiry_info]
    
    do { scanResults = try adapter.scan(timeout) }
        
    catch { Error("Count not scan: \(error)") }
    
    let scanDuration = Date() - scanDate
    
    print("Finished scanning (\(scanDuration)s)")
    
    for info in scanResults {
        
        let address = info.bdaddr
        
        print(address.rawValue)
        
        /*
        let requestNameDate = Date()
        
        let name: String?
        
        do { name = try adapter.requestDeviceName(address, timeout: 10) }
            
        catch { name = nil; print("Error fetching name: \(error)") }
        
        print(name ?? "[No Name]")
        */
    }
}