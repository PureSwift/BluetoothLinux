//
//  ScanTest.swift
//  BlueZ
//
//  Created by Alsey Coleman Miller on 1/2/16.
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

/// Tests the Scanning functionality
func ScanTest(adapter: Adapter, timeout: Int) {
    
    let scanDate = Date()
    
    print("Scanning for ~\(timeout) seconds...")
    
    let scanResults: [inquiry_info]
    
    do { scanResults = try adapter.scan(timeout) }
        
    catch { Error("Could not scan: \(error)") }
    
    let scanDuration = Date() - scanDate
    
    print("Finished scanning (\(scanDuration)s)")
    
    for (index, info) in scanResults.enumerate() {
        
        let address = Address(byteValue: info.bdaddr.b)
        
        print("\(index + 1). " + address.rawValue)
        
        let requestNameDate = Date()
        
        let name: String?
        
        do { name = try adapter.requestDeviceName(address, timeout: 10) }
            
        catch { name = nil; print("Error fetching name: \(error)"); break }
        
        print(name ?? "[No Name]" + " (\(Date() - requestNameDate)s)")
    }
}
