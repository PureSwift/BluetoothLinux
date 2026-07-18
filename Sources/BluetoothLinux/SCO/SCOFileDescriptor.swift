//
//  SCOFileDescriptor.swift
//  BluetoothLinux
//

import Bluetooth
import Socket

internal extension SocketDescriptor {

    /// Creates an SCO socket binded to the specified address.
    @usableFromInline
    static func sco(
        _ address: SCOSocketAddress,
        _ flags: SocketFlags
    ) throws(Errno) -> SocketDescriptor {
        try bluetooth(
            .sco,
            bind: address,
            flags: flags
        )
    }
}
