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
public final class L2CAPSocket {
    
    // MARK: - Properties
    
    /// Internal socket file descriptor
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
        let fileDescriptor = try FileDescriptor.l2cap(address)
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
    
    public func securityLevel() throws -> SecurityLevel {
        let socketOption = try fileDescriptor.getSocketOption(BluetoothSocketOption.Security.self)
        return socketOption.level
    }

    /// Blocks the caller until a new connection is recieved.
    public func waitForConnection() throws -> L2CAPSocket {

        var remoteAddress = sockaddr_l2()

        var socketLength = socklen_t(MemoryLayout<sockaddr_l2>.size)
        
        // accept new client
        let client = withUnsafeMutablePointer(to: &remoteAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1, {
                accept(internalSocket, $0, &socketLength)
            })
        })
        
        // error accepting new connection
        guard client >= 0 else { throw POSIXError.fromErrno() }

        let newSocket = L2CAPSocket(clientSocket: client,
                                    remoteAddress: remoteAddress,
                                    securityLevel: securityLevel)
        
        // make socket non-blocking
        try newSocket.setNonblocking()
        
        return newSocket
    }
    
    /// Reads from the socket.
    public func recieve(_ bufferSize: Int = 1024) throws -> Data? {
        
        // check if reading buffer has data.
        guard try canRead()
            else { return nil }
        
        // read socket
        var buffer = [UInt8](repeating: 0, count: bufferSize)

        let actualByteCount = read(internalSocket, &buffer, bufferSize)

        guard actualByteCount >= 0 else {
            switch errno {
            case EINTR, EAGAIN:
                return nil
            default:
                throw POSIXError.fromErrno()
            }
        }
        
        let actualBytes = Array(buffer.prefix(actualByteCount))

        return Data(actualBytes)
    }
    
    /// Blocks until data is ready.
    public func waitForEvents(timeout: TimeInterval) {
        var pollData = pollfd(
            fd: internalSocket,
            events: Int16(POLLIN) & Int16(POLLOUT) & Int16(POLLPRI) & Int16(POLLERR) & Int16(POLLHUP) & Int16(POLLNVAL),
            revents: 0
        )
        poll(&pollData, 1, 0)
    }
    
    private func canRead() throws -> Bool {
        
        var readSockets = FileDescriptorSet()
        readSockets.zero()
        readSockets.add(internalSocket)
        
        var time = timeval()
        
        let fdCount = select(internalSocket + 1, &readSockets, nil, nil, &time)
        
        guard fdCount != -1
            else { throw POSIXError.fromErrno() }
                
        return fdCount > 0
    }
    
    private func setNonblocking() throws {
        
        var flags = fcntl(internalSocket, F_GETFL, 0)
        
        guard flags != -1
            else { throw POSIXError.fromErrno() }
        
        flags = fcntl(internalSocket, F_SETFL, flags | O_NONBLOCK);
        
        guard flags != -1
            else { throw POSIXError.fromErrno() }
    }
    
    /// Write to the socket.
    public func send(_ data: Data) throws {
        
        var buffer = Array(data)
        
        let actualByteCount = write(internalSocket, &buffer, buffer.count)
        
        guard actualByteCount >= 0
            else { throw POSIXError.fromErrno() }
        
        guard actualByteCount == buffer.count
            else { throw L2CAPSocketError.sentLessBytes(actualByteCount) }
    }
    
    /// Attempt to get L2CAP socket options.
    public func requestSocketOptions() throws -> Options {
        
        var optionValue = Options()
        var optionLength = socklen_t(MemoryLayout<Options>.size)
        
        guard getsockopt(internalSocket, SOL_L2CAP, L2CAP_OPTIONS, &optionValue, &optionLength) == 0
            else { throw POSIXError.fromErrno() }
        
        return optionValue
    }
}

// MARK: - Supporting Types
    
public extension L2CAPSocket {
    
    typealias Error = L2CAPSocketError
}

public enum L2CAPSocketError: Error {
    
    /// Sent less bytes than expected.
    case sentLessBytes(Int)
    
    /// The provided file descriptor was invalid
    case invalidFileDescriptor(CInt)
}

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
