//
//  HCISocketAddress.swift
//  
//
//  Created by Alsey Coleman Miller on 16/10/21.
//

import Bluetooth
import BluetoothHCI
import SystemPackage

/// Bluetooth HCI Socket Address
@frozen
public struct HCISocketAddress: Equatable, Hashable {
    
    internal let bytes: CInterop.HCISocketAddress
    
    internal init(bytes: CInterop.HCISocketAddress) {
        self.bytes = bytes
    }
    
    /// Initialize with device and channel identifiers.
    public init(device: HostController.ID, channel: BluetoothHCI.ChannelIdentifier) {
        self.init(
            bytes: CInterop.HCISocketAddress(
                device: device.rawValue,
                channel: channel.rawValue
            )
        )
    }
    
    /// HCI device identifier
    public var device: HostController.ID {
        return .init(rawValue: bytes.device)
    }
    
    /// Channel identifier
    public var channel: ChannelIdentifier {
        return .init(rawValue: bytes.channel)
    }
}

extension HCISocketAddress: CustomStringConvertible, CustomDebugStringConvertible {
    
    @inline(never)
    public var description: String {
        return "HCISocketAddress(device: \(device), channel: \(channel))"
    }
    
    public var debugDescription: String {
        return description
    }
}

extension HCISocketAddress: SocketAddress {
    
    /// Socket Address Family
    @_alwaysEmitIntoClient
    public static var family: SocketAddressFamily { .bluetooth }
    
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
        return Self.init(bytes: bytes)
    }
}
