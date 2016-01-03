//
//  DeviceCommand.swift
//  BlueZ
//
//  Created by Alsey Coleman Miller on 1/2/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

#if os(Linux)
    import CBlueZ
#endif

import SwiftFoundation

public extension BluetoothAdapter {
    
    /// Sends a command to the device. 
    /// 
    /// - Note: Does not wait for a response.
    func deviceCommand<T: HCICommand>(command: T) -> Bool {
        
        var commandCopy = command
        
        return hci_send_cmd(socket, UInt16(T.opcodeGroupField), UInt16(T.opcodeCommandField.rawValue), T.dataLength, &commandCopy) == 0
    }
}

// MARK: - Darwin Stubs

#if os(OSX) || os(iOS)
    
    func hci_send_cmd(dd: CInt, _ ogf: UInt16, _ ocf: UInt16, _ plen: UInt8 , _ param: UnsafePointer<Void>) -> CInt { stub() }
    
#endif