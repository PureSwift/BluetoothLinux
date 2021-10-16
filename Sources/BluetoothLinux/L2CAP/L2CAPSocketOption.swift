//
//  L2CAPSocketOption.swift
//  
//
//  Created by Alsey Coleman Miller on 16/10/21.
//

import SystemPackage

/// L2CAP Socket Options
public enum L2CAPSocketOption: CInt, SocketOptionID {
    
    public static var optionLevel: SocketOptionLevel { .l2cap }
    
    /// L2CAP Socket Options
    case options        = 0x01
    
    /// L2CAP Connection Info
    case connectionInfo = 0x02
    
    /// L2CAP LM
    case lm             = 0x03
}

