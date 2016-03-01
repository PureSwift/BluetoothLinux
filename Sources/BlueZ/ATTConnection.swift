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
        }
    }
    
    /// Whether logging is enabled.
    public var logEnabled: Bool = false
    
    // MARK: - Private Properties
    
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
    ///
    /// - Returns: Whether the socket did recieve valid data.
    public func read() throws -> Bool {
        
        let recievedData = try self.socket.recieve(maximumTransmissionUnit)
        
        // valid PDU data length
        guard recievedData.byteValue.count >= ATT.MinimumPDULength
            else { return false }
        
        let opcodeByte = recievedData.byteValue[0]
        
        // valid opcode
        guard let opcode = ATT.Opcode(rawValue: opcodeByte)
            else { return false }
        
        // Act on the received PDU based on the opcode type
        switch opcode.type {
            
        case .Response:
            
            
        }
        
        
        
    }
    
    /// Performs the actual IO for sending data.
    ///
    /// - Returns: Whether the socket sent data.
    public func write() throws -> Bool {
        
        guard let sendOpcode = pickNextSendOpcode()
            else { return false }
        
        try socket.send(Data(byteValue: []))
        
        
    }
    
    /// Registers a callback for an opcode and returns the ID associated with that callback.
    public func register<T: ATTProtocolDataUnit>(callback: T -> ()) -> UInt {
        
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
    
    /// Registers all callbacks.
    public func unregisterAll() {
        
        notifyList.removeAll()
        disconnectList.removeAll()
    }
    
    /// Adds a PDU to the queue to send.
    ///
    /// - Returns: Identifier of queued send operation or `nil` if the PDU cannot be sent.
    public func send<T: ATTProtocolDataUnit>(PDU: T, response: ATTResponseCallback? = nil) -> UInt? {
        
        let attributeOpcode = T.attributeOpcode
        
        let type = attributeOpcode.type
        
        /* If the opcode corresponds to an operation type that does not elicit a
        * response from the remote end, then no callback should have been
        * provided, since it will never be called.
        */
        guard (response != nil && type != .Request && type != .Response) == false
            else { return nil }
        
        /* Similarly, if the operation does elicit a response then a callback
        * must be provided.
        */
        guard (response == nil && (type == .Request || type == .Indication)) == false
            else { return nil }
        
        guard let encodedPDU = encodePDU(PDU)
            else { return nil }
        
        let identifier = nextSendOpcodeID
        
        let sendOpcode = ATTSendOpcode(identifier: identifier, opcode: attributeOpcode, PDU: encodedPDU, response: response)
        
        // increment ID
        nextSendOpcodeID += 1
        
        // Add the op to the correct queue based on its type
        switch type {
            
        case .Request:
            
            requestQueue.append(sendOpcode)
            
        case .Indication:
            
            indicationQueue.append(sendOpcode)
            
        case .Command, .Notification, .Response, .Confirmation:
            
            writeQueue.append(sendOpcode)
        }
        
        //wakeup_writer(att);
        
        return sendOpcode.identifier
    }
    
    public func cancel(identifier: UInt) {
        
        //wakeup_writer(att);
    }
    
    public func cancelAll() {
        
        //wakeup_writer(att);
    }
    
    // MARK: - Private Methods
    
    private func encodePDU<T: ATTProtocolDataUnit>(PDU: T) -> [UInt8]? {
        
        let data = PDU.byteValue
        
        // actual PDU length
        let length = T.length
        
        /// MTU must be large enough to hold PDU. 
        guard length <= maximumTransmissionUnit else { return nil }
        
        // TODO: Sign (encrypt) data
        
        return data
    }
    
    private func handleResponse() {
        
        // If no request is pending, then the response is unexpected. Disconnect the bearer.
        guard let pendingRequest = pendingRequest else {
            
            //util_debug(att->debug_callback, att->debug_data,
            //   "Received unexpected ATT response");
            //io_shutdown(att->io);
            
            return
        }
        
        // If the received response doesn't match the pending request, or if the request is malformed, 
        // end the current request with failure.
        
    }
    
    /*
    private func canReadData() -> Bool {
        
        
    }
    
    private func canWriteData() -> Bool {
        
        guard let sendOpcode = pickNextSendOpcode()
            else { return false }
    }*/
    
    private func pickNextSendOpcode() -> ATTSendOpcode? {
        
        // See if any operations are already in the write queue
        if let sendOpcode = writeQueue.popFirst() {
            
            return sendOpcode
        }
        
        // If there is no pending request, pick an operation from the request queue.
        if let sendOpcode = requestQueue.popFirst() where pendingRequest == nil {
            
            return sendOpcode
        }
        
        // There is either a request pending or no requests queued. 
        // If there is no pending indication, pick an operation from the indication queue.
        if let sendOpcode = indicationQueue.popFirst() where pendingIndication == nil {
            
            return sendOpcode
        }
        
        return nil
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

private struct ATTNotify<PDU: ATTProtocolDataUnit> {
    
    let identifier: UInt
    
    let opcode: ATT.Opcode
    
    let notify: PDU -> ()
    
    init(identifier: UInt, opcode: ATT.Opcode, notify: PDU -> ()) {
        
        self.identifier = identifier
        self.opcode = opcode
        self.notify = notify
    }
}
