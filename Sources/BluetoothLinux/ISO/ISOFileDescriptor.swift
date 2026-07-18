//
//  ISOFileDescriptor.swift
//  BluetoothLinux
//

import Bluetooth
import Socket

internal extension SocketDescriptor {

    /// Creates an ISO socket binded to the specified address.
    @usableFromInline
    static func iso(
        _ address: ISOSocketAddress,
        _ flags: SocketFlags
    ) throws(Errno) -> SocketDescriptor {
        try bluetooth(
            .iso,
            bind: address,
            flags: flags
        )
    }
}
