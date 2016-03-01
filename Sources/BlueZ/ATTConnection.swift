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
    public var maximumTransmissionUnit: Int {
        
        get { return buffer.count }
        
        set {
            
            // enforce value range
            assert(newValue >= ATT.MTU.LowEnergy.Default)
            assert(newValue <= ATT.MTU.LowEnergy.Maximum)
            
            // recreate buffer
            buffer = [UInt8](count: newValue, repeatedValue: 0)
        }
    }
    
    /// Whether logging is enabled.
    public var logEnabled: Bool = false
    
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
    private var notifyList = Deque<ATTNotify>()
    
    /// List of disconnect handlers.
    private var disconnectList = Deque<() -> ()>()
    
    // MARK: - Initialization
    
    public init(socket: L2CAPSocket) {
        
        self.socket = socket
    }
    
    // MARK: - Methods
    
    /// Performs the actual IO for recieving data.
    public func read() throws {
        
        //let data = try self.socket.recieve(maximumTransmissionUnit)
        
        
    }
    
    /// Performs the actual IO for sending data.
    public func write() throws {
        
        try self.socket.send(Data(byteValue: buffer))
    }
    
    /// Registers a callback for an opcode and returns the ID associated with that callback.
    public func register(opcode: ATT.Opcode, callback: ATTNotifyCallback) -> UInt {
        
        // ID starts at 1
        if nextRegisterID < 1 {
            
            nextRegisterID = 1
        }
        
        let identifier = nextRegisterID
        
        // create notification
        let notify = ATTNotify(identifier: identifier, opcode: opcode, notify: callback)
        
        // increment ID
        nextRegisterID += 1
        
        // add to queue
        notifyList.append(notify)
        
        return identifier
    }
    
    /// Unregisters the callback associated with the specified identifier.
    ///
    /// - Returns: Whether the callback was unregistered.
    public func unregister(identifier: UInt) -> Bool {
        
        guard let index = notifyList.indexOf({ $0.identifier == identifier })
            else { return false }
        
        notifyList.removeAtIndex(index)
        
        return true
    }
    
    public func unregisterAll() {
        
        notifyList.removeAll()
        disconnectList.removeAll()
    }
    
    /// Adds a PDU to the queue to send.
    public func send<T: ATTProtocolDataUnit>(PDU: T, response: ATTResponseCallback? = nil) throws {
        
        let sendOpcode = createSendOpcode()
        
        
    }
    
    // MARK: - Private Methods
    
    private func createSendOpcode<T: ATTProtocolDataUnit>(PDU: T) -> ATTSendOpcode {
        
        /* If the opcode corresponds to an operation type that does not elicit a
        * response from the remote end, then no callback should have been
        * provided, since it will never be called.
        */
        guard ()
    }
    
    private func encodePDU(sendOpcode: ATTSendOpcode) -> [UInt8] {
        
        
    }
    
    private func log(string: String) {
        
        if self.logEnabled { print(string) }
    }
}

// MARK: - Supporting Types

public typealias ATTResponseCallback = ATTProtocolDataUnit -> ()

public typealias ATTNotifyCallback = ATTProtocolDataUnit -> ()

// MARK: - Private Supporting Types

private struct ATTSendOpcode {
    
    let identifier: UInt
    
    let opcode: ATT.Opcode
    
    let PDU: [UInt8]
    
    let response: ATTResponseCallback
    
    init(identifier: UInt, opcode: ATT.Opcode, PDU: [UInt8], response: ATTResponseCallback) {
        
        self.identifier = identifier
        self.opcode = opcode
        self.PDU = PDU
        self.response = response
    }
}

private struct ATTNotify {
    
    let identifier: UInt
    
    let opcode: ATT.Opcode
    
    let notify: ATTNotifyCallback
    
    init(identifier: UInt, opcode: ATT.Opcode, notify: ATTNotifyCallback) {
        
        self.identifier = identifier
        self.opcode = opcode
        self.notify = notify
    }
}
