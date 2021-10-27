//
//  RFCOMMState.swift
//  
//
//  Created by Alsey Coleman Miller on 27/10/21.
//

/// RFCOMM State
@frozen
public enum RFCOMMState: UInt16, CaseIterable, Codable {
    
    case unknown            = 0x00
    case connected          = 0x01
    case clean              = 0x02
    case bound              = 0x03
    case listening          = 0x04
    case connecting         = 0x05
    case connecting2        = 0x06 // FIXME: Duplicate connecting definitions
    case config             = 0x07
    case disconnecting      = 0x08
    case closed             = 0x09
}
