//
//  HCIDeviceEvent.swift
//  
//
//  Created by Alsey Coleman Miller on 16/10/21.
//

/// HCI dev events
public enum HCIDeviceEvent: CInt {
    
    case register                           = 1
    case unregister
    case up
    case down
    case suspend
    case resume
}
