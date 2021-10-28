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

/// L2CAP Bluetooth socket
public final class L2CAPSocket: L2CAPSocketProtocol {
    
    // MARK: - Properties
    
    /// Internal socket file descriptor
    @usableFromInline
    internal let fileDescriptor: FileDescriptor
    
    /// L2CAP Socket address
    public let address: L2CAPSocketAddress
    
    // MARK: - Initialization

    deinit {
        try? fileDescriptor.close()
    }
    
    internal init(
        fileDescriptor: FileDescriptor,
        address: L2CAPSocketAddress
    ) {
        self.fileDescriptor = fileDescriptor
        self.address = address
    }
    
    /// Create a new L2CAP socket with the specified address.
    public init(address: L2CAPSocketAddress) throws {
        self.fileDescriptor = try .l2cap(address, [.closeOnExec])
        self.address = address
    }
    
    /// Create a new L2CAP socket on the `HostController` with the specified identifier.
    public init(
        hostController: HostController,
        type: AddressType? = nil,
        protocolServiceMultiplexer: ProtocolServiceMultiplexer? = nil,
        channel: ChannelIdentifier
    ) throws {
        let deviceAddress = try hostController.readDeviceAddress()
        let socketAddress = L2CAPSocketAddress(
            address: deviceAddress,
            addressType: type,
            protocolServiceMultiplexer: protocolServiceMultiplexer,
            channel: channel
        )
        self.fileDescriptor = try .l2cap(socketAddress, [.closeOnExec])
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
        let fileDescriptor = try FileDescriptor.l2cap(address, [.closeOnExec])
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
    ) throws -> L2CAPSocket {
        let address = try hostController.readDeviceAddress()
        return try lowEnergyServer(
            address: address,
            isRandom: isRandom,
            backlog: backlog
        )
    }
    
    /// Creates a client socket for an L2CAP connection.
    public static func lowEnergyClient(
        localAddress: BluetoothAddress,
        destinationAddress: BluetoothAddress,
        destinationAddressType: LowEnergyAddressType
    ) throws -> L2CAPSocket {
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
        let fileDescriptor = try FileDescriptor.l2cap(localSocketAddress, [.closeOnExec])
        try fileDescriptor.closeIfThrows {
            try fileDescriptor.connect(to: destinationSocketAddress)
            try fileDescriptor.setNonblocking()
        }
        return L2CAPSocket(
            fileDescriptor: fileDescriptor,
            address: localSocketAddress
        )
    }
    
    /// Creates a client socket for an L2CAP connection.
    public static func lowEnergyClient(
        localAddress: BluetoothAddress,
        destination: HCILEAdvertisingReport.Report
    ) throws -> L2CAPSocket {
        return try lowEnergyClient(
            localAddress: localAddress,
            destinationAddress: destination.address,
            destinationAddressType: destination.addressType
        )
    }
    
    // MARK: - Static Methods
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
    
    /// Attempts to change the socket's security level.
    public func setSecurityLevel(_ securityLevel: SecurityLevel) throws {
        let socketOption = BluetoothSocketOption.Security(
            level: securityLevel,
            keySize: 0
        )
        try fileDescriptor.setSocketOption(socketOption)
    }
    
    internal func _securityLevel() throws -> SecurityLevel {
        let socketOption = try fileDescriptor.getSocketOption(BluetoothSocketOption.Security.self)
        return socketOption.level
    }

    /// Attempt to accept an incomping connection.
    public func accept() throws -> L2CAPSocket {
        let (clientFileDescriptor, clientAddress) = try fileDescriptor.accept(L2CAPSocketAddress.self)
        try clientFileDescriptor.closeIfThrows {
            try clientFileDescriptor.setNonblocking()
        }
        return L2CAPSocket(
            fileDescriptor: clientFileDescriptor,
            address: clientAddress
        )
    }
    
    /// Reads from the socket.
    public func recieve(_ bufferSize: Int = 1024) throws -> Data? {
        
        let events = try fileDescriptor.poll(
            for: [.read],
            timeout: 0
        )
        
        guard events.contains(.read) else {
            return nil
        }
        
        var buffer = Data(repeating: 0, count: bufferSize)
        let recievedByteCount = try buffer.withUnsafeMutableBytes {
            try fileDescriptor.read(into: $0)
        }
        return Data(buffer.prefix(recievedByteCount))
    }
    
    /// Blocks until data is ready.
    public func waitForEvents(timeout: TimeInterval) throws {
        
        let _ = try fileDescriptor.poll(
            for: [.read, .write, .error, .readUrgent, .hangup, .invalidRequest],
            timeout: Int(timeout)
        )
    }
    
    /// Write to the socket.
    public func send(_ data: Data) throws {
        
        let _ = try data.withUnsafeBytes {
            try fileDescriptor.write($0)
        }
    }
    
    /// Attempt to get L2CAP socket options.
    public func getSocketOptions() throws -> L2CAPSocketOption.Options {
        return try fileDescriptor.getSocketOption(L2CAPSocketOption.Options.self)
    }
}

public extension L2CAPSocket {
    
    /// The socket's security level.
    @available(*, deprecated, message: "Use throwing 'securityLevel()'")
    var securityLevel: SecurityLevel {
        return (try? _securityLevel()) ?? .sdp
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
