//
//  DeviceRequest.swift
//  BlueZ
//
//  Created by Alsey Coleman Miller on 1/3/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

#if os(Linux)
    import CBlueZ
#endif

import SwiftFoundation

public extension BluetoothAdapter {
    
    /// Sends a command to the device and waits for a response. 
    func deviceRequest(opcodeGroupField: UInt16, opcodeCommandField: UInt16, event: CInt, command: Data, timeout: Int = 1000) throws {
                
        let HCIRequestPointer = UnsafeMutablePointer<hci_request>.alloc(1)
        defer { HCIRequestPointer.dealloc(1) }
        
        memset(HCIRequestPointer, 0, sizeof(hci_request))
        
        guard hci_send_req(socket, COpaquePointer(HCIRequestPointer), CInt(timeout)) == 0
            else { throw POSIXError.fromErrorNumber! }
        
        
    }
}

// MARK: - Darwin Stubs

#if os(OSX) || os(iOS)
    
    /// Sends command and waits for response.
    func hci_send_req(dd: CInt, _ hci_request: COpaquePointer, _ timeout: CInt) -> CInt { stub() }
    
    struct hci_request {
        
        var ogf: UInt16
        
        var ocf: UInt16
        
        /// The event code of the event to wait for.
        var event: CInt
        
        var cparam: UnsafeMutablePointer<Void>
        
        var clen: CInt
        
        var rparam: UnsafeMutablePointer<Void>
        
        var rlen: CInt
    }
    
#endif
