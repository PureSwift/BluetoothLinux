//
//  HCISocketAddress.swift
//  
//
//  Created by Alsey Coleman Miller on 16/10/21.
//

import Bluetooth
import SystemPackage

/// Bluetooth HCI Socket Address
@frozen
public struct HCISocketAddress: Equatable, Hashable {
    
    // MARK: - Properties
    
    /// HCI device identifier
    public var device: HostController.ID
    
    /// Channel identifier
    public var channel: HCIChannel
    
    // MARK: - Initialization
    
    /// Initialize with device and channel identifiers.
    @_alwaysEmitIntoClient
    public init(
        device: HostController.ID = .none,
        channel: HCIChannel = .raw
    ) {
        self.device = device
        self.channel = channel
    }
}

internal extension HCISocketAddress {
    
    @usableFromInline
    init(_ bytes: CInterop.HCISocketAddress) {
        self.init(
            device: HostController.ID(rawValue: bytes.device),
            channel: HCIChannel(rawValue: bytes.channel) ?? .raw
        )
    }
    
    @usableFromInline
    var bytes: CInterop.HCISocketAddress {
        CInterop.HCISocketAddress(
            device: device.rawValue,
            channel: channel.rawValue
        )
    }
}

extension HCISocketAddress: BluetoothSocketAddress {
    
    @_alwaysEmitIntoClient
    public static var protocolID: BluetoothSocketProtocol { .hci }
    
    /// Unsafe pointer closure
    public func withUnsafePointer<Result>(
      _ body: (UnsafePointer<CInterop.SocketAddress>, UInt32) throws -> Result
    ) rethrows -> Result {
        try bytes.withUnsafePointer(body)
    }
    
    public static func withUnsafePointer(
        _ body: (UnsafeMutablePointer<CInterop.SocketAddress>, UInt32) throws -> ()
    ) rethrows -> Self {
        var bytes = CInterop.HCISocketAddress()
        try bytes.withUnsafeMutablePointer(body)
        return Self.init(bytes)
    }
    
    public static func withUnsafePointer(
        _ pointer: UnsafeMutablePointer<CInterop.SocketAddress>
    ) -> Self {
        return pointer.withMemoryRebound(to: CInterop.HCISocketAddress.self, capacity: 1) { pointer in
            Self.init(pointer.pointee)
        }
    }
}
