//
//  BNEPConnection.swift
//  BluetoothLinux
//

import Foundation
import Bluetooth
import SystemPackage
import Socket

/// BNEP connection information.
public struct BNEPConnection: Equatable, Hashable, Sendable {

    /// Connection flags.
    public let flags: BNEPConnectionFlag

    /// Service role of the local device.
    public let role: BNEPRole?

    /// Connection state.
    public let state: BNEPConnectionState

    /// Address of the remote device.
    public let destination: BluetoothAddress

    /// Name of the network interface bridging the connection (e.g. `bnep0`).
    public let device: String
}

internal extension BNEPConnection {

    init(_ bytes: CInterop.BNEPConnectionInformation) {
        self.flags = BNEPConnectionFlag(rawValue: bytes.flags)
        self.role = BNEPRole(rawValue: bytes.role)
        self.state = BNEPConnectionState(rawValue: bytes.state) ?? .unknown
        self.destination = bytes.destination
        self.device = withUnsafeBytes(of: bytes.device) { buffer in
            String(decoding: buffer.prefix(while: { $0 != 0 }), as: UTF8.self)
        }
    }
}

internal extension String {

    /// Encode as a fixed-size null-terminated C string tuple of 16 bytes.
    @usableFromInline
    var deviceNameBytes: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) {
        var bytes: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        let utf8 = Array(self.utf8.prefix(15))
        withUnsafeMutableBytes(of: &bytes) { buffer in
            for (index, byte) in utf8.enumerated() {
                buffer[index] = byte
            }
        }
        return bytes
    }
}
