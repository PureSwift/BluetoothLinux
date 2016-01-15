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
        case NoConnection
        case HardwareFailure
        case PageTimeout
        case AuthenticationFailure
        case KeyMissing
        case MemoryFull
        case ConnectionTimeout
        case MaxConnections
        case MaxSCOConnections
        case ACLConnectionExists
        case CommandDisallowed
        case RejectedLimitedResources
        case RejectedSecurity
        case RejectedPersonal
        case HostTimeout
        case UnsupportedFeature
        case InvalidParameters
        case OEUserEndedConnection
        case OELowResources
        case OEPowerOff
        case ConnectionTerminated
        case RepeatedAttempts
        case PairingNotAllowed
        
        // ... Add More
        
        case TransactionCollision       = 0x2a
        case QOSUnacceptableParameter   = 0x2c
        
        // TODO: Add all errors
        
        case HostBusyPairing    = 0x38
    }
}
