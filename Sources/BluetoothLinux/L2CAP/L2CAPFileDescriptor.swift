//
//  L2CAPFileDescriptor.swift
//  
//
//  Created by Alsey Coleman Miller on 17/10/21.
//

import Bluetooth
import BluetoothHCI
import SystemPackage

internal extension FileDescriptor {
    
    /// Creates an L2CAP socket binded to the specified address.
    @usableFromInline
    static func l2cap(
        _ address: L2CAPSocketAddress,
        _ flags: SocketFlags
    ) throws -> FileDescriptor {
        try bluetooth(
            .l2cap,
            bind: address,
            flags: flags
        )
    }
}
