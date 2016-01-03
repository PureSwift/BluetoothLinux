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

public extension Adapter {
    
    /// Sends a command to the device. 
    /// 
    /// - Note: Does not wait for a response.
    func deviceCommand(opcodeGroupField: UInt16, opcodeCommandField: UInt16, data: Data) -> Bool {
        
        return hci_send_cmd(socket, opcodeGroupField, opcodeCommandField, Byte(data.count), data) == 0
    }
}

// MARK: - Darwin Stubs

#if os(OSX) || os(iOS)
    
    func hci_send_cmd(dd: CInt, _ ogf: UInt16, _ ocf: UInt16, _ plen: UInt8 , _ param: UnsafePointer<Void>) -> CInt { stub() }
    
#endif