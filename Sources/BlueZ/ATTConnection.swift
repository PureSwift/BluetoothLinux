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
    
    // MARK: - Private Properties
    
    /// There's a pending incoming request.
    private var incomingRequest = false
    
    /// IDs for registered callbacks.
    private var nextRegisterID: UInt = 0
    
    /// IDs for "send" ops.
    private var nextSendOpcodeID: UInt = 0
    
    /// Pending request state.
    private var pendingRequest: ATTSendOpcodeType?
    
    /// Pending indication state.
    private var pendingIndication: ATTSendOpcodeType?
    
    /// Queued ATT protocol requests
    private var requestQueue = Deque<ATTSendOpcodeType>()
    
    /// Queued ATT protocol indications
    private var indicationQueue = Deque<ATTSendOpcodeType>()
    
    /// Queue of PDUs ready to send
    private var writeQueue = Deque<ATTSendOpcodeType>()
    
    /// List of registered callbacks.
    private var notifyList = Deque<ATTNotifyType>()
    
    /// List of disconnect handlers.
    private var disconnectList = Deque<() -> ()>()
    
    // MARK: - Initialization
    
    public init(socket: L2CAPSocket) {
        
        self.socket = socket
    }
    
    // MARK: - Methods
    
    /// Performs the actual IO for recieving data.
    public func read() throws {
        
        let recievedData = try self.socket.recieve(maximumTransmissionUnit)
        
        // valid PDU data length
        guard recievedData.byteValue.count >= ATT.MinimumPDULength
            else { throw Error.GarbageResponse(recievedData) }
        
        let opcodeByte = recievedData.byteValue[0]
        
        // valid opcode
        guard let opcode = ATT.Opcode(rawValue: opcodeByte)
            else { throw Error.GarbageResponse(recievedData) }
        
        // Act on the received PDU based on the opcode type
        switch opcode.type {
            
        case .Response: try handleResponse(recievedData, opcode: opcode)
        }
        
        
        
    }
    
    /// Performs the actual IO for sending data.
    public func write() throws {
        
        guard let sendOpcode = pickNextSendOpcode()
            else { return } // throw error?
        
        //try socket.send(Data(byteValue: []))
        
        
    }
    
    /// Registers a callback for an opcode and returns the ID associated with that callback.
    public func register<T: ATTProtocolDataUnit>(callback: T -> ()) -> UInt {
        
        let identifier = nextRegisterID
        
        // create notification
        let notify = ATTNotify(identifier: identifier, notify: callback)
        
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
    public func send<T: ATTProtocolDataUnit>(PDU: T, response: T -> ()) -> UInt? {
        
        let attributeOpcode = T.attributeOpcode
        
        let type = attributeOpcode.type
        
        guard let encodedPDU = encodePDU(PDU)
            else { return nil }
        
        let identifier = nextSendOpcodeID
        
        let sendOpcode = ATTSendOpcode(identifier: identifier, opcode: attributeOpcode, data: encodedPDU, response: response)
        
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
    
    private func handleResponse(data: Data, opcode: ATT.Opcode) throws {
        
        // If no request is pending, then the response is unexpected. Disconnect the bearer.
        guard let pendingRequest = pendingRequest else {
            
            throw Error.UnexpectedResponse(data)
        }
        
        // If the received response doesn't match the pending request, or if the request is malformed, 
        // end the current request with failure.
        guard pendingRequest.dynamicType.PDUType.attributeOpcode == opcode else {
            
            /*
            // attempt to recover from unexpected error
            guard opcode != ATT.Opcode.ErrorResponse else {
                
                try handleErrorResponse(data, opcode: opcode)
            }*/
            
            throw Error.UnexpectedResponse(data)
        }
        
        // attempt to deserialize
        guard let PDU = pendingRequest.dynamicType.PDUType.init(byteValue: data.byteValue)
            else { throw Error.GarbageResponse(data) }
        
        // success!
        pendingRequest.callback(PDU)
        
        self.pendingRequest = nil
    }
    
    private func handleErrorResponse(data: Data, opcode: ATT.Opcode) throws {
        
        
    }
    
    private func handleConfirmation() {
        
        
    }
    
    /*
    private func canReadData() -> Bool {
        
        
    }
    
    private func canWriteData() -> Bool {
        
        guard let sendOpcode = pickNextSendOpcode()
            else { return false }
    }*/
    
    private func pickNextSendOpcode() -> ATTSendOpcodeType? {
        
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
}

// MARK: - Supporting Types

public extension ATTConnection {
    public typealias Error = ATTConnectionError
}

/// ATT Connection Error
public enum ATTConnectionError: ErrorType {
    
    /// The recieved data could not be parsed correctly.
    case GarbageResponse(Data)
    
    /// Response is unexpected.
    case UnexpectedResponse(Data)
}

// MARK: - Private Supporting Types

private protocol ATTSendOpcodeType {
    
    static var PDUType: ATTProtocolDataUnit.Type { get }
    
    var identifier: UInt { get }
    
    var data: [UInt8] { get }
    
    var callback: ATTProtocolDataUnit -> () { get }
}

private struct ATTSendOpcode<PDU: ATTProtocolDataUnit>: ATTSendOpcodeType {
    
    static var PDUType: ATTProtocolDataUnit.Type { return PDU.self }
    
    let identifier: UInt
    
    let data: [UInt8]
    
    let response: PDU -> ()
    
    var callback: ATTProtocolDataUnit -> () { return { self.response($0 as! PDU) } }
    
    init(identifier: UInt, opcode: ATT.Opcode, data: [UInt8], response: PDU -> ()) {
        
        self.identifier = identifier
        self.data = data
        self.response = response
    }
}

private protocol ATTNotifyType {
    
    static var PDUType: ATTProtocolDataUnit.Type { get }
    
    var identifier: UInt { get }
    
    var callback: ATTProtocolDataUnit -> () { get }
}

private struct ATTNotify<PDU: ATTProtocolDataUnit>: ATTNotifyType {
    
    static var PDUType: ATTProtocolDataUnit.Type { return PDU.self }
    
    let identifier: UInt
    
    let notify: PDU -> ()
    
    var callback: ATTProtocolDataUnit -> () { return { self.notify($0 as! PDU) } }
    
    init(identifier: UInt, notify: PDU -> ()) {
        
        self.identifier = identifier
        self.notify = notify
    }
}
