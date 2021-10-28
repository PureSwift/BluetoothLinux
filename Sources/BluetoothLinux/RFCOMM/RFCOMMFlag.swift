//
//  File.swift
//  
//
//  Created by Alsey Coleman Miller on 27/10/21.
//

import Bluetooth

/// RFCOMM Flags
@frozen
public enum RFCOMMFlag: UInt32, CaseIterable, BitMaskOption {
    
    case reuseDLC           = 0x01 // RFCOMM_REUSE_DLC
    case releaseOnHangup    = 0x02 // RFCOMM_RELEASE_ONHUP
    case hangupNow          = 0x04 // RFCOMM_HANGUP_NOW
    case serialAttached     = 0x08 // RFCOMM_TTY_ATTACHED
}
