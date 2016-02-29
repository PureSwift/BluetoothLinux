//
//  ATT.swift
//  BlueZ
//
//  Created by Alsey Coleman Miller on 2/29/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

#if os(Linux)
    import CBlueZ
    import Glibc
#elseif os(OSX) || os(iOS)
    import Darwin.C
#endif

import SwiftFoundation

/// Manages a Bluetooth connection using the ATT protocol.
public final class ATTConnection {
    
    // MARK: - Properties
    
    public let socket: L2CAPSocket
    
    public private(set) var maximumTransmissionUnit: Int = BT_ATT_DEFAULT_LE_MTU
    
    // MARK: - Initialization
    
    public init(socket: L2CAPSocket) {
        
        self.socket = socket
    }
}

// MARK: - Protocol Definitions

/// Bluetooth ATT protocol
public struct ATT {
    
    public static let PSM: UInt16                       = 31
    
    public static let CID: UInt16                       = 4
    
    public static let MinimumPDULength                  = 1  /* At least 1 byte for the opcode. */
    
    public static let OpcodeCommandMask                 = 0x40
    
    public static let OpcodeSignedMask                  = 0x80
    
    public static let Timeout: TimeInterval             = 30000 /* 30000 ms */
    
    /// Length of signature in write signed packet.
    public static let SignatureLength                   = 12
    
    public static let MaximumValueLength                = 512
    
    /// ATT MTU constants
    public struct MTU {
        
        public struct LowEnergy {
            
            public static let Default                   = 23
            
            public static let Maximum                   = 517
        }
    }
    
    /// ATT protocol security
    public enum Security: CInt {
        
        case Auto       = 0
        case Low        = 1
        case Medium     = 2
        case High       = 3
    }
    
    /// ATT protocol opcodes.
    public enum Opcode: UInt8 {
        
        case ErrorResponse                              = 0x01
        case MaximumTransmissionUnitRequest             = 0x02
        case MaximumTransmissionUnitResponse            = 0x03
        case 
    }
}




