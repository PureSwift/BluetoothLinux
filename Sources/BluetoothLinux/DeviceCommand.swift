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

import SwiftFoundation

public extension Adapter {
    
    func deviceCommand<T: HCICommand>(command: T) throws {
        
        try HCISendCommand(internalSocket, opcode: (command.rawValue, T.opcodeGroupField.rawValue))
    }
    
    func deviceCommand<T: HCICommandParameter>(commandParameter: T) throws {
        
        let command = T.command
        
        let opcodeGroupField = command.dynamicType.opcodeGroupField
        
        let parameterData = commandParameter.byteValue
        
        try HCISendCommand(internalSocket, opcode: (command.rawValue, opcodeGroupField.rawValue), parameterData: parameterData)
    }
}

// MARK: - Internal HCI Function

internal func HCISendCommand(deviceDescriptor: CInt, opcode: (commandField: UInt16, groupField: UInt16), parameterData: [UInt8] = []) throws {
    
    let packetType = HCIPacketType.Command.rawValue
    
    var header = HCICommandHeader()
    header.opcode = HCICommandOpcodePack(opcode.commandField, opcode.groupField).littleEndian
    header.parameterLength = UInt8(parameterData.count)
    
    /// data sent to host controller interface...
    
    // build iovec
    var ioVectors = [iovec](count: 2, repeatedValue: iovec())
    
    ioVectors[0] = iovec(byteValue: [packetType])
    ioVectors[1] = iovec(byteValue: header.byteValue)
    
    if parameterData.isEmpty == false {
        
        ioVectors.append(iovec(byteValue: parameterData))
    }
    
    // free memory
    defer { for index in 0 ..< ioVectors.count { ioVectors[index].dealloc() } }
    
    // write to device descriptor socket
    while writev(deviceDescriptor, &ioVectors, CInt(ioVectors.count)) < 0 {
        
        guard (errno == EAGAIN || errno == EINTR)
            else { throw POSIXError.fromErrorNumber! }
    }
}

@inline(__always)
internal func HCICommandOpcodePack(commandField: UInt16, _ groupField: UInt16) -> UInt16 {
    
    return (commandField & 0x03ff) | (groupField << 10)
}
