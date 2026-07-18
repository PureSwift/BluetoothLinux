//
//  SCOSocketAddress.swift
//  BluetoothLinux
//

import SystemPackage
import Socket
import Bluetooth

/// Bluetooth SCO Socket Address
@frozen
public struct SCOSocketAddress: Equatable, Hashable, Sendable {

    // MARK: - Properties

    /// Bluetooth address
    public var address: BluetoothAddress

    // MARK: - Initialization

    public init(address: BluetoothAddress) {
        self.address = address
    }
}

extension SCOSocketAddress: BluetoothSocketAddress {

    @_alwaysEmitIntoClient
    public static var protocolID: BluetoothSocketProtocol { .sco }

    /// Unsafe pointer closure
    public func withUnsafePointer<Result, Error>(
      _ body: (UnsafePointer<CInterop.SocketAddress>, UInt32) throws(Error) -> Result
    ) rethrows -> Result where Error: Swift.Error {
        var value = CInterop.SCOSocketAddress()
        value.address = address.littleEndian
        return try value.withUnsafePointer(body)
    }

    public static func withUnsafePointer<Error>(
        _ body: (UnsafeMutablePointer<CInterop.SocketAddress>, UInt32) throws(Error) -> ()
    ) rethrows -> Self where Error: Swift.Error {
        var value = CInterop.SCOSocketAddress()
        try value.withUnsafeMutablePointer(body)
        return Self.init(address: .init(littleEndian: value.address))
    }

    public static func withUnsafePointer(
        _ pointer: UnsafeMutablePointer<CInterop.SocketAddress>
    ) -> Self {
        pointer.withMemoryRebound(to: CInterop.SCOSocketAddress.self, capacity: 1) { pointer in
            Self.init(address: .init(littleEndian: pointer.pointee.address))
        }
    }
}
