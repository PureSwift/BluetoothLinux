//
//  DeviceRequest.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 1/3/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

#if os(Linux)
    import Glibc
#elseif os(OSX) || os(iOS)
    import Darwin.C
#endif

import SwiftFoundation

public extension Adapter {

    /// Sends a command to the device and waits for a response.
    func deviceRequest<T: HCICommandParameter>(command: T, timeout: Int = 1000) throws {
        
        
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
