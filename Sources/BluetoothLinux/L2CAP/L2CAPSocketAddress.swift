//
//  L2CAPSocketAddress.swift
//  
//
//  Created by Alsey Coleman Miller on 16/10/21.
//

import SystemPackage
import Bluetooth
import BluetoothHCI

/// Bluetooth L2CAP Socket
@frozen
public struct L2CAPSocketAddress: Equatable, Hashable, BluetoothSocketAddress {
    
    @_alwaysEmitIntoClient
    public static var protocolID: BluetoothSocketProtocol { .l2cap }
    
    // MARK: - Properties
    
    /// Bluetooth address
    public var address: BluetoothAddress
    
    /// Bluetooth address type
    public var addressType: AddressType?
    
    /// Protocol Service Multiplexer
    public var protocolServiceMultiplexer: ProtocolServiceMultiplexer?
    
    /// Channel
    public var channel: ChannelIdentifier
    
    // MARK: - Initialization
    
    /// Initialize with device and channel identifiers.
    public init(
        address: BluetoothAddress,
        addressType: AddressType? = nil,
        protocolServiceMultiplexer: ProtocolServiceMultiplexer? = nil,
        channel: ChannelIdentifier
    ) {
        self.address = address
        self.addressType = addressType
        self.protocolServiceMultiplexer = protocolServiceMultiplexer
        self.channel = channel
    }
    
    public static var none: L2CAPSocketAddress {
        return L2CAPSocketAddress(
            address: .zero,
            addressType: nil,
            protocolServiceMultiplexer: nil,
            channel: 0
        )
    }
    
    @_alwaysEmitIntoClient
    public init(
        lowEnergy address: BluetoothAddress,
        isRandom: Bool
    ) {
        self.init(
            address: address,
            addressType: isRandom ? .lowEnergyRandom : .lowEnergyPublic,
            protocolServiceMultiplexer: nil,
            channel: .att
        )
    }
    
    internal init(_ address: CInterop.L2CAPSocketAddress) {
        self.init(
            address: .init(littleEndian: address.l2_bdaddr),
            addressType: .init(rawValue: address.l2_bdaddr_type),
            protocolServiceMultiplexer: .init(rawValue: UInt8(UInt16(littleEndian: address.l2_psm))),
            channel: .init(rawValue: .init(littleEndian: address.l2_cid))
        )
    }
    
    public func withUnsafePointer<Result>(
      _ body: (UnsafePointer<CInterop.SocketAddress>, UInt32) throws -> Result
    ) rethrows -> Result {
        var value = CInterop.L2CAPSocketAddress()
        value.l2_bdaddr = address.littleEndian
        // FIXME: PSM enum should be UInt16 not UInt8
        value.l2_psm = UInt16(protocolServiceMultiplexer?.rawValue ?? 0).littleEndian
        value.l2_cid = channel.rawValue.littleEndian
        value.l2_bdaddr_type = addressType?.rawValue ?? 0
        return try value.withUnsafePointer(body)
    }
    
    public static func withUnsafePointer(
        _ body: (UnsafeMutablePointer<CInterop.SocketAddress>, UInt32) throws -> ()
    ) rethrows -> Self {
        var value = CInterop.L2CAPSocketAddress()
        try value.withUnsafeMutablePointer(body)
        return Self.init(value)
    }
    
    public static func withUnsafePointer(
        _ pointer: UnsafeMutablePointer<CInterop.SocketAddress>
    ) -> Self {
        return pointer.withMemoryRebound(to: CInterop.L2CAPSocketAddress.self, capacity: 1) { pointer in
            Self.init(pointer.pointee)
        }
    }
}
