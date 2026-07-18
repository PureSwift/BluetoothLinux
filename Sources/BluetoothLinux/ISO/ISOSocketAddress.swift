//
//  ISOSocketAddress.swift
//  BluetoothLinux
//

import SystemPackage
import Socket
import Bluetooth

/// Bluetooth ISO Socket Address
@frozen
public struct ISOSocketAddress: Equatable, Hashable, Sendable {

    // MARK: - Properties

    /// Bluetooth address
    public var address: BluetoothAddress

    /// Bluetooth address type
    public var addressType: AddressType

    // MARK: - Initialization

    public init(
        address: BluetoothAddress,
        addressType: AddressType = .lowEnergyPublic
    ) {
        self.address = address
        self.addressType = addressType
    }
}

extension ISOSocketAddress: BluetoothSocketAddress {

    @_alwaysEmitIntoClient
    public static var protocolID: BluetoothSocketProtocol { .iso }

    /// Unsafe pointer closure
    public func withUnsafePointer<Result, Error>(
      _ body: (UnsafePointer<CInterop.SocketAddress>, UInt32) throws(Error) -> Result
    ) rethrows -> Result where Error: Swift.Error {
        var value = CInterop.ISOSocketAddress()
        value.address = address.littleEndian
        value.type = addressType.rawValue
        return try value.withUnsafePointer(body)
    }

    public static func withUnsafePointer<Error>(
        _ body: (UnsafeMutablePointer<CInterop.SocketAddress>, UInt32) throws(Error) -> ()
    ) rethrows -> Self where Error: Swift.Error {
        var value = CInterop.ISOSocketAddress()
        try value.withUnsafeMutablePointer(body)
        return Self.init(value)
    }

    public static func withUnsafePointer(
        _ pointer: UnsafeMutablePointer<CInterop.SocketAddress>
    ) -> Self {
        pointer.withMemoryRebound(to: CInterop.ISOSocketAddress.self, capacity: 1) { pointer in
            Self.init(pointer.pointee)
        }
    }
}

internal extension ISOSocketAddress {

    @usableFromInline
    init(_ bytes: CInterop.ISOSocketAddress) {
        self.init(
            address: .init(littleEndian: bytes.address),
            addressType: AddressType(rawValue: bytes.type) ?? .lowEnergyPublic
        )
    }
}
