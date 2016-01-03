//
//  OpcodeGroupField.swift
//  BlueZ
//
//  Created by Alsey Coleman Miller on 1/3/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

import SwiftFoundation

public enum OpcodeGroupField: Byte {
    
    /// Link Control
    case LinkControl = 0x01
    
    /// Link Policy
    case LinkPolicy = 0x02
    
    /// Host Controller and Baseband
    case HostController = 0x03
    
    /// Informational Parameters
    case InformationalParameters = 0x04
    
    /// Status Parameters
    case StatusParameters = 0x05
    
    /// Low Energy
    case LowEnergy = 0x08
    
    /// Testing Commands
    case Testing = 0x3e
    
    /// Vendor specific commands
    case Vendor = 0x3f
}