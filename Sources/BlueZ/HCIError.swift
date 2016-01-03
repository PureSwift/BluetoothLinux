//
//  HCIError.swift
//  BlueZ
//
//  Created by Alsey Coleman Miller on 1/3/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

import SwiftFoundation

public extension Bluetooth {
    
    /// HCI Errors
    public enum HCIError: Byte, ErrorType {
        
        case UnknownCommand     = 0x01
        case NoConnection       = 0x02
        case HardwareFailure    = 0x03
        
        // TODO: Add all errors
        
        case HostBusyPairing    = 0x38
    }
}
