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
        return try FileDescriptor.socket(
            socketProtocol,
            flags: flags
        )
    }
}

