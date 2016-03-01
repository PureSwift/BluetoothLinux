//
//  ATT.swift
//  BlueZ
//
//  Created by Alsey Coleman Miller on 2/29/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

// MARK: - Protocol Definitions

/// Bluetooth ATT protocol
public struct ATT {
    
    public static let PSM: ProtocolServiceMultiplexer   = .ATT
    
    public static let CID: UInt16                       = 4
    
    public static let MinimumPDULength                  = 1  /* At least 1 byte for the opcode. */
    
    public static let Timeout: Int                      = 30000 /* 30000 ms */
    
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
        
        public static let CommandMask                   = 0x40
        public static let SignedMask                    = 0x80
        
        case ErrorResponse                              = 0x01
        case MaximumTransmissionUnitRequest             = 0x02
        case MaximumTransmissionUnitResponse            = 0x03
        case FindInformationRequest                     = 0x04
        case FindInformationResponse                    = 0x05
        case FindByTypeRequest                          = 0x06
        case FindByTypeResponse                         = 0x07
        case ReadByTypeRequest                          = 0x08
        case ReadByTypeResponse                         = 0x09
        
        // TODO: All Opcodes
    }
    
    /// Error codes for Error response PDU.
    public enum Error: UInt8 {
        
        case InvalidHandle                              = 0x01
        case ReadNotPermitted                           = 0x02
        
        // TODO: All Error Codes
        
    }
    
    /// ATT attribute permission bitfield values. Permissions are grouped as
    /// "Access", "Encryption", "Authentication", and "Authorization". A bitmask of
    /// permissions is a byte that encodes a combination of these.
    public enum AttributePermission: UInt8 {
        
        // Access
        case Read                                       = 0x01
        case Write                                      = 0x02
        
        // Encryption
        case Encrypt                                    = 12 // ReadEncrypt | WriteEncrypt
        case ReadEncrypt                                = 0x04
        case WriteEncrypt                               = 0x08
        
        // Authentication
        case Authentication                             = 48 // ReadAuthentication | WriteAuthentication
        case ReadAuthentication                         = 0x10
        case WriteAuthentication                        = 0x20
        
        // Authorization
        case Authorized                                 = 0x40
        case None                                       = 0x80
    }
    
}




