//
//  ATTConnection.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 2/29/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

#if os(Linux)
    import Glibc
#elseif os(OSX) || os(iOS)
    import Darwin.C
#endif

import struct SwiftFoundation.Data
import Bluetooth

/// Manages a Bluetooth connection using the ATT protocol.
public final class ATTConnection {
    
    // MARK: - Properties
    
    /// Actual number of bytes for PDU ATT exchange.
    public var maximumTransmissionUnit: Int = ATT.MTU.LowEnergy.Default {
        
        willSet {
            
            // enforce value range
            assert(newValue >= ATT.MTU.LowEnergy.Default)
            assert(newValue <= ATT.MTU.LowEnergy.Maximum)
        }
    }
    
    public let socket: L2CAPSocket
    
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
    private var requestQueue = [ATTSendOpcodeType]()
    
    /// Queued ATT protocol indications
    private var indicationQueue = [ATTSendOpcodeType]()
    
    /// Queue of PDUs ready to send
    private var writeQueue = [ATTSendOpcodeType]()
    
    /// List of registered callbacks.
    private var notifyList = [ATTNotifyType]()
    
    /// List of disconnect handlers.
    private var disconnectList = [() -> ()]()
    
    // MARK: - Initialization
    
    public init(socket: L2CAPSocket) {
        
        self.socket = socket
    }
    
    // MARK: - Methods
    
    /// Performs the actual IO for recieving data.
    public func read() throws {
        
        //print("Will read")
        
        let recievedData = try socket.recieve(maximumTransmissionUnit)
        
        //print("Recieved data")
        
        // valid PDU data length
        guard recievedData.byteValue.count >= ATT.MinimumPDULength
            else { throw Error.GarbageResponse(recievedData) }
        
        let opcodeByte = recievedData.byteValue[0]
        
        // valid opcode
        guard let opcode = ATT.Opcode(rawValue: opcodeByte)
            else { throw Error.GarbageResponse(recievedData) }
        
       // print("Recieved opcode \(opcode)")
        
        // Act on the received PDU based on the opcode type
        switch opcode.type {
            
        case .Response:
            
            try handle(response: recievedData, opcode: opcode)
            
        case .Confirmation:
            
            try handle(confirmation: recievedData, opcode: opcode)
            
        case .Request:
            
            try handle(request: recievedData, opcode: opcode)
            
        case .Command, .Notification, .Indication:
            
            // For all other opcodes notify the upper layer of the PDU and let them act on it.
            try handle(notify: recievedData, opcode: opcode)
        }
    }
    
    /// Performs the actual IO for sending data.
    public func write() throws -> Bool {
        
        //print("Will write")
        
        guard let sendOpcode = pickNextSendOpcode()
            else { return false }
        
        assert(sendOpcode.data.count <= maximumTransmissionUnit, "Trying to send \(sendOpcode.data.count) bytes when MTU is \(maximumTransmissionUnit)")
        
        //print("Sending data... (\(sendOpcode.data.count) bytes)")
        
        try socket.send(Data(byteValue: sendOpcode.data))
        
        let opcode = sendOpcode.dynamicType.PDUType.attributeOpcode
        
        //print("Did write \(opcode)")
        
        /* Based on the operation type, set either the pending request or the
        * pending indication. If it came from the write queue, then there is
        * no need to keep it around.
        */
        switch opcode.type {
            
        case .Request:
            
            pendingRequest = sendOpcode
            
        case .Indication:
            
            pendingRequest = sendOpcode
            
        case .Response:
            
            // Set `incomingRequest` to false to indicate that no request is pending
            incomingRequest = false
            
            // Fall through to the next case
            fallthrough
            
        case .Command, .Notification, .Confirmation:
            
            break
        }
        
        return true
    }
    
    /// Registers a callback for an opcode and returns the ID associated with that callback.
    public func register<T: ATTProtocolDataUnit>(_ callback: (T) -> ()) -> UInt {
        
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
    public func unregister(_ identifier: UInt) -> Bool {
        
        guard let index = notifyList.index(where: { $0.identifier == identifier })
            else { return false }
        
        notifyList.remove(at: index)
        
        return true
    }
    
    /// Registers all callbacks.
    public func unregisterAll() {
        
        notifyList.removeAll()
        
        disconnectList.removeAll()
    }
    
    /// Sends an error.
    public func send(error: ATT.Error, opcode: ATTOpcode, handle: UInt16 = 0, response: ((ATTErrorResponse) -> ())? = nil) -> UInt? {
        
        let error = ATTErrorResponse(requestOpcode: opcode, attributeHandle: handle, error: error)
        
        return self.send(PDU: error) { response?($0) }
    }
    
    /// Adds a PDU to the queue to send.
    ///
    /// - Returns: Identifier of queued send operation or `nil` if the PDU cannot be sent.
    public func send<T: ATTProtocolDataUnit>(PDU: T, response: (T) -> ()) -> UInt? {
        
        let attributeOpcode = T.attributeOpcode
        
        let type = attributeOpcode.type
        
        guard let encodedPDU = encode(PDU: PDU)
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
    
    public func cancel(_ identifier: UInt) {
        
        //wakeup_writer(att);
    }
    
    public func cancelAll() {
        
        //wakeup_writer(att);
    }
    
    // MARK: - Private Methods
    
    private func encode<T: ATTProtocolDataUnit>(PDU: T) -> [UInt8]? {
        
        let data = PDU.byteValue
        
        // actual PDU length
        let length = data.count
        
        //print("\(length) encoded bytes")
        
        /// MTU must be large enough to hold PDU. 
        guard length <= maximumTransmissionUnit else { return nil }
        
        // TODO: Sign (encrypt) data
        
        return data
    }
    
    private func handle(response data: Data, opcode: ATT.Opcode) throws {
        
        // If no request is pending, then the response is unexpected. Disconnect the bearer.
        guard let sendOpcode = pendingRequest else {
            
            throw Error.UnexpectedResponse(data)
        }
        
        // If the received response doesn't match the pending request, or if the request is malformed, 
        // end the current request with failure.
        guard sendOpcode.dynamicType.PDUType.attributeOpcode == opcode else {
            
            throw Error.UnexpectedResponse(data)
        }
        
        // attempt to deserialize
        guard let PDU = sendOpcode.dynamicType.PDUType.init(byteValue: data.byteValue)
            else { throw Error.GarbageResponse(data) }
        
        // success!
        sendOpcode.callback(PDU)
        
        self.pendingRequest = nil
        
        //wakeup_writer(att);
    }
    
    private func handle(confirmation data: Data, opcode: ATT.Opcode) throws {
        
        // Disconnect the bearer if the confirmation is unexpected or the PDU is invalid.
        
        guard let sendOpcode = pendingIndication
            else { throw Error.UnexpectedResponse(data) }
        
        guard data.byteValue.count == 1
            else { throw Error.GarbageResponse(data) }
        
        // attempt to deserialize
        guard let PDU = sendOpcode.dynamicType.PDUType.init(byteValue: data.byteValue)
            else { throw Error.GarbageResponse(data) }
        
        // success!
        sendOpcode.callback(PDU)
        
        self.pendingIndication = nil
        
        //wakeup_writer(att);
    }
    
    private func handle(request data: Data, opcode: ATT.Opcode) throws {
        
        /*
        * If a request is currently pending, then the sequential
        * protocol was violated. Disconnect the bearer, which will
        * promptly notify the upper layer via disconnect handlers.
        */
        
        // Received request while another is pending.
        guard incomingRequest == false
            else { throw Error.UnexpectedResponse(data) }
        
        incomingRequest = true
        
        // notify
        try handle(notify: data, opcode: opcode)
    }
    
    private func handle(notify data: Data, opcode: ATT.Opcode) throws {
        
        var foundPDU: ATTProtocolDataUnit?
        
        for notify in notifyList {
            
            // try next
            if notify.dynamicType.PDUType.attributeOpcode != opcode { continue }
            
            // attempt to deserialize
            guard let PDU = foundPDU ?? notify.dynamicType.PDUType.init(byteValue: data.byteValue)
                else { throw Error.GarbageResponse(data) }
            
            foundPDU = PDU
            
            notify.callback(PDU)
            
            // callback could remove all entries from notify list, if so, exit the loop
            if self.notifyList.isEmpty { break }
        }
        
        // If this was a request and no handler was registered for it, respond with "Not Supported"
        if foundPDU == nil && opcode.type == .Request {
            
            let errorResponse = ATTErrorResponse(requestOpcode: opcode, attributeHandle: 0x00, error: .RequestNotSupported)
            
            let _ = send(PDU: errorResponse) { _ in }
        }
        
    }
    
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
public enum ATTConnectionError: ErrorProtocol {
    
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
    
    var callback: (ATTProtocolDataUnit) -> () { get }
}

private struct ATTSendOpcode<PDU: ATTProtocolDataUnit>: ATTSendOpcodeType {
    
    static var PDUType: ATTProtocolDataUnit.Type { return PDU.self }
    
    let identifier: UInt
    
    let data: [UInt8]
    
    let response: (PDU) -> ()
    
    var callback: (ATTProtocolDataUnit) -> () { return { self.response($0 as! PDU) } }
    
    init(identifier: UInt, opcode: ATT.Opcode, data: [UInt8], response: (PDU) -> ()) {
        
        self.identifier = identifier
        self.data = data
        self.response = response
    }
}

private protocol ATTNotifyType {
    
    static var PDUType: ATTProtocolDataUnit.Type { get }
    
    var identifier: UInt { get }
    
    var callback: (ATTProtocolDataUnit) -> () { get }
}

private struct ATTNotify<PDU: ATTProtocolDataUnit>: ATTNotifyType {
    
    static var PDUType: ATTProtocolDataUnit.Type { return PDU.self }
    
    let identifier: UInt
    
    let notify: (PDU) -> ()
    
    var callback: (ATTProtocolDataUnit) -> () { return { self.notify($0 as! PDU) } }
    
    init(identifier: UInt, notify: (PDU) -> ()) {
        
        self.identifier = identifier
        self.notify = notify
    }
}

extension Array {
    
    mutating func popFirst() -> Element? {
        
        guard let first = self.first else { return nil }
        
        self.removeFirst()
        
        return first
    }
}
