//
//  L2CAP.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 2/28/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

import Foundation
import Bluetooth
import BluetoothHCI
import CBluetoothLinux
import SystemPackage
import Socket

/// L2CAP Bluetooth socket
public final class L2CAPSocket: Bluetooth.L2CAPSocket {
    
    // MARK: - Properties
    
    /// Internal socket file descriptor
    @usableFromInline
    internal let socket: Socket
    
    /// L2CAP Socket address
    public let address: L2CAPSocketAddress
    
    // MARK: - Initialization

    deinit {
        socket.close()
    }
    
    internal init(
        fileDescriptor: FileDescriptor,
        address: L2CAPSocketAddress
    ) {
        self.socket = Socket(fileDescriptor: fileDescriptor)
        self.address = address
    }
    
    /// Create a new L2CAP socket with the specified address.
    public init(address: L2CAPSocketAddress) throws {
        self.socket = try Socket(fileDescriptor: .l2cap(address, [.closeOnExec, .nonBlocking]))
        self.address = address
    }
    
    /// Create a new L2CAP socket on the `HostController` with the specified identifier.
    public init(
        hostController: HostController,
        type: AddressType? = nil,
        protocolServiceMultiplexer: ProtocolServiceMultiplexer? = nil,
        channel: ChannelIdentifier
    ) async throws {
        let deviceAddress = try await hostController.readDeviceAddress()
        let socketAddress = L2CAPSocketAddress(
            address: deviceAddress,
            addressType: type,
            protocolServiceMultiplexer: protocolServiceMultiplexer,
            channel: channel
        )
        self.socket = try Socket(fileDescriptor: .l2cap(socketAddress, [.closeOnExec, .nonBlocking]))
        self.address = socketAddress
    }
    
    /// Creates a server socket for an L2CAP connection.
    public static func lowEnergyServer(
        address: BluetoothAddress,
        isRandom: Bool = false,
        backlog: Int = 10
    ) throws -> L2CAPSocket {
        let address = L2CAPSocketAddress(
            lowEnergy: address,
            isRandom: isRandom
        )
        let fileDescriptor = try FileDescriptor.l2cap(address, [.closeOnExec, .nonBlocking])
        try fileDescriptor.closeIfThrows {
            try fileDescriptor.listen(backlog: backlog)
        }
        return L2CAPSocket(
            fileDescriptor: fileDescriptor,
            address: address
        )
    }
    
    /// Creates a server socket for an L2CAP connection.
    public static func lowEnergyServer(
        hostController: HostController,
        isRandom: Bool = false,
        backlog: Int = 10
    ) async throws -> L2CAPSocket {
        let address = try await hostController.readDeviceAddress()
        return try lowEnergyServer(
            address: address,
            isRandom: isRandom,
            backlog: backlog
        )
    }
    
    /// Creates a new socket connected to the remote address specified.
    public static func lowEnergyClient(
        address: BluetoothAddress,
        destination: BluetoothAddress,
        isRandom: Bool
    ) async throws -> L2CAPSocket {
        try await lowEnergyClient(
            address: address,
            destination: destination,
            type: isRandom ? .random : .public
        )
    }
    
    /// Creates a client socket for an L2CAP connection.
    public static func lowEnergyClient(
        address localAddress: BluetoothAddress,
        destination destinationAddress: BluetoothAddress,
        type destinationAddressType: LowEnergyAddressType
    ) async throws -> L2CAPSocket {
        let localSocketAddress = L2CAPSocketAddress(
            address: localAddress,
            addressType: nil,
            protocolServiceMultiplexer: nil,
            channel: .att
        )
        let destinationSocketAddress = L2CAPSocketAddress(
            address: destinationAddress,
            addressType: AddressType(lowEnergy: destinationAddressType),
            protocolServiceMultiplexer: nil,
            channel: .att
        )
        let fileDescriptor = try FileDescriptor.l2cap(localSocketAddress, [.closeOnExec, .nonBlocking])
        try await fileDescriptor.closeIfThrows {
            try await fileDescriptor.connect(to: destinationSocketAddress, sleep: 10_000_000)
        }
        return L2CAPSocket(
            fileDescriptor: fileDescriptor,
            address: localSocketAddress
        )
    }
    
    /// Creates a client socket for an L2CAP connection.
    public static func lowEnergyClient(
        address localAddress: BluetoothAddress,
        destination: HCILEAdvertisingReport.Report
    ) async throws -> L2CAPSocket {
        try await lowEnergyClient(
            address: localAddress,
            destination: destination.address,
            type: destination.addressType
        )
    }
    
    /*
    /// Check whether the file descriptor is a L2CAP socket.
    public static func validate(fileDescriptor: CInt) throws -> Bool {
        
        func value(for socketOption: CInt) throws -> CInt {
            
            var optionValue: CInt = 0
            var optionLength = socklen_t(MemoryLayout<CInt>.size)
            
            guard getsockopt(fileDescriptor, SOL_SOCKET, socketOption, &optionValue, &optionLength) == 0
                else { throw POSIXError.fromErrno() }
            
            return optionValue
        }
        
        // socket domain and protocol
        guard try value(for: SO_DOMAIN) == AF_BLUETOOTH,
            try value(for: SO_PROTOCOL) == BluetoothSocketProtocol.l2cap.rawValue
            else { return false }
        
        return true
    }*/

    // MARK: - Methods
    
    /// Attempt to accept an incoming connection.
    public func accept() async throws -> L2CAPSocket {
        let (clientFileDescriptor, clientAddress) = try await socket.fileDescriptor.accept(L2CAPSocketAddress.self, sleep: 10_000_000)
        try clientFileDescriptor.closeIfThrows {
            try clientFileDescriptor.setNonblocking()
        }
        return L2CAPSocket(
            fileDescriptor: clientFileDescriptor,
            address: clientAddress
        )
    }
    
    /// Write to the socket.
    public func send(_ data: Data) async throws {
        try await socket.write(data)
    }
    
    /// Reads from the socket.
    public func recieve(_ bufferSize: Int) async throws -> Data {
        return try await socket.read(bufferSize)
    }
    
    /// Attempts to change the socket's security level.
    public func setSecurityLevel(_ securityLevel: SecurityLevel) throws {
        let socketOption = BluetoothSocketOption.Security(
            level: securityLevel,
            keySize: 0
        )
        try socket.fileDescriptor.setSocketOption(socketOption)
    }
    
    public func securityLevel() throws -> SecurityLevel {
        let socketOption = try socket.fileDescriptor.getSocketOption(BluetoothSocketOption.Security.self)
        return socketOption.level
    }
    
    /// Attempt to get L2CAP socket options.
    public func getSocketOptions() throws -> L2CAPSocketOption.Options {
        return try socket.fileDescriptor.getSocketOption(L2CAPSocketOption.Options.self)
    }
}

// MARK: - Supporting Types

public extension L2CAPSocket {
    
    enum ConnectionResult: UInt16 {
        
        case success    = 0x0000
        case pending    = 0x0001
        case badPSM     = 0x0002
        case secBlock   = 0x0003
        case noMemory   = 0x0004
    }
    
    enum ConnectionStatus: UInt16 {
        
        case noInfo                 = 0x0000
        case authenticationPending  = 0x0001
        case authorizationPending   = 0x0002
    }
}
