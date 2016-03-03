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
    
    func deviceCommand<T: HCICommand>(command: T) {
        
        
    }
    
    func deviceCommand<T: HCICommandParameter>(commandParameter: T) {
        
        
        
    }
}

// MARK: - Internal HCI Function

internal func HCISendCommand(deviceDescriptor: CInt, opcode: (groupField: UInt16, commandField: UInt16), parameterData: [UInt8] = []) {
    
    let type = HCIPacketType.Command.rawValue
    
    var hciCommand = HCICommandHDR()
    
    
}