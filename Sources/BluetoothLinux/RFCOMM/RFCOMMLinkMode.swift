//
//  RFCOMMLinkMode.swift
//  
//
//  Created by Alsey Coleman Miller on 27/10/21.
//

import Bluetooth

/// RFCOMM Link Mode
@frozen
public enum RFCOMMLinkMode: UInt16, CaseIterable, BitMaskOption {
    
    case master         = 0x0001
    case authenticated  = 0x0002
    case encrypted      = 0x0004
    case trusted        = 0x0008
    case reliable       = 0x0010
    case secure         = 0x0020
}
