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

public extension Adapter {
    
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
    }
}

// MARK: - Internal HCI Function

/// int hci_send_cmd(int dd, uint16_t ogf, uint16_t ocf, uint8_t plen, void *param)
internal func HCISendCommand(deviceDescriptor: CInt, opcode: (commandField: UInt16, groupField: UInt16), parameterData: [UInt8] = []) throws {
    
    let packetType = HCIPacketType.Command.rawValue
    
    var header = HCICommandHeader()
    
    header.opcode = HCICommandOpcodePack(opcode.commandField, opcode.groupField).littleEndian
    
    header.parameterLength = UInt8(parameterData.count)
    
    /// data sent to host controller interface
    var data = [packetType] + header.byteValue + parameterData
    
    // write to device descriptor socket
    guard write(deviceDescriptor, &data, data.count) >= 0 // should we check if all data was written?
        else { throw POSIXError.fromErrorNumber! }
}

@inline(__always)
internal func HCICommandOpcodePack(commandField: UInt16, _ groupField: UInt16) -> UInt16 {
    
    return (commandField & 0x03ff) | (groupField << 10)
}
