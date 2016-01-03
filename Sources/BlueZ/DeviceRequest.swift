//
//  DeviceRequest.swift
//  BlueZ
//
//  Created by Alsey Coleman Miller on 1/3/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

#if os(Linux)
    import CBlueZ
    import Glibc
#elseif os(OSX) || os(iOS)
    import Darwin.C
#endif

import SwiftFoundation

public extension BluetoothAdapter {
    
    /// Sends a command to the device and waits for a response.
    ///
    /// The response is always a byte.
    func deviceRequest<Command: HCICommand>(command: Command, timeout: Int = 1000) throws -> Byte {
                
        var request = hci_request()
        var status: Byte = 0
        
        // initialize by zeroing memory
        memset(&request, 0, sizeof(hci_request))
        
        // set HCI command parameters
        
        request.ogf = Command.opcodeGroupField.rawValue
        request.ocf = Command.opcodeCommandField
        request.clen = CInt(Command.dataLength)
        
        var commandBytes = command.toData().byteValue
        
        withUnsafePointer(&commandBytes) { (pointer) in

            request.cparam = UnsafeMutablePointer<Void>(pointer)
        }
        
        // set HCI Event to a status byte
        request.rlen = 1
        
        withUnsafeMutablePointer(&status) { (pointer) in
            
            request.rparam = UnsafeMutablePointer<Void>(pointer)
        }
        
        try withUnsafeMutablePointer(&request) { (pointer) throws in
            
            guard hci_send_req(socket, pointer, CInt(timeout)) == 0
                else { throw POSIXError.fromErrorNumber! }
        }
        
        return status
    }
    
    /*
    /// Sends a command to the device and waits for a response.
    ///
    /// The response is always a byte.
    func deviceRequest<Command: HCICommand, Event: HCIEvent>(command: Command, timeout: Int = 1000) throws -> Event {
        
        var request = hci_request()
        
        // initialize by zeroing memory
        memset(&request, 0, sizeof(hci_request))
        
        // set HCI command parameters
        
        request.ogf = Command.opcodeGroupField.rawValue
        request.ocf = Command.opcodeCommandField
        request.clen = CInt(Command.dataLength)
        
        var commandBytes = command.toData().byteValue
        
        withUnsafePointer(&commandBytes) { (pointer) in
            
            request.cparam = UnsafeMutablePointer<Void>(pointer)
        }
        
        // set HCI Event
        request.event = Event.
        
        try withUnsafePointer(&request) { (pointer) throws in
            
            guard hci_send_req(socket, COpaquePointer(pointer), CInt(timeout)) == 0
                else { throw POSIXError.fromErrorNumber! }
        }
        
        
    }*/
}

// MARK: - Darwin Stubs

#if os(OSX) || os(iOS)
    
    /// Sends command and waits for response.
    func hci_send_req(dd: CInt, _ hcirequest: UnsafeMutablePointer<hci_request>, _ timeout: CInt) -> CInt { stub() }
    
    struct hci_request {
        
        var ogf: UInt16
        
        var ocf: UInt16
        
        /// The event code of the event to wait for.
        var event: CInt
        
        var cparam: UnsafeMutablePointer<Void>
        
        var clen: CInt
        
        var rparam: UnsafeMutablePointer<Void>
        
        var rlen: CInt
        
        init() { stub() }
    }
    
#endif
