//
//  RFCOMMSocket.swift
//  BluetoothLinux
//

import Foundation
import Bluetooth
import SystemPackage
import Socket

/// Bluetooth RFCOMM Socket
///
/// Stream socket providing serial port emulation over L2CAP.
public struct RFCOMMSocket: Sendable {

    // MARK: - Properties

    @usableFromInline
    internal let fileDescriptor: SocketDescriptor

    /// Socket address.
    public let address: RFCOMMSocketAddress

    // MARK: - Initialization

    internal init(
        fileDescriptor: SocketDescriptor,
        address: RFCOMMSocketAddress
    ) {
        self.fileDescriptor = fileDescriptor
        self.address = address
    }

    /// Create a new RFCOMM socket bound to the specified address.
    public init(address: RFCOMMSocketAddress) throws(Errno) {
        self.fileDescriptor = try .rfcomm(address, [.closeOnExec, .nonBlocking])
        self.address = address
    }

    /// Creates a client socket connected to the specified remote device and channel.
    ///
    /// - Parameter channel: The RFCOMM channel of the service on the remote device (1-30),
    ///   typically discovered via its service record.
    public static func client(
        address localAddress: BluetoothAddress,
        destination destinationAddress: BluetoothAddress,
        channel: UInt8
    ) throws(Errno) -> Self {
        let localSocketAddress = RFCOMMSocketAddress(
            address: localAddress,
            channel: 0
        )
        let destinationSocketAddress = RFCOMMSocketAddress(
            address: destinationAddress,
            channel: channel
        )
        let fileDescriptor = try SocketDescriptor.rfcomm(localSocketAddress, [.closeOnExec, .nonBlocking])

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

    /// Creates a server socket listening on the specified address and channel.
    ///
    /// - Parameter channel: The RFCOMM channel to listen on (1-30).
    public static func server(
        address: BluetoothAddress,
        channel: UInt8,
        backlog: Int = Socket.maxBacklog
    ) throws(Errno) -> Self {
        let socketAddress = RFCOMMSocketAddress(
            address: address,
            channel: channel
        )
        let fileDescriptor = try SocketDescriptor.rfcomm(socketAddress, [.closeOnExec, .nonBlocking])
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
        let (fileDescriptor, address) = try self.fileDescriptor.accept(RFCOMMSocketAddress.self)
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

    /// Connection information (handle and device class).
    public var connectionInfo: RFCOMMSocketOption.ConnectionInfo {
        get throws(Errno) {
            try fileDescriptor.getSocketOption(RFCOMMSocketOption.ConnectionInfo.self)
        }
    }

    /// The link mode of the socket.
    public var linkMode: RFCOMMSocketOption.LinkMode {
        get throws(Errno) {
            try fileDescriptor.getSocketOption(RFCOMMSocketOption.LinkMode.self)
        }
    }

    /// Set the link mode of the socket.
    public func setLinkMode(_ linkMode: RFCOMMSocketOption.LinkMode) throws(Errno) {
        try fileDescriptor.setSocketOption(linkMode)
    }

    /// The security level of the socket.
    public var security: BluetoothSocketOption.Security {
        get throws(Errno) {
            try fileDescriptor.getSocketOption(BluetoothSocketOption.Security.self)
        }
    }

    /// Set the security level of the socket.
    public func setSecurity(_ security: BluetoothSocketOption.Security) throws(Errno) {
        try fileDescriptor.setSocketOption(security)
    }
}
