//
//  L2CAPFileDescriptor.swift
//  
//
//  Created by Alsey Coleman Miller on 17/10/21.
//

import Bluetooth
import BluetoothHCI
import Socket

internal extension SocketDescriptor {
    
    /// Creates an L2CAP socket binded to the specified address.
    @usableFromInline
    static func l2cap(
        _ address: L2CAPSocketAddress,
        _ flags: SocketFlags
    ) throws -> SocketDescriptor {
        try bluetooth(
            .l2cap,
            bind: address,
            flags: flags
        )
    }
}
