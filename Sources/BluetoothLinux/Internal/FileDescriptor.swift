//
//  FileDescriptor.swift
//  
//
//  Created by Alsey Coleman Miller on 16/10/21.
//

import Foundation
import Bluetooth
import BluetoothHCI
import SystemPackage

internal extension FileDescriptor {
    
    static func bluetooth(
        _ socketProtocol: BluetoothSocketProtocol,
        flags: SocketFlags = [.closeOnExec]
    ) throws -> FileDescriptor {
        return try socket(
            socketProtocol,
            flags: flags
        )
    }
    
    static func bluetooth<Address: BluetoothSocketAddress>(
        _ socketProtocol: BluetoothSocketProtocol,
        bind address: Address,
        flags: SocketFlags = [.closeOnExec]
    ) throws -> FileDescriptor {
        return try socket(socketProtocol, bind: address, flags: flags)
    }
}

