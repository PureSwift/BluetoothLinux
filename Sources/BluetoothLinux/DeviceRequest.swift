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

public extension HostController {

    /// Send an HCI command with parameters to the controller and waits for a response.
    func deviceRequest<CP: HCICommandParameter, EP: HCIEventParameter> (_ commandParameter: CP, _ eventParameterType: EP.Type, timeout: HCICommandTimeout = .default) throws -> EP {
        
        let command = CP.command

        let parameterData = commandParameter.data
        
        let data = try HCISendRequest(internalSocket,
                                      command: command,
                                      commandParameterData: parameterData,
                                      event: EP.event.rawValue,
                                      eventParameterLength: EP.length,
                                      timeout: timeout)
        
        guard let eventParameter = EP(data: data)
            else { throw BluetoothHostControllerError.garbageResponse(data) }
        
        return eventParameter
    }
    
    /// Send an HCI command to the controller and waits for a response.
    public func deviceRequest<C, EP>(_ command: C, _ eventParameterType: EP.Type, timeout: HCICommandTimeout) throws -> EP where C : HCICommand, EP : HCIEventParameter {
        
        let data = try HCISendRequest(internalSocket,
                                      command: command,
                                      event: EP.event.rawValue,
                                      eventParameterLength: EP.length,
                                      timeout: timeout)
        
        guard let eventParameter = EP(data: data)
            else { throw BluetoothHostControllerError.garbageResponse(data) }
        
        return eventParameter
    }
    
    /*
    @inline(__always)
    func deviceRequest<C: HCICommand, EP: HCIEventParameter>(command: C, eventParameterType: EP.Type, timeout: HCICommandTimeout = .default) throws -> EP {

        let opcode = (command.rawValue, C.opcodeGroupField.rawValue)

        let event = EP.event.rawValue

        let data = try HCISendRequest(internalSocket, opcode: opcode, event: event, eventParameterLength: EP.length, timeout: timeout)

        guard let eventParameter = EP(bytes: data)
            else { throw BluetoothHostControllerError.GarbageResponse(Data(bytes: data)) }

        return eventParameter
    }

    @inline(__always)
    func deviceRequest<CP: HCICommandParameter, E: HCIEvent>(commandParameter: CP, event: E, verifyStatusByte: Bool = true, timeout: HCICommandTimeout = .default) throws {

        let command = CP.command

        let opcode = (command.rawValue, command.dynamicType.opcodeGroupField.rawValue)

        let parameterData = commandParameter.bytes

        let eventParameterLength = verifyStatusByte ? 1 : 0

        let data = try HCISendRequest(internalSocket, opcode: opcode, commandParameterData: parameterData, event: event.rawValue, eventParameterLength: eventParameterLength, timeout: timeout)

        if verifyStatusByte {

            guard let statusByte = data.first
                else { fatalError("Missing status byte!") }

            guard statusByte == 0x00
                else { throw BluetoothHostControllerError.DeviceRequestStatus(statusByte) }
        }
    }

    @inline(__always)
    func deviceRequest<C: HCICommand, E: HCIEvent>(command: C, event: E, verifyStatusByte: Bool = true, timeout: HCICommandTimeout = .default) throws {

        let opcode = (command.rawValue, C.opcodeGroupField.rawValue)

        let eventParameterLength = verifyStatusByte ? 1 : 0

        let data = try HCISendRequest(internalSocket, opcode: opcode, event: event.rawValue, eventParameterLength: eventParameterLength, timeout: timeout)

        if verifyStatusByte {

            guard let statusByte = data.first
                else { fatalError("Missing status byte!") }

            guard statusByte == 0x00
                else { throw BluetoothHostControllerError.DeviceRequestStatus(statusByte) }
        }
    }
 
    */
    
    /// Send a command to the controller and wait for response. 
    func deviceRequest<C: HCICommand>(_ command: C, timeout: HCICommandTimeout = .default) throws {

        let data = try HCISendRequest(internalSocket,
                                      command: command,
                                      eventParameterLength: 1,
                                      timeout: timeout)
        
        guard let statusByte = data.first
            else { fatalError("Missing status byte!") }
        
        guard statusByte == 0x00
            else { throw HCIError(rawValue: statusByte)! }
        
    }
    
    func deviceRequest<CP: HCICommandParameter>(_ commandParameter: CP, timeout: HCICommandTimeout = .default) throws {
        
        let data = try HCISendRequest(internalSocket,
                                      command: CP.command,
                                      commandParameterData: commandParameter.data,
                                      eventParameterLength: 1,
                                      timeout: timeout)
        
        guard let statusByte = data.first
            else { fatalError("Missing status byte!") }
        
        guard statusByte == 0x00
            else { throw HCIError(rawValue: statusByte)! }
    }
    
    func deviceRequest <Return: HCICommandReturnParameter> (_ commandReturnType : Return.Type, timeout: HCICommandTimeout = .default) throws -> Return {
        
        let data = try HCISendRequest(internalSocket,
                                      command: commandReturnType.command,
                                      eventParameterLength: commandReturnType.length + 1, // status code + parameters
                                      timeout: timeout)
        
        guard let statusByte = data.first
            else { fatalError("Missing status byte!") }
        
        guard statusByte == 0x00
            else { throw HCIError(rawValue: statusByte)! }
        
        guard let response = Return(data: Data(data.suffix(from: 1)))
            else { throw BluetoothHostControllerError.garbageResponse(Data(data)) }
        
        return response
    }
    
    /// Sends a command to the device and waits for a response with return parameter values.
    func deviceRequest <CP: HCICommandParameter, Return: HCICommandReturnParameter> (_ commandParameter: CP, _ commandReturnType : Return.Type, timeout: HCICommandTimeout = .default) throws -> Return {
        
        assert(CP.command.opcode == Return.command.opcode)
        
        let data = try HCISendRequest(internalSocket,
                                      command: commandReturnType.command,
                                      commandParameterData: commandParameter.data,
                                      eventParameterLength: commandReturnType.length + 1,
                                      timeout: timeout)
        
        guard let statusByte = data.first
            else { fatalError("Missing status byte!") }
        
        guard statusByte == 0x00
            else { throw HCIError(rawValue: statusByte)! }
        
        guard let response = Return(data: Data(data.suffix(from: 1)))
            else { throw BluetoothHostControllerError.garbageResponse(Data(data)) }
        
        return response
    }
}

// MARK: - Internal HCI Functions

/// Returns event parameter data.
internal func HCISendRequest <Command: HCICommand> (_ deviceDescriptor: CInt,
                             command: Command,
                             commandParameterData: Data = Data(),
                             event: UInt8 = 0,
                             eventParameterLength: Int = 0,
                             timeout: HCICommandTimeout = .default) throws -> Data {
    
    // initialize variables
    var timeout = timeout.rawValue
    let opcodePacked = command.opcode.littleEndian
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
    newFilter.setEvent(HCIGeneralEvent.commandStatus.rawValue)
    newFilter.setEvent(HCIGeneralEvent.commandComplete.rawValue)
    newFilter.setEvent(HCIGeneralEvent.lowEnergyMeta.rawValue)
    newFilter.setEvent(event)
    newFilter.opcode = opcodePacked
    
    // set new filter
    guard setsockopt(deviceDescriptor, SOL_HCI, HCISocketOption.Filter.rawValue, newFilterPointer, filterLength) == 0
        else { throw POSIXError.fromErrno! }

    // restore old filter in case of error
    func restoreFilter(_ error: Error) -> Error {

        guard setsockopt(deviceDescriptor, SOL_HCI, HCISocketOption.Filter.rawValue, oldFilterPointer, filterLength) == 0
            else { return BluetoothHostControllerError.couldNotRestoreFilter(error, POSIXError.fromErrno!) }

        return error
    }

    // send command
    do { try HCISendCommand(deviceDescriptor, command: command, parameterData: commandParameterData) }
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
        
        let headerData = Data(eventBuffer[1 ..< 1 + HCIEventHeader.length])
        let eventData = Data(eventBuffer[(1 + HCIEventHeader.length) ..< actualBytesRead])
        //var length = actualBytesRead - (1 + HCIEventHeader.length)

        guard let eventHeader = HCIEventHeader(data: headerData)
            else { throw restoreFilter(BluetoothHostControllerError.garbageResponse(headerData)) }
        
        //print("Event header data: \(headerData)")
        //print("Event header: \(eventHeader)")
        //print("Event data: \(eventData)")

        /// restores the old filter option before exiting
        func done() throws {

            guard setsockopt(deviceDescriptor, SOL_HCI, HCISocketOption.Filter.rawValue, oldFilterPointer, filterLength) == 0
                else { throw POSIXError.fromErrno! }
        }

        switch eventHeader.event {

        case .commandStatus:
            
            let parameterData = Data(eventData.prefix(min(eventData.count, HCICommandStatus.length)))
            
            guard let parameter = HCICommandStatus(data: parameterData)
                else { throw BluetoothHostControllerError.garbageResponse(parameterData) }

            /// must be command status for sent command
            guard parameter.opcode == opcodePacked else { continue }

            ///
            guard event == HCIGeneralEvent.commandStatus.rawValue else {
                
                switch parameter.status {
                    
                case let .error(error):
                    throw error
                    
                case .success:
                    break
                }
                
                break
            }

            // success!
            try done()
            let dataLength = min(eventData.count, eventParameterLength)
            return Data(eventData.suffix(dataLength))

        case .commandComplete:
            
            let parameterData = Data(eventData.prefix(min(eventData.count, HCICommandComplete.length)))

            guard let parameter = HCICommandComplete(data: parameterData)
                else { throw BluetoothHostControllerError.garbageResponse(parameterData) }
            
            guard parameter.opcode == opcodePacked else { continue }

            // success!
            try done()
            
            let commandCompleteParameterLength = HCICommandComplete.length
            let data = eventData.suffix(eventParameterLength)
            
            let dataLength = max(data.count, commandCompleteParameterLength)
            return Data(data.suffix(dataLength))

        case .remoteNameRequestComplete:

            guard eventHeader.event.rawValue == event else { break }
            
            let parameterData = Data(eventData.prefix(min(eventData.count, HCIRemoteNameRequestComplete.length)))

            guard let parameter = HCIRemoteNameRequestComplete(data: parameterData)
                else { throw BluetoothHostControllerError.garbageResponse(parameterData) }

            if commandParameterData.isEmpty == false {

                guard let commandParameter = HCIRemoteNameRequest(data: commandParameterData)
                    else { fatalError("HCI Command 'RemoteNameRequest' was sent, but the event parameter data does not correspond to 'RemoteNameRequestParameter'") }
                
                // must be different, for some reason
                guard commandParameter.address == parameter.address else { continue }
            }

            // success!
            try done()
            let dataLength = min(eventData.count, eventParameterLength)
            return Data(eventData.suffix(dataLength))
            
        case .lowEnergyMeta:
            
            let parameterData = eventData
            
            guard let metaParameter = HCILowEnergyMetaEvent(data: parameterData)
                else { throw BluetoothHostControllerError.garbageResponse(parameterData) }
            
            // LE event should match
            guard metaParameter.subevent.rawValue == event
                else { continue }
            
            // success!
            try done()
            return metaParameter.eventData

        // all other events
        default:

            guard eventHeader.event.rawValue == event else { break }

            try done()
            let dataLength = min(eventData.count, eventParameterLength)
            return Data(eventData.suffix(dataLength))
        }
    }

    // throw timeout error
    throw POSIXError(code: .ETIMEDOUT)
}

// MARK: - Internal Constants

let SOL_HCI: CInt = 0
