//
//  DeviceRequest.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 1/3/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

#if os(Linux)
    import Glibc
#elseif os(OSX) || os(iOS)
    import Darwin.C
#endif

import SwiftFoundation

public extension Adapter {

    /// Sends a command to the device and waits for a response.
    @inline(__always)
    func deviceRequest<T: HCICommand>(command: T, timeout: Int = 1000) throws {
        
        
    }
    
    @inline(__always)
    func deviceRequest<T: HCICommandParameter>(commandParameter: T, timeout: Int = 1000) throws {
        
        
    }
    
    /*
    @inline(__always)
    func deviceCommand<T: HCICommand>(command: T) throws {
        
        try HCISendCommand(internalSocket, opcode: (command.rawValue, T.opcodeGroupField.rawValue))
    }
    
    @inline(__always)
    func deviceCommand<T: HCICommandParameter>(commandParameter: T) throws {
        
        let command = T.command
        
        let opcodeGroupField = command.dynamicType.opcodeGroupField
        
        let parameterData = commandParameter.byteValue
        
        try HCISendCommand(internalSocket, opcode: (command.rawValue, opcodeGroupField.rawValue), parameterData: parameterData)
    }*/
}

// MARK: - Internal HCI Functions

/// int hci_send_req(int dd, struct hci_request *r, int to)
/// Returns event parameter data.
internal func HCISendRequest(deviceDescriptor: CInt, opcode: (commandField: UInt16, groupField: UInt16), commandParameterData: [UInt8] = [], event: UInt8 = 0, timeout: Int = 0) throws -> [UInt8] {
    
    // assertions
    assert(timeout >= 0, "Negative timeout value")
    assert(timeout <= Int(Int32.max), "Timeout > Int32.max")
    
    // initialize variables
    var timeout = timeout
    let opcodePacked = HCICommandOpcodePack(opcode.commandField, opcode.groupField).littleEndian
    var eventBuffer = [UInt8](count: HCI.MaximumEventSize, repeatedValue: 0)
    var oldFilter = HCIFilter()
    var newFilter = HCIFilter()
    let oldFilterPointer = withUnsafeMutablePointer(&oldFilter) { UnsafeMutablePointer<Void>($0) }
    let newFilterPointer = withUnsafeMutablePointer(&oldFilter) { UnsafeMutablePointer<Void>($0) }
    var filterLength = socklen_t(sizeof(HCIFilter))
    
    // get old filter
    guard getsockopt(deviceDescriptor, SOL_HCI, HCISocketOption.Filter.rawValue, oldFilterPointer, &filterLength) == 0
        else { throw POSIXError.fromErrorNumber! }
    
    // configure new filter
    newFilter.setPacketType(.Event)
    newFilter.setEvent(HCIGeneralEvent.CommandStatus.rawValue)
    newFilter.setEvent(HCIGeneralEvent.CommandComplete.rawValue)
    newFilter.setEvent(HCIGeneralEvent.LowEnergyMeta.rawValue)
    newFilter.setEvent(event)
    newFilter.opcode = opcodePacked
    
    // set new filter
    guard setsockopt(deviceDescriptor, SOL_HCI, HCISocketOption.Filter.rawValue, newFilterPointer, filterLength) == 0
        else { throw POSIXError.fromErrorNumber! }
    
    // restore old filter in case of error
    func restoreFilter(error: ErrorType) -> ErrorType {
        
        guard setsockopt(deviceDescriptor, SOL_HCI, HCISocketOption.Filter.rawValue, newFilterPointer, filterLength) == 0
            else { return AdapterError.CouldNotRestoreFilter(error, POSIXError.fromErrorNumber!) }
        
        return error
    }
    
    // send command
    do { try HCISendCommand(deviceDescriptor, opcode: opcode, parameterData: commandParameterData) }
    catch { throw restoreFilter(error) }
    
    // retrieve data...
    
    var attempts = 10
    
    while attempts > 0 {
        
        // decrement attempts
        attempts -= 1
        
        // wait for timeout
        if timeout > 0 {
            
            var timeoutPoll = pollfd(fd: deviceDescriptor, events: Int16(POLLIN), revents: 0)
            var pollStatus: CInt = 0
            
            func doPoll() { pollStatus = poll(&timeoutPoll, 1, CInt(timeout)) }
            
            doPoll()
            
            while pollStatus < 0 {
                
                // ignore these errors
                if (errno == EAGAIN || errno == EINTR) {
                    
                    // try again
                    doPoll()
                    continue
                    
                } else {
                    
                    // attempt to restore filter and throw
                    throw restoreFilter(POSIXError.fromErrorNumber!)
                }
            }
            
            // poll timed out
            guard pollStatus != 0
                else { throw restoreFilter(POSIXError(rawValue: ETIMEDOUT)!) }
            
            // decrement timeout (why?)
            timeout -= 10
            
            // make sure its not a negative number
            if timeout < 0 {
                
                timeout = 0
            }
        }
        
        var actualBytesRead = 0
        
        func doRead() { actualBytesRead = read(deviceDescriptor, &eventBuffer, eventBuffer.count) }
        
        doRead()
        
        while actualBytesRead < 0 {
            
            // ignore these errors
            if (errno == EAGAIN || errno == EINTR) {
                
                // try again
                doRead()
                continue
                
            } else {
                
                // attempt to restore filter and throw
                throw restoreFilter(POSIXError.fromErrorNumber!)
            }
        }
        
        let headerData = Array(eventBuffer[1 ..< HCIEventHeader.length])
        let eventData = Array(eventBuffer[(1 + HCIEventHeader.length) ..< actualBytesRead])
        //var length = actualBytesRead - (1 + HCIEventHeader.length)
        
        guard let eventHeader = HCIEventHeader(byteValue: headerData)
            else { throw restoreFilter(AdapterError.GarbageResponse(Data(byteValue: eventBuffer))) }
        
        func done() throws {
            
            guard setsockopt(deviceDescriptor, SOL_HCI, HCISocketOption.Filter.rawValue, newFilterPointer, filterLength) == 0
                else { throw POSIXError.fromErrorNumber! }
        }
        
        switch eventHeader.event {
            
        case HCIGeneralEvent.CommandStatus.rawValue:
            
            guard let parameter = HCIGeneralEvent.CommandStatusParameter(byteValue: eventData)
                else { throw AdapterError.GarbageResponse(Data(byteValue: eventBuffer)) }
            
            guard parameter.opcode == opcodePacked else { continue }
            
            guard event == HCIGeneralEvent.CommandStatus.rawValue else {
                
                guard parameter.status == 0
                    else { throw restoreFilter(POSIXError(rawValue: EIO)!) }
                
                break
            }
            
            // success!
            try done()
            return eventData
            
        case HCIGeneralEvent.CommandComplete.rawValue:
            
            guard let parameter = HCIGeneralEvent.CommandCompleteParameter(byteValue: eventData)
                else { throw AdapterError.GarbageResponse(Data(byteValue: eventBuffer)) }
            
            guard parameter.opcode == opcodePacked else { continue }
            
            
            
            // success!
            try done()
            return eventData
            
        // all other events
        default:
            
            
            
            try done()
            return eventData
        }
    }
    
    // throw timeout error
    throw POSIXError(rawValue: ETIMEDOUT)!
}

// MARK: - Internal Constants

let SOL_HCI: CInt = 0


