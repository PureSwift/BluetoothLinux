//
//  BNEPAddConnection.swift
//  BluetoothLinux
//

import Bluetooth
import SystemPackage
import Socket

public extension BNEPIO {

    /// BNEP Add Connection
    ///
    /// Bridges a connected L2CAP socket into a kernel network interface.
    /// The kernel writes the name of the created interface back into the request.
    struct AddConnection: IOControlValue {

        @_alwaysEmitIntoClient
        public static var id: BNEPIO { .addConnection }

        @usableFromInline
        internal private(set) var bytes: CInterop.BNEPConnectionAddRequest

        @usableFromInline
        internal init(_ bytes: CInterop.BNEPConnectionAddRequest) {
            self.bytes = bytes
        }

        public init(
            socket: SocketDescriptor,
            flags: BNEPConnectionFlag = [],
            role: BNEPRole,
            device: String = ""
        ) {
            self.init(CInterop.BNEPConnectionAddRequest(
                socket: socket.rawValue,
                flags: flags.rawValue,
                role: role.rawValue,
                device: device.deviceNameBytes)
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

public extension BNEPIO.AddConnection {

    @_alwaysEmitIntoClient
    var socket: SocketDescriptor {
        return .init(rawValue: bytes.socket)
    }

    @_alwaysEmitIntoClient
    var flags: BNEPConnectionFlag {
        return .init(rawValue: bytes.flags)
    }

    @_alwaysEmitIntoClient
    var role: BNEPRole? {
        return .init(rawValue: bytes.role)
    }

    /// Name of the network interface bridging the connection (e.g. `bnep0`).
    var device: String {
        withUnsafeBytes(of: bytes.device) { buffer in
            String(decoding: buffer.prefix(while: { $0 != 0 }), as: UTF8.self)
        }
    }
}

// MARK: - File Descriptor

internal extension SocketDescriptor {

    @usableFromInline
    func bnepAddConnection(
        socket: SocketDescriptor,
        flags: BNEPConnectionFlag = [],
        role: BNEPRole,
        device: String = ""
    ) throws -> String {
        var request = BNEPIO.AddConnection(
            socket: socket,
            flags: flags,
            role: role,
            device: device
        )
        try inputOutput(&request)
        return request.device
    }
}
