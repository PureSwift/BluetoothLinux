//
//  HCI.swift
//  BlueZ
//
//  Created by Alsey Coleman Miller on 3/1/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//


public struct HCI {
    
    
    
    // MARK: - Typealiases
    
    public typealias Error = HCIError
    
    public typealias Event = HCIEvent
}

/// HCI Errors
public enum HCIError: UInt8, ErrorType {
    
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
    
    case HostBusyPairing            = 0x38
}

/// HCI device flags
public enum HCIDeviceFlag: CInt {
    
    case Up
    case Initialized
    case Running
    
    case PassiveScan
    case InteractiveScan
    case Authenticated
    case Encrypt
    case Inquiry
    
    case Raw
}

/// HCI controller types
public enum HCIControllerType: UInt8 {
    
    case BREDR                      = 0x00
    case AMP                        = 0x01
}

/// HCI bus types
public enum HCIBusType: CInt {
    
    case Virtual
    case USB
    case PCCard
    case UART
    case RS232
    case PCI
    case SDIO
}



