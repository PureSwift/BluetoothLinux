//
//  HCIDeviceEvent.swift
//  
//
//  Created by Alsey Coleman Miller on 16/10/21.
//

/// HCI dev events
public enum HCIDeviceEvent: CInt {
    
    case register       = 1
    case unregister     = 2
    case up             = 3
    case down           = 4
    case suspend        = 5
    case resume         = 6
}
