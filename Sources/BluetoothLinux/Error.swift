//
//  Error.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 1/4/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

public enum BluetoothLinuxError: ErrorType {
    
    /// The specified adapter could not be found.
    case AdapterNotFound
    
    /// The error status byte used with `deviceRequest()`.
    case DeviceRequestStatus(UInt8)
}