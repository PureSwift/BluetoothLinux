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

// get Bluetooth device

guard let adapter = Adapter() else {
    
    print("No Bluetooth adapters found")
    
    exit(0)
}

print("Found Bluetooth adapter with device ID: \(adapter.deviceIdentifier)")

// test scanning
scan(adapter)


