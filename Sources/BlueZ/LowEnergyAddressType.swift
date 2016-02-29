//
//  LowEnergyAddressType.swift
//  BlueZ
//
//  Created by Alsey Coleman Miller on 1/3/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

public extension Address {
    
    public enum LowEnergyType: UInt8 {
        
        case Public = 0x00
        case Random = 0x01
    }
}