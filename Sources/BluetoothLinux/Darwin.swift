//
//  Darwin.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 2/28/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

import SystemPackage

#if !os(Linux)
#warning("This module will only run on Linux")
internal func stub() -> Never {
    fatalError("Method not implemented. This code only runs on Linux.")
}

internal extension SocketAddressFamily {
    
    @usableFromInline
    static var bluetooth: SocketAddressFamily { stub() }
}

#endif

#if os(Android)
#warning("Android does not use BlueZ kernel module")
#endif
