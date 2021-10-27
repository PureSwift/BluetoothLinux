//
//  RFCOMMSocketAddress.swift
//  
//
//  Created by Alsey Coleman Miller on 16/10/21.
//

import Bluetooth
import SystemPackage

/// RFCOMM Socket Address
@frozen
public struct RFCOMMSocketAddress: Equatable, Hashable {
    
    // MARK: - Properties
    
    public var address: BluetoothAddress
    
    public var channel: UInt8
    
    // MARK: - Initialization
    
    public init(address: BluetoothAddress, channel: UInt8){
        self.address = address
        self.channel = channel
    }
}

extension RFCOMMSocketAddress: SocketAddress {
    
    public typealias ProtocolID = BluetoothSocketProtocol
    
    public static var protocolID: ProtocolID { .rfcomm }
    
    /// Unsafe pointer closure
    public func withUnsafePointer<Result>(
      _ body: (UnsafePointer<CInterop.SocketAddress>, UInt32) throws -> Result
    ) rethrows -> Result {
        try bytes.withUnsafePointer(body)
    }
    
    public static func withUnsafePointer(
        _ body: (UnsafeMutablePointer<CInterop.SocketAddress>, UInt32) throws -> ()
    ) rethrows -> Self {
        var bytes = CInterop.RFCOMMSocketAddress()
        try bytes.withUnsafeMutablePointer(body)
        return Self.init(bytes)
    }
}

internal extension RFCOMMSocketAddress {
    
    init(_ bytes: CInterop.RFCOMMSocketAddress) {
        self.init(
            address: bytes.address,
            channel: bytes.channel
        )
    }
    
    var bytes: CInterop.RFCOMMSocketAddress {
        CInterop.RFCOMMSocketAddress(
            address: address,
            channel: channel
        )
    }
}
