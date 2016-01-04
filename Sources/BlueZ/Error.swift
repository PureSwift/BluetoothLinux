//
//  Error.swift
//  BlueZ
//
//  Created by Alsey Coleman Miller on 1/4/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

public extension Bluetooth {
    
    public enum Error: ErrorType {
        
        /// The error status byte used with `deviceRequest()`.
        case DeviceRequestStatus(UInt8)
    }
}