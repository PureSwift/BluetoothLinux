//
//  main.swift
//  BlueZ
//
//  Created by Alsey Coleman Miller on 12/6/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

#if os(Linux)
    import CBlueZ
    import Glibc
    import BlueZ
#elseif os(OSX) || os(iOS)
    import Darwin.C
#endif

import SwiftFoundation

guard let adapter = Adapter() else {
    
    print("No Bluetooth adapters found")
    
    exit(0)
}

print("Found Bluetooth adapter with device ID: \(adapter.deviceIdentifier)")

let scanDate = Date()

print("Scanning...")

let scanResults: [inquiry_info] 

do { scanResults = try adapter.scan() }

catch { print("Count not scan: \(error)"); exit(1) }

let scanDuration = Date() - scanDate

print("Finished scanning (\(scanDuration)s)")

print("Fetch names: ")

for info in scanResults {
    
    let address = Address(bytes: info.bdaddr)
    
    print(address.rawValue)
    
    let requestNameDate = Date()
    
    let name: String?
    
    do { name = try adapter.requestDeviceName(address, timeout: 10) }
    
    catch { name = nil; print("Error fetching name: \(error)") }
    
    print(name ?? "[No Name]")
}


