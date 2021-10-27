//
//  RFCOMMSocketOption.swift
//  
//
//  Created by Alsey Coleman Miller on 16/10/21.
//

import Bluetooth
import SystemPackage

/// RFCOMM Socket Options
@frozen
public enum RFCOMMSocketOption: CInt, SocketOptionID {
    
    @_alwaysEmitIntoClient
    public static var optionLevel: SocketOptionLevel { .rfcomm }
    
    /// RFCOMM Connection Info
    case connectionInfo     = 0x02 // RFCOMM_CONNINFO
    
    /// RFCOMM LM
    case linkMode           = 0x03 // RFCOMM_LM
}
