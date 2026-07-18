//
//  BNEPRemoveConnection.swift
//  BluetoothLinux
//

import Bluetooth
import SystemPackage
import Socket

public extension BNEPIO {

    /// BNEP Remove Connection
    ///
    /// Destroys the kernel session (and network interface) for the specified remote device.
    struct RemoveConnection: Equatable, Hashable, IOControlValue {

        @_alwaysEmitIntoClient
        public static var id: BNEPIO { .removeConnection }

        @usableFromInline
        internal private(set) var bytes: CInterop.BNEPConnectionDeleteRequest

        @usableFromInline
        internal init(_ bytes: CInterop.BNEPConnectionDeleteRequest) {
            self.bytes = bytes
        }

        @_alwaysEmitIntoClient
        public init(
            destination: BluetoothAddress,
            flags: BNEPConnectionFlag = []
        ) {
            self.init(CInterop.BNEPConnectionDeleteRequest(
                flags: flags.rawValue,
                destination: destination)
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

public extension BNEPIO.RemoveConnection {

    @_alwaysEmitIntoClient
    var destination: BluetoothAddress {
        return bytes.destination
    }

    @_alwaysEmitIntoClient
    var flags: BNEPConnectionFlag {
        return .init(rawValue: bytes.flags)
    }
}

// MARK: - File Descriptor

internal extension SocketDescriptor {

    @usableFromInline
    func bnepRemoveConnection(
        destination: BluetoothAddress,
        flags: BNEPConnectionFlag = []
    ) throws {
        var request = BNEPIO.RemoveConnection(
            destination: destination,
            flags: flags
        )
        try inputOutput(&request)
    }
}
