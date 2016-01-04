//
//  HCIEvent.swift
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

public protocol HCIEvent {
    
    /// Event Opcode
    static var eventCode: CInt { get }
    
    /// Length of the command when encoded to data.
    ///
    /// - Note: Commands are a fixed length.
    static var dataLength: Byte { get }
}

// MARK: - C API Extensions

#if os(OSX)
    let EVT_LE_CONN_COMPLETE: CInt = 0x01
    public struct evt_le_connection_complete {
        var status: UInt8
        var handle: UInt16
        var role: UInt8
        var peer_bdaddr_type: UInt8
        var peer_bdaddr: bdaddr_t
        var interval: UInt16
        var latency: UInt16
        var supervision_timeout: UInt16
        var master_clock_accuracy: UInt8
    }
    let EVT_LE_CONN_COMPLETE_SIZE: CInt = 18
#endif

extension evt_le_connection_complete: HCIEvent {
    public static var eventCode: CInt { return EVT_LE_CONN_COMPLETE }
    public static var dataLength: Byte { return Byte(EVT_LE_CONN_COMPLETE_SIZE) }
}


