//
//  L2CAPSocket+Classic.swift
//  BluetoothLinux
//
//  Classic (BR/EDR) L2CAP connection conveniences.
//

import Foundation
import Bluetooth
import BluetoothHCI
import SystemPackage
import Socket

public extension L2CAPSocket {

    /// Creates a client socket for a classic (BR/EDR) L2CAP connection.
    ///
    /// - Parameter protocolServiceMultiplexer: The protocol/service multiplexer (PSM)
    ///   of the service on the remote device (e.g. ``ProtocolServiceMultiplexer/bnep``).
    static func classicClient(
        address localAddress: BluetoothAddress,
        destination destinationAddress: BluetoothAddress,
        protocolServiceMultiplexer: ProtocolServiceMultiplexer
    ) throws(Errno) -> Self {
        let localSocketAddress = L2CAPSocketAddress(
            address: localAddress,
            addressType: nil,
            protocolServiceMultiplexer: nil,
            channel: 0
        )
        let destinationSocketAddress = L2CAPSocketAddress(
            address: destinationAddress,
            addressType: nil,
            protocolServiceMultiplexer: protocolServiceMultiplexer,
            channel: 0
        )
        return try connect(
            local: localSocketAddress,
            destination: destinationSocketAddress
        )
    }

    /// Creates a client socket for a classic (BR/EDR) L2CAP connection.
    static func classicClient(
        hostController: HostController,
        destination: BluetoothAddress,
        protocolServiceMultiplexer: ProtocolServiceMultiplexer
    ) async throws -> Self {
        let localAddress = try await hostController.readDeviceAddress()
        return try classicClient(
            address: localAddress,
            destination: destination,
            protocolServiceMultiplexer: protocolServiceMultiplexer
        )
    }

    /// Creates a server socket for a classic (BR/EDR) L2CAP connection.
    static func classicServer(
        address: BluetoothAddress,
        protocolServiceMultiplexer: ProtocolServiceMultiplexer,
        backlog: Int = Socket.maxBacklog
    ) throws(Errno) -> Self {
        let address = L2CAPSocketAddress(
            address: address,
            addressType: nil,
            protocolServiceMultiplexer: protocolServiceMultiplexer,
            channel: 0
        )
        let fileDescriptor = try SocketDescriptor.l2cap(address, [.closeOnExec, .nonBlocking])
        try fileDescriptor.closeIfThrows { () throws(Errno) -> () in
            try fileDescriptor.listen(backlog: backlog)
        }
        return Self.init(fileDescriptor: fileDescriptor, address: address)
    }

    /// Creates a server socket for a classic (BR/EDR) L2CAP connection.
    static func classicServer(
        hostController: HostController,
        protocolServiceMultiplexer: ProtocolServiceMultiplexer,
        backlog: Int = Socket.maxBacklog
    ) async throws -> Self {
        let address = try await hostController.readDeviceAddress()
        return try classicServer(
            address: address,
            protocolServiceMultiplexer: protocolServiceMultiplexer,
            backlog: backlog
        )
    }

    /// Creates a socket and connects to the destination, waiting until the
    /// non-blocking connection completes.
    internal static func connect(
        local localSocketAddress: L2CAPSocketAddress,
        destination destinationSocketAddress: L2CAPSocketAddress
    ) throws(Errno) -> Self {
        let fileDescriptor = try SocketDescriptor.l2cap(localSocketAddress, [.closeOnExec, .nonBlocking])

        // Start async connect - for non-blocking sockets this returns EINPROGRESS
        do {
            try fileDescriptor.connect(to: destinationSocketAddress)
        } catch Errno.nowInProgress {
            // Expected for non-blocking socket - connection is in progress
            // Wait for socket to become writable (indicates connect completed)
            let timeout: Int = 30_000  // 30 seconds in milliseconds
            let events = try fileDescriptor.poll(for: [.write, .error, .hangup], timeout: timeout)

            // Check for errors
            if events.contains(.error) || events.contains(.hangup) {
                try? fileDescriptor.close()
                throw Errno.connectionRefused
            }

            // Check if we timed out (no events returned)
            if !events.contains(.write) {
                try? fileDescriptor.close()
                throw Errno.timedOut
            }
        } catch {
            // Other errors during connect
            try? fileDescriptor.close()
            throw error
        }

        return Self.init(fileDescriptor: fileDescriptor, address: localSocketAddress)
    }
}

// MARK: - Server

public extension L2CAPSocket.Server {

    /// Creates a server socket for a classic (BR/EDR) L2CAP connection.
    static func classicServer(
        address: BluetoothAddress,
        protocolServiceMultiplexer: ProtocolServiceMultiplexer,
        backlog: Int = Socket.maxBacklog
    ) throws(Errno) -> L2CAPSocket.Server {
        let socket = try L2CAPSocket.classicServer(
            address: address,
            protocolServiceMultiplexer: protocolServiceMultiplexer,
            backlog: backlog
        )
        return Self.init(socket: socket)
    }
}

// MARK: - Connection

public extension L2CAPSocket.Connection {

    /// Creates a client socket for a classic (BR/EDR) L2CAP connection.
    static func classicClient(
        address: BluetoothAddress,
        destination: BluetoothAddress,
        protocolServiceMultiplexer: ProtocolServiceMultiplexer
    ) throws(Errno) -> Self {
        let socket = try L2CAPSocket.classicClient(
            address: address,
            destination: destination,
            protocolServiceMultiplexer: protocolServiceMultiplexer
        )
        return .init(socket: socket, destination: destination)
    }
}
