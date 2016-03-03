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
    
    func deviceCommand<T: HCICommand>(command: T) throws {
        
        try HCISendCommand(internalSocket, opcode: (T.opcodeGroupField.rawValue, command.rawValue))
    }
    
    func deviceCommand<T: HCICommandParameter>(commandParameter: T) throws {
        
        let command = T.command
        
        let opcodeGroupField = command.dynamicType.opcodeGroupField
        
        let parameterData = commandParameter.byteValue
        
        try HCISendCommand(internalSocket, opcode: (opcodeGroupField.rawValue, command.rawValue), parameterData: parameterData)
    }
}

// MARK: - Internal HCI Function

internal func HCISendCommand(deviceDescriptor: CInt, opcode: (groupField: UInt16, commandField: UInt16), parameterData: [UInt8] = []) throws {
    
    let type = HCIPacketType.Command.rawValue
    
    var hciCommand = HCICommandHDR()
    
    
    
}

@inline(__always)
internal func HCICommandOpcodePack(groupField: UInt16, _ commandField: UInt16) {
    
    
}