//
//  DeviceCommand.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 3/2/16.
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
    
    func deviceCommand<T: HCICommand>(_ command: T) throws {
        
        try HCISendCommand(internalSocket, opcode: (command.rawValue, T.opcodeGroupField.rawValue))
    }
    
    func deviceCommand<T: HCICommandParameter>(_ commandParameter: T) throws {
        
        let command = T.command
        
        let opcodeGroupField = type(of: command).opcodeGroupField
        
        let parameterData = commandParameter.byteValue
        
        try HCISendCommand(internalSocket, opcode: (command.rawValue, opcodeGroupField.rawValue), parameterData: parameterData)
    }
}

// MARK: - Internal HCI Function

internal func HCISendCommand(_ deviceDescriptor: CInt,
                             opcode: (commandField: UInt16, groupField: UInt16),
                             parameterData: [UInt8] = []) throws {
    
    let packetType = HCIPacketType.Command.rawValue
    
    var header = HCICommandHeader()
    
    header.opcode = HCICommandOpcodePack(opcode.commandField, opcode.groupField).littleEndian
    
    header.parameterLength = UInt8(parameterData.count)
    
    /// data sent to host controller interface
    var data = [packetType] + header.byteValue + parameterData
    
    // write to device descriptor socket
    guard write(deviceDescriptor, &data, data.count) >= 0 // should we check if all data was written?
        else { throw POSIXError.fromErrno! }
}

/// TODO: Remove
@inline(__always)
internal func HCICommandOpcodePack(_ commandField: UInt16, _ groupField: UInt16) -> UInt16 {
    
    return (commandField & 0x03ff) | (groupField << 10)
}
