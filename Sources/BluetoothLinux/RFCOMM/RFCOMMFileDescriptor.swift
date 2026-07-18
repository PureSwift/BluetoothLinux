//
//  RFCOMMFileDescriptor.swift
//  BluetoothLinux
//

import Bluetooth
import Socket

internal extension SocketDescriptor {

    /// Creates an RFCOMM socket binded to the specified address.
    @usableFromInline
    static func rfcomm(
        _ address: RFCOMMSocketAddress,
        _ flags: SocketFlags
    ) throws(Errno) -> SocketDescriptor {
        try bluetooth(
            .rfcomm,
            bind: address,
            flags: flags
        )
    }
}
