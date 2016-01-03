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
func scan(adapter: BluetoothAdapter) {
    
    let scanDate = Date()
    
    print("Scanning...")
    
    let scanResults: [inquiry_info]
    
    do { scanResults = try adapter.scan() }
        
    catch { print("Count not scan: \(error)"); exit(1) }
    
    let scanDuration = Date() - scanDate
    
    print("Finished scanning (\(scanDuration)s)")
    
    print("Fetch names: ")
    
    for info in scanResults {
        
        let address = info.bdaddr
        
        print(address.rawValue)
        
        //let requestNameDate = Date()
        
        let name: String?
        
        do { name = try adapter.requestDeviceName(address, timeout: 10) }
            
        catch { name = nil; print("Error fetching name: \(error)") }
        
        print(name ?? "[No Name]")
    }
}