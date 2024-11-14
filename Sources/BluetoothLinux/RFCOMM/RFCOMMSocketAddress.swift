//
//  RFCOMMSocketAddress.swift
//  
//
//  Created by Alsey Coleman Miller on 16/10/21.
//

import SystemPackage
import Socket
import Bluetooth

/// RFCOMM Socket Address
@frozen
public struct RFCOMMSocketAddress: Equatable, Hashable, Sendable {
    
    // MARK: - Properties
    
    public var address: BluetoothAddress
    
    public var channel: UInt8
    
    // MARK: - Initialization
    
    public init(address: BluetoothAddress,
                channel: UInt8) {
        
        self.address = address
        self.channel = channel
    }
}

extension RFCOMMSocketAddress: BluetoothSocketAddress {
    
    @_alwaysEmitIntoClient
    public static var protocolID: BluetoothSocketProtocol { .rfcomm }
    
    /// Unsafe pointer closure
    @_alwaysEmitIntoClient
    public func withUnsafePointer<Result, Error>(
      _ body: (UnsafePointer<CInterop.SocketAddress>, UInt32) throws(Error) -> Result
    ) rethrows -> Result where Error: Swift.Error {
        try bytes.withUnsafePointer(body)
    }
    
    @_alwaysEmitIntoClient
    public static func withUnsafePointer<Error>(
        _ body: (UnsafeMutablePointer<CInterop.SocketAddress>, UInt32) throws(Error) -> ()
    ) rethrows -> Self where Error: Swift.Error {
        var bytes = CInterop.RFCOMMSocketAddress()
        try bytes.withUnsafeMutablePointer(body)
        return Self.init(bytes)
    }
    
    public static func withUnsafePointer(
        _ pointer: UnsafeMutablePointer<CInterop.SocketAddress>
    ) -> Self {
        return pointer.withMemoryRebound(to: CInterop.RFCOMMSocketAddress.self, capacity: 1) { pointer in
            Self.init(pointer.pointee)
        }
    }
}

internal extension RFCOMMSocketAddress {
    
    @usableFromInline
    init(_ bytes: CInterop.RFCOMMSocketAddress) {
        self.init(
            address: bytes.address,
            channel: bytes.channel
        )
    }
    
    @usableFromInline
    var bytes: CInterop.RFCOMMSocketAddress {
        CInterop.RFCOMMSocketAddress(
            address: address,
            channel: channel
        )
    }
}
