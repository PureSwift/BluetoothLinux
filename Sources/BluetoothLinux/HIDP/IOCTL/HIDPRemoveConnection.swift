//
//  HIDPRemoveConnection.swift
//  BluetoothLinux
//

import Bluetooth
import SystemPackage
import Socket

public extension HIDPIO {

    /// HIDP Remove Connection
    ///
    /// Destroys the kernel session (and input device) for the specified remote device.
    struct RemoveConnection: Equatable, Hashable, IOControlValue {

        @_alwaysEmitIntoClient
        public static var id: HIDPIO { .removeConnection }

        @usableFromInline
        internal private(set) var bytes: CInterop.HIDPConnectionDeleteRequest

        @usableFromInline
        internal init(_ bytes: CInterop.HIDPConnectionDeleteRequest) {
            self.bytes = bytes
        }

        public init(
            destination: BluetoothAddress,
            flags: HIDPConnectionFlag = []
        ) {
            self.init(CInterop.HIDPConnectionDeleteRequest(
                address: destination.littleEndian,
                flags: flags.rawValue)
            )
        }

        @_alwaysEmitIntoClient
        public mutating func withUnsafeMutablePointer<Result>(_ body: (UnsafeMutableRawPointer) throws -> (Result)) rethrows -> Result {
            try Swift.withUnsafeMutableBytes(of: &bytes) { buffer in
                try body(buffer.baseAddress!)
            }
        }
    }
}

public extension HIDPIO.RemoveConnection {

    @_alwaysEmitIntoClient
    var destination: BluetoothAddress {
        return BluetoothAddress(littleEndian: bytes.address)
    }

    @_alwaysEmitIntoClient
    var flags: HIDPConnectionFlag {
        return .init(rawValue: bytes.flags)
    }
}

// MARK: - File Descriptor

internal extension SocketDescriptor {

    @usableFromInline
    func hidpRemoveConnection(
        destination: BluetoothAddress,
        flags: HIDPConnectionFlag = []
    ) throws {
        var request = HIDPIO.RemoveConnection(
            destination: destination,
            flags: flags
        )
        try inputOutput(&request)
    }
}
