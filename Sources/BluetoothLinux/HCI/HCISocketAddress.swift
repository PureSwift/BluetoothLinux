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
    public init(
        device: HostController.ID = .none,
        channel: HCIChannel = .raw
    ) {
        self.device = device
        self.channel = channel
    }
}

internal extension HCISocketAddress {
    
    init(_ bytes: CInterop.HCISocketAddress) {
        self.init(
            device: HostController.ID(rawValue: bytes.device),
            channel: HCIChannel(rawValue: bytes.channel) ?? .raw
        )
    }
    
    var bytes: CInterop.HCISocketAddress {
        CInterop.HCISocketAddress(
            device: device.rawValue,
            channel: channel.rawValue
        )
    }
}

extension HCISocketAddress: CustomStringConvertible, CustomDebugStringConvertible {
    
    @inline(never)
    public var description: String {
        return "HCISocketAddress(device: \(device.rawValue), channel: \(channel))"
    }
    
    public var debugDescription: String {
        return description
    }
}

extension HCISocketAddress: SocketAddress {
    
    public typealias ProtocolID = BluetoothSocketProtocol
    
    public static var protocolID: ProtocolID { .hci }
    
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
}
