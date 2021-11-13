//
//  HCIPacketType.swift
//  
//
//  Created by Alsey Coleman Miller on 16/10/21.
//

import BluetoothHCI

/// HCI Packet types
public enum HCIPacketType: UInt8 {
    
    case command                            = 0x01
    case acl                                = 0x02
    case sco                                = 0x03
    case event                              = 0x04
    case vendor                             = 0xff
}

internal extension HCIEventHeader {
    
    static var maximumSize: Int { 260 }
}
