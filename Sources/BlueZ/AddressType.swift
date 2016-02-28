//
//  AddressType.swift
//  BlueZ
//
//  Created by Alsey Coleman Miller on 2/28/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

public enum AddressType {
    
    case BDR
    case LowEnergyRandom
    case LowEnergyPublic
    
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