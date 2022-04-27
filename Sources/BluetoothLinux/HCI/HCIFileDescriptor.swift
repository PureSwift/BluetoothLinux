//
//  HCIFileDescriptor.swift
//  
//
//  Created by Alsey Coleman Miller on 16/10/21.
//

import Foundation
import Bluetooth
import BluetoothHCI
import SystemPackage
import Socket

internal extension Socket {
    
    /// Sends an HCI command without waiting for an event.
    @usableFromInline
    func sendCommand<Command: HCICommand>(
        _ command: Command,
        parameter parameterData: Data = Data()
    ) async throws {
        // build data buffer to write
        assert(parameterData.count <= UInt8.max)
        let header = HCICommandHeader(
            command: command,
            parameterLength: UInt8(parameterData.count)
        )
        let dataLength = 1 + HCICommandHeader.length + parameterData.count
        var data = Data(capacity: dataLength)
        data.append(HCIPacketType.command.rawValue)
        data.append(header.data)
        if parameterData.isEmpty == false {
            data.append(parameterData)
        }
        assert(data.count == dataLength)
        // write data to socket
        try await write(data)
    }
    
    /// Sends an HCI command and waits for expected event parameter data.
    @usableFromInline
    func sendRequest <Command: HCICommand> (
        command: Command,
        commandParameterData: Data = Data(),
        event: UInt8 = 0,
        eventParameterLength: Int = 0,
        timeout: HCICommandTimeout = .default
    ) async throws -> Data {
        
        // initialize variables
        let opcodePacked = command.opcode.littleEndian
        
        // configure new filter
        var newFilter = HCISocketOption.Filter()
        newFilter.typeMask = 16
        //newFilter.setPacketType(.Event)
        newFilter.setEvent(HCIGeneralEvent.commandStatus)
        newFilter.setEvent(HCIGeneralEvent.commandComplete)
        newFilter.setEvent(HCIGeneralEvent.lowEnergyMeta)
        newFilter.bytes.setEvent(event)
        newFilter.opcode = opcodePacked
        
        return try await fileDescriptor.setFilter(newFilter) { () throws -> (Data) in
            
            // send command
            try await sendCommand(command, parameter: commandParameterData)

            // retrieve data...
            var attempts = 10
            while attempts > 0 {

                // decrement attempts
                attempts -= 1
                
                // attempt to read
                let eventBuffer = try await read(HCIEventHeader.maximumSize)
                assert(eventBuffer.isEmpty == false, "No HCI event read")
                let actualBytesRead = eventBuffer.count
                let headerData = Data(eventBuffer[1 ..< 1 + HCIEventHeader.length])
                let eventData = Data(eventBuffer[(1 + HCIEventHeader.length) ..< actualBytesRead])

                guard let eventHeader = HCIEventHeader(data: headerData)
                    else { throw BluetoothHostControllerError.garbageResponse(headerData) }

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
                    let dataLength = min(eventData.count, eventParameterLength)
                    return Data(eventData.suffix(dataLength))

                case .commandComplete:
                    
                    let parameterData = Data(eventData.prefix(min(eventData.count, HCICommandComplete.length)))

                    guard let parameter = HCICommandComplete(data: parameterData)
                        else { throw BluetoothHostControllerError.garbageResponse(parameterData) }
                    
                    guard parameter.opcode == opcodePacked else { continue }

                    // success!
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
                    return metaParameter.eventData

                // all other events
                default:

                    guard eventHeader.event.rawValue == event else { break }

                    let dataLength = min(eventData.count, eventParameterLength)
                    return Data(eventData.suffix(dataLength))
                }
            }

            // throw timeout error
            throw Errno.timedOut
        }
    }
}

internal extension SocketDescriptor {
    
    /// Creates an HCI socket binded to the specified address.
    @usableFromInline
    static func hci(
        _ address: HCISocketAddress,
        flags: SocketFlags = [.closeOnExec]
    ) throws -> SocketDescriptor {
        try bluetooth(
            .hci,
            bind: address,
            flags: flags
        )
    }
    
    func setFilter<R>(_ newFilter: HCISocketOption.Filter, _ body: () async throws -> (R)) async throws -> R {
        let oldFilter = try getSocketOption(HCISocketOption.Filter.self)
        try setSocketOption(newFilter)
        let result: R
        do { result = try await body() }
        catch let error {
            // restore filter
            do { try setSocketOption(oldFilter) }
            catch let restoreError {
                throw BluetoothHostControllerError.couldNotRestoreFilter(error, restoreError)
            }
            throw error
        }
        // restore filter on success
        try setSocketOption(oldFilter)
        return result
    }
}
