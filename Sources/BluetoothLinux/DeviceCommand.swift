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
import Bluetooth

public extension Adapter {
    
    func deviceCommand<T: HCICommand>(_ command: T) throws {
        
        try HCISendCommand(internalSocket, opcode: (command.rawValue, T.opcodeGroupField.rawValue))
    }
    
    func deviceCommand<T: HCICommandParameter>(_ commandParameter: T) throws {
        
        let command = T.command
        
        let opcodeGroupField = command.dynamicType.opcodeGroupField
        
        let parameterData = commandParameter.byteValue
        
        try HCISendCommand(internalSocket, opcode: (command.rawValue, opcodeGroupField.rawValue), parameterData: parameterData)
    }
}

// MARK: - Internal HCI Function

internal func HCISendCommand(_ deviceDescriptor: CInt, opcode: (commandField: UInt16, groupField: UInt16), parameterData: [UInt8] = []) throws {
    
    let packetType = HCIPacketType.Command.rawValue
    
    var header = HCICommandHeader()
    header.opcode = HCICommandOpcodePack(opcode.commandField, opcode.groupField).littleEndian
    header.parameterLength = UInt8(parameterData.count)
    
    /// data sent to host controller interface...
    
    // build iovec
    var ioVectors = [iovec](repeating: iovec(), count: 2)
    
    ioVectors[0] = iovec(byteValue: [packetType])
    ioVectors[1] = iovec(byteValue: header.byteValue)
    
    defer { ioVectors[0].iov_base.deallocateCapacity(ioVectors[0].iov_len) }
    defer { ioVectors[1].iov_base.deallocateCapacity(ioVectors[1].iov_len) }
    
    if parameterData.isEmpty == false {
        
        ioVectors.append(iovec(byteValue: parameterData))
        
        defer { ioVectors[2].iov_base.deallocateCapacity(ioVectors[2].iov_len) }
    }
    
    // write to device descriptor socket
    while writev(deviceDescriptor, &ioVectors, CInt(ioVectors.count)) < 0 {
        
        guard (errno == EAGAIN || errno == EINTR)
            else { throw POSIXError.fromErrorNumber! }
    }
}

@inline(__always)
internal func HCICommandOpcodePack(_ commandField: UInt16, _ groupField: UInt16) -> UInt16 {
    
    return (commandField & 0x03ff) | (groupField << 10)
}
