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
        
        case UnknownCommand             = 0x01
        case NoConnection               = 0x02
        case HardwareFailure            = 0x03
        case PageTimeout                = 0x04
        case AuthenticationFailure      = 0x05
        case KeyMissing                 = 0x06
        case MemoryFull                 = 0x07
        case ConnectionTimeout          = 0x08
        case MaxConnections             = 0x09
        case MaxDeviceSCOConnections    = 0x0A
        case ACLConnectionAlreadyExists = 0x0B
        case CommandDisallowed          = 0x0C
        
        // TODO: Add all errors
        
        case HostBusyPairing    = 0x38
    }
}
