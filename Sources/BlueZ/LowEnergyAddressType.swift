//
//  LowEnergyAddressType.swift
//  BlueZ
//
//  Created by Alsey Coleman Miller on 1/3/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

import SwiftFoundation

public extension Address {
    
    public enum LowEnergyAddressType: CInt {
        
        case Public = 0x00
        case Random = 0x01
    }
}