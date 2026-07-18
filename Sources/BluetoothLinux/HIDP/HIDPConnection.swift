//
//  HIDPConnection.swift
//  BluetoothLinux
//

import Foundation
import Bluetooth
import SystemPackage
import Socket

/// HIDP connection information.
public struct HIDPConnection: Equatable, Hashable, Sendable {

    /// Address of the remote device.
    public let address: BluetoothAddress

    /// Connection flags.
    public let flags: HIDPConnectionFlag

    /// Connection state.
    public let state: HIDPConnectionState

    /// Vendor identifier.
    public let vendor: UInt16

    /// Product identifier.
    public let product: UInt16

    /// Version number.
    public let version: UInt16

    /// Name of the device.
    public let name: String
}

internal extension HIDPConnection {

    init(_ bytes: CInterop.HIDPConnectionInformation) {
        self.address = BluetoothAddress(littleEndian: bytes.address)
        self.flags = HIDPConnectionFlag(rawValue: bytes.flags)
        self.state = HIDPConnectionState(rawValue: bytes.state) ?? .unknown
        self.vendor = bytes.vendor
        self.product = bytes.product
        self.version = bytes.version
        self.name = String(hidpDeviceName: bytes.name)
    }
}

internal extension String {

    /// Decode from a fixed-size null-terminated device name buffer.
    @usableFromInline
    init(hidpDeviceName: CInterop.HIDPDeviceName) {
        self = withUnsafeBytes(of: hidpDeviceName) { buffer in
            String(decoding: buffer.prefix(while: { $0 != 0 }), as: UTF8.self)
        }
    }

    /// Encode as a fixed-size null-terminated device name buffer.
    @usableFromInline
    var hidpDeviceName: CInterop.HIDPDeviceName {
        var name: CInterop.HIDPDeviceName = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        let utf8 = Array(self.utf8.prefix(127))
        withUnsafeMutableBytes(of: &name) { buffer in
            for (index, byte) in utf8.enumerated() {
                buffer[index] = byte
            }
        }
        return name
    }
}
