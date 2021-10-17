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

internal extension FileDescriptor {
    
    func sendCommand<Command: HCICommand>(
        _ command: Command,
        parameter parameterData: Data = Data()
    ) throws {
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
        try writeAll(data)
    }
    
    /// Returns event parameter data.
    func sendRequest <Command: HCICommand> (
        command: Command,
        commandParameterData: Data = Data(),
        event: UInt8 = 0,
        eventParameterLength: Int = 0,
        timeout: HCICommandTimeout = .default
    ) throws -> Data {
        
        // initialize variables
        var timeout = timeout.rawValue
        let opcodePacked = command.opcode.littleEndian
        var eventBuffer = [UInt8](repeating: 0, count: HCI.maximumEventSize)
        
        // get old filter
        let oldFilter = try getSocketOption(HCISocketOption.Filter.self)
        
        // configure new filter
        var newFilter = HCISocketOption.Filter()
        newFilter.typeMask = 16
        //newFilter.setPacketType(.Event)
        newFilter.setEvent(HCIGeneralEvent.commandStatus)
        newFilter.setEvent(HCIGeneralEvent.commandComplete)
        newFilter.setEvent(HCIGeneralEvent.lowEnergyMeta)
        newFilter.bytes.setEvent(event)
        newFilter.opcode = opcodePacked
        
        // set new filter
        try setSocketOption(newFilter)

        // restore old filter in case of error
        func restoreFilter(_ failure: Swift.Error) -> Error {
            do { try setSocketOption(oldFilter) }
            catch {
                return BluetoothHostControllerError.couldNotRestoreFilter(failure, error)
            }
            return failure
        }

        // send command
        do { try sendCommand(command, parameter: commandParameterData) }
        catch { throw restoreFilter(error) }

        // retrieve data...

        var attempts = 10

        while attempts > 0 {

            // decrement attempts
            attempts -= 1
            
            // wait for timeout
            if timeout > 0 {
                var pollStatus: FileEvents = []
                while pollStatus.contains(.read) == false {
                    // check for data
                    do { pollStatus = try poll(for: [.read], timeout: Int(timeout)) }
                    // ignore these errors
                    catch Errno.resourceTemporarilyUnavailable {
                        continue
                    }
                    catch Errno.interrupted {
                        continue
                    }
                    catch {
                        // attempt to restore filter and throw
                        throw restoreFilter(error)
                    }
                }
                
                // poll timed out
                guard pollStatus.contains(.read)
                else { throw restoreFilter(Errno.timedOut) }
                
                // decrement timeout (why?)
                timeout -= 10
            }
            
            var actualBytesRead = 0
            while actualBytesRead < 0 {
                do {
                    actualBytesRead = try eventBuffer.withUnsafeMutableBytes {
                        try read(into: $0)
                    }
                }
                // ignore these errors
                catch Errno.resourceTemporarilyUnavailable {
                    continue
                }
                catch Errno.interrupted {
                    continue
                }
                catch {
                    // attempt to restore filter and throw
                    throw restoreFilter(error)
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
                try setSocketOption(oldFilter)
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
        throw Errno.timedOut
    }
}
