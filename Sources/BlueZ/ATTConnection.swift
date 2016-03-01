//
//  ATTConnection.swift
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
    
    /// Actual number of bytes for PDU ATT exchange.
    public private(set) var maximumTransmissionUnit: Int = ATT.MTU.LowEnergy.Default
    
    // MARK: - Initialization
    
    public init(socket: L2CAPSocket) {
        
        self.socket = socket
    }
    
    // MARK: - Methods
    
    public func register(opcode: ATT.Opcode) {
        
        
    }
    
    public func unregister() {
        
        
    }
    
    public func unregisterAll() {
        
        
    }
    
    public func sendError(error: ATT.Error, opcode: ATT.Opcode, handle: UInt16) throws {
        
        var pdu = bt_att_pdu_error_rsp()
        
        pdu.opcode = opcode.rawValue
        pdu.ecode = error.rawValue
        pdu.handle = handle.littleEndian // put_le16(handle, &pdu.handle); att.c BlueZ
        
        // bt_att_send(att, BT_ATT_OP_ERROR_RSP, &pdu, sizeof(pdu), NULL, NULL, NULL);
        //send()
    }
    
    public func send<T: Any>(opcode: ATT.Opcode, PDU: T) throws {
        
        
    }
}

// MARK: - Darwin Stubs

#if os(OSX) || os(iOS)
    
    // Packed struct definitions for ATT protocol PDUs
    
    /// ATT Error Response protocol data unit
    ///
    /// Packed
    struct bt_att_pdu_error_rsp {
        
        var opcode: UInt8
        var handle: UInt16
        var ecode: UInt8
        
        init() { stub() }
    }
    
#endif
