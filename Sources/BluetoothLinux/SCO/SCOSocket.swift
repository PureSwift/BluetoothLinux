//
//  SCOSocket.swift
//  BluetoothLinux
//

import Foundation
import Bluetooth
import SystemPackage
import Socket

/// Bluetooth SCO Socket
///
/// Synchronous Connection Oriented links carry voice audio
/// between the host and a connected classic (BR/EDR) device.
public struct SCOSocket: Sendable {

    // MARK: - Properties

    @usableFromInline
    internal let fileDescriptor: SocketDescriptor

    /// Socket address.
    public let address: SCOSocketAddress

    // MARK: - Initialization

    internal init(
        fileDescriptor: SocketDescriptor,
        address: SCOSocketAddress
    ) {
        self.fileDescriptor = fileDescriptor
        self.address = address
    }

    /// Create a new SCO socket bound to the specified address.
    public init(address: SCOSocketAddress) throws(Errno) {
        self.fileDescriptor = try .sco(address, [.closeOnExec, .nonBlocking])
        self.address = address
    }

    /// Creates a client socket connected to the specified remote device.
    ///
    /// - Note: An ACL connection to the remote device must already exist,
    ///   and a non-default air coding format (``BluetoothSocketOption/Voice``)
    ///   must be configured before connecting.
    public static func client(
        address localAddress: BluetoothAddress,
        destination destinationAddress: BluetoothAddress,
        voice: BluetoothSocketOption.Voice? = nil
    ) throws(Errno) -> Self {
        let localSocketAddress = SCOSocketAddress(address: localAddress)
        let destinationSocketAddress = SCOSocketAddress(address: destinationAddress)
        let fileDescriptor = try SocketDescriptor.sco(localSocketAddress, [.closeOnExec, .nonBlocking])

        // configure the air coding format before connecting
        if let voice {
            do {
                try fileDescriptor.setSocketOption(voice)
            } catch {
                try? fileDescriptor.close()
                throw error
            }
        }

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

    /// Creates a server socket listening on the specified address.
    public static func server(
        address: BluetoothAddress,
        backlog: Int = Socket.maxBacklog
    ) throws(Errno) -> Self {
        let socketAddress = SCOSocketAddress(address: address)
        let fileDescriptor = try SocketDescriptor.sco(socketAddress, [.closeOnExec, .nonBlocking])
        try fileDescriptor.closeIfThrows { () throws(Errno) -> () in
            try fileDescriptor.listen(backlog: backlog)
        }
        return Self.init(fileDescriptor: fileDescriptor, address: socketAddress)
    }

    // MARK: - Methods

    /// Close socket.
    public func close() {
        try? fileDescriptor.close()
    }

    /// Attempt to accept an incoming connection.
    public func accept() throws(Errno) -> Self {
        let (fileDescriptor, address) = try self.fileDescriptor.accept(SCOSocketAddress.self)
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

    // MARK: - Options

    /// Socket options (maximum transmission unit).
    public var options: SCOSocketOption.Options {
        get throws(Errno) {
            try fileDescriptor.getSocketOption(SCOSocketOption.Options.self)
        }
    }

    /// Connection information (handle and device class).
    public var connectionInfo: SCOSocketOption.ConnectionInfo {
        get throws(Errno) {
            try fileDescriptor.getSocketOption(SCOSocketOption.ConnectionInfo.self)
        }
    }

    /// The voice setting (air coding format) of the socket.
    public var voice: BluetoothSocketOption.Voice {
        get throws(Errno) {
            try fileDescriptor.getSocketOption(BluetoothSocketOption.Voice.self)
        }
    }

    /// Set the voice setting (air coding format) of the socket.
    ///
    /// Must be configured before the connection is established.
    public func setVoice(_ voice: BluetoothSocketOption.Voice) throws(Errno) {
        try fileDescriptor.setSocketOption(voice)
    }
}
