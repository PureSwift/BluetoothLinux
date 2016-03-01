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
    public var maximumTransmissionUnit: Int = ATT.MTU.LowEnergy.Default {
        
        willSet {
            
            // enforce value range
            assert(newValue >= ATT.MTU.LowEnergy.Default)
            assert(newValue <= ATT.MTU.LowEnergy.Maximum)
            
            // recreate buffer
            
        }
    }
    
    // MARK: - Private Properties
    
    // Internal buffer. Should always be the size of MTU.
    private var buffer = [UInt8](count: ATT.MTU.LowEnergy.Default, repeatedValue: 0)
    
    /// Whether ATT is engaged in write operation.
    private var writerActive = false
    
    /// There's a pending incoming request.
    private var incomingRequest = false
    
    /// IDs for registered callbacks.
    private var nextRegisterID: UInt = 0
    
    /// IDs for "send" ops.
    private var nextSendOpcodeID: UInt = 0
    
    /// Pending request state.
    private var pendingRequest: ATTSendOpcode?
    
    /// Pending indication state.
    private var pendingIndication: ATTSendOpcode?
    
    /// Queued ATT protocol requests
    private var requestQueue = Deque<ATTSendOpcode>()
    
    /// Queued ATT protocol indications
    private var indicationQueue = Deque<ATTSendOpcode>()
    
    /// Queue of PDUs ready to send
    private var writeQueue = Deque<ATTSendOpcode>()
    
    /// List of registered callbacks.
    private var notifyList = Deque<() -> ()>()
    
    /// List of disconnect handlers.
    private var disconnectList = Deque<() -> ()>()
    
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
    
    public func send<T: ATTProtocolDataUnit>(PDU: T) throws {
        
        let sendOpcode = createSendOpcode()
        
        
    }
    
    // MARK: - Private Methods
    
    private func createSendOpcode() -> ATTSendOpcode {
        
        
    }
    
    private func encodePDU(sendOpcode: ATTSendOpcode) -> [UInt8] {
        
        
    }
}

// MARK: - Private Supporting Types

private struct ATTSendOpcode {
    
    let identifier: UInt
    
    let opcode: ATT.Opcode
    
    let PDU: [UInt8]
    
    let response: () -> ()
    
    init(identifier: UInt, opcode: ATT.Opcode, PDU: [UInt8], response: () -> ()) {
        
        self.identifier = identifier
        self.opcode = opcode
        self.PDU = PDU
        self.response = response
    }
}

private struct ATTNotify {
    
    let identifier: UInt
    
    let opcode: ATT.Opcode
    
    let notify: () -> ()
    
    init(identifier: UInt, opcode: ATT.Opcode, notify: () -> ()) {
        
        self.identifier = identifier
        self.opcode = opcode
        self.notify = notify
    }
}
