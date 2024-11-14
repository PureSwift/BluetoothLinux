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
@_implementationOnly import CBluetoothLinux
import SystemPackage
import Socket

/// L2CAP Bluetooth socket
public struct L2CAPSocket: Sendable {
    
    // MARK: - Properties
    
    /// Internal socket file descriptor
    @usableFromInline
    internal let fileDescriptor: SocketDescriptor
    
    /// L2CAP Socket address
    public let address: L2CAPSocketAddress
    
    // MARK: - Initialization
    
    internal init(
        fileDescriptor: SocketDescriptor,
        address: L2CAPSocketAddress
    ) {
        self.fileDescriptor = fileDescriptor
        self.address = address
    }
    
    /// Create a new L2CAP socket with the specified address.
    public init(address: L2CAPSocketAddress) throws(Errno) {
        self.fileDescriptor = try .l2cap(address, [.closeOnExec, .nonBlocking])
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
        try self.init(address: socketAddress)
    }
    
    /// Creates a server socket for an L2CAP connection.
    public static func lowEnergyServer(
        address: BluetoothAddress,
        isRandom: Bool = false,
        backlog: Int = Socket.maxBacklog
    ) throws(Errno) -> Self {
        let address = L2CAPSocketAddress(
            lowEnergy: address,
            isRandom: isRandom
        )
        let fileDescriptor = try SocketDescriptor.l2cap(address, [.closeOnExec, .nonBlocking])
        try fileDescriptor.closeIfThrows { () throws(Errno) -> () in
            try fileDescriptor.listen(backlog: backlog)
        }
        return Self.init(fileDescriptor: fileDescriptor, address: address)
    }
    
    /// Creates a server socket for an L2CAP connection.
    public static func lowEnergyServer(
        hostController: HostController,
        isRandom: Bool = false,
        backlog: Int = Socket.maxBacklog
    ) async throws -> Self {
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
    ) throws(Errno) -> Self {
        try lowEnergyClient(
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
    ) throws(Errno) -> Self {
        let localSocketAddress = L2CAPSocketAddress(
            address: localAddress,
            addressType: nil,
            protocolServiceMultiplexer: nil,
            channel: .att
        )
        let destinationSocketAddress = L2CAPSocketAddress(
            address: destinationAddress,
            addressType: AddressType(lowEnergy: destinationAddressType),
            protocolServiceMultiplexer: .att,
            channel: .att
        )
        let fileDescriptor = try SocketDescriptor.l2cap(localSocketAddress, [.closeOnExec, .nonBlocking])
        try? fileDescriptor.connect(to: destinationSocketAddress) // ignore result, async socket always throws
        return Self.init(fileDescriptor: fileDescriptor, address: localSocketAddress)
    }
    
    /// Creates a client socket for an L2CAP connection.
    public static func lowEnergyClient(
        address localAddress: BluetoothAddress,
        destination: HCILEAdvertisingReport.Report
    ) throws(Errno) -> Self {
        try lowEnergyClient(
            address: localAddress,
            destination: destination.address,
            type: destination.addressType
        )
    }
    
    // MARK: - Methods
    
    /// Close socket.
    public func close() {
        try? fileDescriptor.close()
    }
    
    /// Attempt to accept an incoming connection.
    public func accept() throws(Errno) -> Self {
        let (fileDescriptor, address) = try self.fileDescriptor.accept(L2CAPSocketAddress.self)
        return Self.init(
            fileDescriptor: fileDescriptor,
            address: address
        )
    }
    
    /// Write to the socket.
    public func send(_ data: Data) throws(Errno) -> Int {
        do {
            return try data.withUnsafeBytes { (bytes) throws(Errno) -> Int in
                try fileDescriptor.write(bytes)
            }
        }
        catch {
            throw error as! Errno // TODO: Foundation doesnt support typed error yet
        }
    }
    
    /// Reads from the socket.
    public func receive(_ length: Int) throws(Errno) -> Data {
        do {
            var data = Data(count: length)
            let bytesRead = try data.withUnsafeMutableBytes { (bytes) throws(Errno) -> Int in
                try fileDescriptor.read(into: bytes)
            }
            if bytesRead < length {
                data = data.prefix(bytesRead)
            }
            return data
        }
        catch {
            throw error as! Errno // TODO: Foundation doesnt support typed error yet
        }
    }
    
    public var security: BluetoothSocketOption.Security {
        get throws(Errno) {
            try fileDescriptor.getSocketOption(BluetoothSocketOption.Security.self)
        }
    }
    
    /// Attempts to change the socket's security level.
    public func setSecurity(_ security: BluetoothSocketOption.Security) throws(Errno) {
        try fileDescriptor.setSocketOption(security)
    }
    
    /// Attempt to get L2CAP socket options.
    public var options: L2CAPSocketOption.Options {
        get throws(Errno) {
            return try fileDescriptor.getSocketOption(L2CAPSocketOption.Options.self)
        }
    }
    
    public func setOptions(_ options: L2CAPSocketOption.Options) throws(Errno) {
        try fileDescriptor.setSocketOption(options)
    }
}

// MARK: - Supporting Types

// MARK: - Server

public extension L2CAPSocket {
    
    struct Server: Bluetooth.L2CAPServer, Sendable {
        
        // MARK: Properties
        
        @usableFromInline
        internal let socket: BluetoothLinux.L2CAPSocket
        
        /// Socket address
        public var address: BluetoothAddress {
            socket.address.address
        }
        
        /// Socket status
        public var status: L2CAPSocketStatus<Errno> {
            let events: FileEvents
            let errno: Errno?
            do {
                events = try socket.fileDescriptor.poll(for: [.read, .error, .hangup, .invalidRequest])
                if events.contains(.error) {
                    errno = .connectionReset
                } else if events.contains(.invalidRequest) {
                    errno = .badFileDescriptor
                } else if events.contains(.hangup) {
                    errno = .socketShutdown
                } else {
                    errno = nil
                }
            }
            catch {
                errno = error
                events = []
            }
            return .init(
                send: false,
                recieve: false,
                accept: events.contains(.read) && errno == nil,
                error: errno
            )
        }
        
        // MARK: Initialization
        
        internal init(socket: BluetoothLinux.L2CAPSocket) {
            self.socket = socket
        }
        
        public static func lowEnergyServer(
            address: BluetoothAddress,
            isRandom: Bool = false,
            backlog: Int = Socket.maxBacklog
        ) throws(Errno) -> L2CAPSocket.Server {
            let socket = try L2CAPSocket.lowEnergyServer(
                address: address,
                isRandom: isRandom,
                backlog: backlog
            )
            return Self.init(socket: socket)
        }
        
        // MARK: Methods
        
        /// Close socket.
        public func close() {
            socket.close()
        }
        
        public func accept() throws(Errno) -> L2CAPSocket.Connection {
            let socket = try self.socket.accept()
            return .init(socket: socket, destination: self.socket.address.address)
        }
    }
}

// MARK: - Connection

public extension L2CAPSocket {
    
    struct Connection: Bluetooth.L2CAPConnection, Sendable {
        
        // MARK: Properties
        
        @usableFromInline
        internal let socket: BluetoothLinux.L2CAPSocket
        
        public let destination: BluetoothAddress
        
        /// Socket address
        public var address: BluetoothAddress {
            socket.address.address
        }
                
        /// Socket status
        public var status: L2CAPSocketStatus<Errno> {
            let events: FileEvents
            let errno: Errno?
            do {
                events = try socket.fileDescriptor.poll(for: [.read, .write, .error, .hangup, .invalidRequest])
                if events.contains(.error) {
                    errno = .connectionReset
                } else if events.contains(.invalidRequest) {
                    errno = .badFileDescriptor
                } else if events.contains(.hangup) {
                    errno = .socketShutdown
                } else {
                    errno = nil
                }
            }
            catch {
                errno = error
                events = []
            }
            return .init(
                send: events.contains(.write) && errno == nil,
                recieve: events.contains(.read) && errno == nil,
                accept: false,
                error: errno
            )
        }
        
        // MARK: Initialization
        
        internal init(
            socket: BluetoothLinux.L2CAPSocket,
            destination: BluetoothAddress
        ) {
            self.socket = socket
            self.destination = destination
        }
        
        public static func lowEnergyClient(
            address: BluetoothAddress,
            destination: BluetoothAddress,
            isRandom: Bool = false
        ) throws(Errno) -> Self {
            let socket = try L2CAPSocket.lowEnergyClient(
                address: address,
                destination: destination,
                isRandom: isRandom
            )
            return .init(socket: socket, destination: destination)
        }
        
        // MARK: Methods
        
        /// Close socket.
        public func close() {
            socket.close()
        }
                
        /// Write to the socket.
        public func send(_ data: Data) throws(Errno) {
            _ = try socket.send(data)
        }
        
        /// Reads from the socket.
        public func receive(_ bufferSize: Int) throws(Errno) -> Data {
            try socket.receive(bufferSize)
        }
            
        /// Attempts to change the socket's security level.
        public func setSecurityLevel(_ securityLevel: SecurityLevel) throws(Errno) {
            var security = try socket.security
            security = .init(level: securityLevel, keySize: security.keySize)
            try socket.setSecurity(security)
        }
        
        /// Get security level
        public func securityLevel() throws(Errno) -> SecurityLevel {
            try socket.security.level
        }
    }
}

internal extension L2CAPSocket {
    
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
