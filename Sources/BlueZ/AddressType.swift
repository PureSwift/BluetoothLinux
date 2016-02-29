//
//  AddressType.swift
//  BlueZ
//
//  Created by Alsey Coleman Miller on 2/28/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

/// BlueZ Address type
public enum AddressType: CInt {
    
    case BREDR              = 0x00
    case LowEnergyRandom    = 0x01
    case LowEnergyPublic    = 0x02
    
    /// Whether the Bluetooth address type is LE.
    public var isLowEnergy: Bool {
        
        switch self {
            
        case .LowEnergyPublic, .LowEnergyRandom:
            return true
        
        default:
            return false
        }
    }
}