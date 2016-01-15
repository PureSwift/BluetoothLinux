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

    /// Sends a command to the device and waits for a response. No specific event is expected.
    func deviceRequest<Command: HCICommand, CommandParameter: HCICommandParameter>(command: Command, parameter: CommandParameter? = nil, timeout: Int = 1000) throws {

        var request = hci_request()
        var status: Byte = 0

        // initialize by zeroing memory
        memset(&request, 0, sizeof(hci_request))

        // set HCI command parameters

        request.ogf = Command.opcodeGroupField.rawValue
        request.ocf = command.rawValue
        
        if var commandParameter = parameter {
            
            request.clen = CommandParameter.dataLength
            
            withUnsafePointer(&commandParameter) { (pointer) in
                
                request.cparam = UnsafeMutablePointer<Void>(pointer)
            }
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

        guard status == 0x00 else { throw Bluetooth.HCIError(rawValue: status)! }
    }

    /// Sends a command to the device and waits for a response. The specified event is returned.
    ///
    /// - Precondition: The `Event` type is a value type.
    func deviceRequest<Command: HCICommandParameter, Event: HCIEvent>(command: Command, inout event: Event, timeout: Int = 1000) throws {

        assert(event as? AnyObject == nil, "\(event) must be a C struct from BlueZ")

        var request = hci_request()

        // initialize by zeroing memory
        memset(&request, 0, sizeof(hci_request))

        // set HCI command parameters

        request.ogf = Command.opcodeGroupField.rawValue
        request.ocf = Command.opcodeCommandField
        request.clen = CInt(Command.dataLength)

        var commandCopy = command

        withUnsafePointer(&commandCopy) { (pointer) in

            request.cparam = UnsafeMutablePointer<Void>(pointer)
        }

        // set HCI Event
        request.event = Event.eventCode
        request.rlen = CInt(Event.dataLength)

        withUnsafeMutablePointer(&event) { (pointer) in

            request.rparam = UnsafeMutablePointer<Void>(pointer)
        }

        try withUnsafeMutablePointer(&request) { (pointer) throws in

            guard hci_send_req(socket, pointer, CInt(timeout)) == 0
                else { throw POSIXError.fromErrorNumber! }
        }
    }
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
