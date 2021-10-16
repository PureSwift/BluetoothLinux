//
//  HCIDeviceFlag.swift
//  
//
//  Created by Alsey Coleman Miller on 16/10/21.
//

/// HCI device flags
public enum HCIDeviceFlag: Int32 {
    
    case up
    case initialized
    case running
    
    case passiveScan
    case interactiveScan
    case authenticated
    case encrypt
    case inquiry
    
    case raw
}
