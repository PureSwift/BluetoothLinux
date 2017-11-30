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

import Foundation
import Bluetooth

public extension Adapter {

    /// Sends a command to the device and waits for a response.
    /*
    @inline(__always)
    func deviceRequest<CP: HCICommandParameter, EP: HCIEventParameter>(commandParameter: CP, eventParameterType: EP.Type, timeout: Int = 1000) throws -> EP {

        let command = CP.command

        let opcodeGroupField = command.dynamicType.opcodeGroupField

        let parameterData = commandParameter.bytes

        let data = try HCISendRequest(internalSocket, opcode: (command.rawValue, opcodeGroupField.rawValue), commandParameterData: parameterData, eventParameterLength: EP.length, event: EP.event.rawValue, timeout: timeout)

        guard let eventParameter = EP(bytes: data)
            else { throw AdapterError.GarbageResponse(Data(bytes: data)) }

        return eventParameter
    }

    @inline(__always)
    func deviceRequest<C: HCICommand, EP: HCIEventParameter>(command: C, eventParameterType: EP.Type, timeout: Int = 1000) throws -> EP {

        let opcode = (command.rawValue, C.opcodeGroupField.rawValue)

        let event = EP.event.rawValue

        let data = try HCISendRequest(internalSocket, opcode: opcode, event: event, eventParameterLength: EP.length, timeout: timeout)

        guard let eventParameter = EP(bytes: data)
            else { throw AdapterError.GarbageResponse(Data(bytes: data)) }

        return eventParameter
    }

    @inline(__always)
    func deviceRequest<CP: HCICommandParameter, E: HCIEvent>(commandParameter: CP, event: E, verifyStatusByte: Bool = true, timeout: Int = 1000) throws {

        let command = CP.command

        let opcode = (command.rawValue, command.dynamicType.opcodeGroupField.rawValue)

        let parameterData = commandParameter.bytes

        let eventParameterLength = verifyStatusByte ? 1 : 0

        let data = try HCISendRequest(internalSocket, opcode: opcode, commandParameterData: parameterData, event: event.rawValue, eventParameterLength: eventParameterLength, timeout: timeout)

        if verifyStatusByte {

            guard let statusByte = data.first
                else { fatalError("Missing status byte!") }

            guard statusByte == 0x00
                else { throw AdapterError.DeviceRequestStatus(statusByte) }
        }
    }

    @inline(__always)
    func deviceRequest<C: HCICommand, E: HCIEvent>(command: C, event: E, verifyStatusByte: Bool = true, timeout: Int = 1000) throws {

        let opcode = (command.rawValue, C.opcodeGroupField.rawValue)

        let eventParameterLength = verifyStatusByte ? 1 : 0

        let data = try HCISendRequest(internalSocket, opcode: opcode, event: event.rawValue, eventParameterLength: eventParameterLength, timeout: timeout)

        if verifyStatusByte {

            guard let statusByte = data.first
                else { fatalError("Missing status byte!") }

            guard statusByte == 0x00
                else { throw AdapterError.DeviceRequestStatus(statusByte) }
        }
    }
 
    */
    
    /// Send a command to the controller and wait for response. 
    func deviceRequest<C: HCICommand>(_ command: C, timeout: Int = 1000) throws {

        let opcode = (command.rawValue, C.opcodeGroupField.rawValue)

        let data = try HCISendRequest(internalSocket,
                                      opcode: opcode,
                                      eventParameterLength: 1,
                                      timeout: timeout)
        
        guard let statusByte = data.first
            else { fatalError("Missing status byte!") }
        
        guard statusByte == 0x00
            else { throw HCIError(rawValue: statusByte)! }
        
    }
    
    func deviceRequest<CP: HCICommandParameter>(_ commandParameter: CP, timeout: Int = 1000) throws {

        let opcode = (CP.command.rawValue, type(of: CP.command).opcodeGroupField.rawValue)

        let data = try HCISendRequest(internalSocket,
                                      opcode: opcode,
                                      commandParameterData: commandParameter.byteValue,
                                      eventParameterLength: 1,
                                      timeout: timeout)
        
        guard let statusByte = data.first
            else { fatalError("Missing status byte!") }
        
        guard statusByte == 0x00
            else { throw HCIError(rawValue: statusByte)! }
    }
    
    func deviceRequest <Return: HCICommandReturnParameter> (_ commandReturnType : Return.Type, timeout: Int = 1000) throws -> Return {
        
        let opcode = (Return.command.rawValue, Return.HCICommandType.opcodeGroupField.rawValue)
        
        let data = try HCISendRequest(internalSocket,
                                      opcode: opcode,
                                      eventParameterLength: commandReturnType.length + 1, // status code + parameters
                                      timeout: timeout)
        
        guard let statusByte = data.first
            else { fatalError("Missing status byte!") }
        
        guard statusByte == 0x00
            else { throw HCIError(rawValue: statusByte)! }
        
        guard let response = Return(byteValue: Array(data.suffix(from: 1)))
            else { throw AdapterError.garbageResponse(Data(data)) }
        
        return response
    }
}

// MARK: - Internal HCI Functions

/// Returns event parameter data.
internal func HCISendRequest(_ deviceDescriptor: CInt,
                             opcode: (commandField: UInt16, groupField: UInt16),
                             commandParameterData: [UInt8] = [],
                             event: UInt8 = 0,
                             eventParameterLength: Int = 0,
                             timeout: Int = 1000) throws -> [UInt8] {

    // assertions
    assert(timeout >= 0, "Negative timeout value")
    assert(timeout <= Int(Int32.max), "Timeout > Int32.max")

    // initialize variables
    var timeout = timeout
    let opcodePacked = HCICommandOpcodePack(opcode.commandField, opcode.groupField).littleEndian
    var eventBuffer = [UInt8](repeating: 0, count: HCI.maximumEventSize)
    var oldFilter = HCIFilter()
    var newFilter = HCIFilter()
    let oldFilterPointer = withUnsafeMutablePointer(to: &oldFilter) { UnsafeMutableRawPointer($0) }
    let newFilterPointer = withUnsafeMutablePointer(to: &newFilter) { UnsafeMutableRawPointer($0) }
    var filterLength = socklen_t(MemoryLayout<HCIFilter>.size)

    // get old filter
    guard getsockopt(deviceDescriptor, SOL_HCI, HCISocketOption.Filter.rawValue, oldFilterPointer, &filterLength) == 0
        else { throw POSIXError.fromErrno! }
    
    // configure new filter
    newFilter.clear()
    newFilter.typeMask = 16
    //newFilter.setPacketType(.Event)
    newFilter.setEvent(HCIGeneralEvent.CommandStatus.rawValue)
    newFilter.setEvent(HCIGeneralEvent.CommandComplete.rawValue)
    newFilter.setEvent(HCIGeneralEvent.LowEnergyMeta.rawValue)
    newFilter.setEvent(event)
    //newFilter.setEvent(HCIGeneralEvent.CommandStatus.rawValue, HCIGeneralEvent.CommandComplete.rawValue, HCIGeneralEvent.LowEnergyMeta.rawValue, event)
    newFilter.opcode = opcodePacked
    
    // set new filter
    guard setsockopt(deviceDescriptor, SOL_HCI, HCISocketOption.Filter.rawValue, newFilterPointer, filterLength) == 0
        else { throw POSIXError.fromErrno! }

    // restore old filter in case of error
    func restoreFilter(_ error: Error) -> Error {

        guard setsockopt(deviceDescriptor, SOL_HCI, HCISocketOption.Filter.rawValue, oldFilterPointer, filterLength) == 0
            else { return AdapterError.couldNotRestoreFilter(error, POSIXError.fromErrno!) }

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
                    throw restoreFilter(POSIXError.fromErrno!)
                }
            }
            
            // poll timed out
            guard pollStatus != 0
                else { throw restoreFilter(POSIXError(code: .ETIMEDOUT)) }

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
                throw restoreFilter(POSIXError.fromErrno!)
            }
        }
        
        let headerData = Array(eventBuffer[1 ..< 1 + HCIEventHeader.length])
        let eventData = Array(eventBuffer[(1 + HCIEventHeader.length) ..< actualBytesRead])
        //var length = actualBytesRead - (1 + HCIEventHeader.length)

        guard let eventHeader = HCIEventHeader(bytes: headerData)
            else { throw restoreFilter(AdapterError.garbageResponse(Data(bytes: headerData))) }
        
        //print("Event header data: \(headerData)")
        //print("Event header: \(eventHeader)")
        //print("Event data: \(eventData)")

        /// restores the old filter option before exiting
        func done() throws {

            guard setsockopt(deviceDescriptor, SOL_HCI, HCISocketOption.Filter.rawValue, oldFilterPointer, filterLength) == 0
                else { throw POSIXError.fromErrno! }
        }

        switch eventHeader.event {

        case HCIGeneralEvent.CommandStatus.rawValue:
            
            let parameterData = Array(eventData.prefix(min(eventData.count, HCIGeneralEvent.CommandStatusParameter.length)))
            
            guard let parameter = HCIGeneralEvent.CommandStatusParameter(byteValue: parameterData)
                else { throw AdapterError.garbageResponse(Data(bytes: parameterData)) }

            /// must be command status for sent command
            guard parameter.opcode == opcodePacked else { continue }

            ///
            guard event == HCIGeneralEvent.CommandStatus.rawValue else {

                guard parameter.status == 0
                    else { throw restoreFilter(POSIXError(code: .EIO)) }

                break
            }

            // success!
            try done()
            let dataLength = min(eventData.count, eventParameterLength)
            return Array(eventData.suffix(dataLength))

        case HCIGeneralEvent.CommandComplete.rawValue:
            
            let parameterData = Array(eventData.prefix(min(eventData.count, HCIGeneralEvent.CommandCompleteParameter.length)))

            guard let parameter = HCIGeneralEvent.CommandCompleteParameter(byteValue: parameterData)
                else { throw AdapterError.garbageResponse(Data(bytes: parameterData)) }
            
            guard parameter.opcode == opcodePacked else { continue }

            // success!
            try done()
            
            let commandParameterLength = HCIGeneralEvent.CommandCompleteParameter.length
            let data = eventData.suffix(commandParameterLength)
            
            let dataLength = min(data.count, eventParameterLength)
            return Array(data.suffix(dataLength))

        case HCIGeneralEvent.RemoteNameRequestComplete.rawValue:

            guard eventHeader.event == event else { break }
            
            let parameterData = Array(eventData.prefix(min(eventData.count, HCIGeneralEvent.RemoteNameRequestCompleteParameter.length)))

            guard let parameter = HCIGeneralEvent.RemoteNameRequestCompleteParameter(byteValue: parameterData)
                else { throw AdapterError.garbageResponse(Data(bytes: parameterData)) }

            if commandParameterData.isEmpty == false {

                guard let commandParameter = LinkControlCommand.RemoteNameRequestParameter(byteValue: commandParameterData)
                    else { fatalError("HCI Command 'RemoteNameRequest' was sent, but the event parameter data does not correspond to 'RemoteNameRequestParameter'") }

                // must be different, for some reason
                guard commandParameter.address != parameter.address else { continue }
            }

            // success!
            try done()
            let dataLength = min(eventData.count - 1, eventParameterLength)
            return Array(eventData.suffix(dataLength))
            
        case HCIGeneralEvent.LowEnergyMeta.rawValue:
            
            let parameterData = Array(eventData.prefix(min(eventData.count, HCIGeneralEvent.LowEnergyMetaParameter.length)))
            
            guard let metaParameter = HCIGeneralEvent.LowEnergyMetaParameter(byteValue: parameterData)
                else { throw AdapterError.garbageResponse(Data(bytes: parameterData)) }
            
            // LE event should match
            guard metaParameter.subevent == event
                else { continue }
            
            // success!
            try done()
            //let dataLength = min(eventData.count - 1, eventParameterLength)
            //return Array(eventData.suffix(dataLength))
            return metaParameter.data

        // all other events
        default:

            guard eventHeader.event == event else { break }

            try done()
            let dataLength = min(eventData.count, eventParameterLength)
            return Array(eventData.suffix(dataLength))
        }
    }

    // throw timeout error
    throw POSIXError(code: .ETIMEDOUT)
}

// MARK: - Internal Constants

let SOL_HCI: CInt = 0
