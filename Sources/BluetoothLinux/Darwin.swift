//
//  Darwin.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 2/28/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

#if canImport(Darwin)
internal func stub() -> Never {
    fatalError("Method not implemented. This code only runs on Linux.")
}
#endif

#if !os(Linux)
#warning("This module will only run on Linux")
#endif
