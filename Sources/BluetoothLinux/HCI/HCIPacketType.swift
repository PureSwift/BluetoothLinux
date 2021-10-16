//
//  HCIPacketType.swift
//  
//
//  Created by Alsey Coleman Miller on 16/10/21.
//

/// HCI Packet types
public enum HCIPacketType: UInt8 {
    
    case command                            = 0x01
    case acl                                = 0x02
    case sco                                = 0x03
    case event                              = 0x04
    case vendor                             = 0xff
}
