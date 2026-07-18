//
//  ISOSocket.swift
//  BluetoothLinux
//

import Foundation
import Bluetooth
import SystemPackage
import Socket

/// Bluetooth ISO Socket
///
/// Isochronous channels carry time-sensitive audio data between the host
/// and Low Energy devices (LE Audio). Requires kernel 6.0 or later; on older
/// kernels the ISO socket is gated behind an experimental feature toggled
/// via the management interface.
public struct ISOSocket: Sendable {

    // MARK: - Properties

    @usableFromInline
    internal let fileDescriptor: SocketDescriptor

    /// Socket address.
    public let address: ISOSocketAddress

    // MARK: - Initialization

    internal init(
        fileDescriptor: SocketDescriptor,
        address: ISOSocketAddress
    ) {
        self.fileDescriptor = fileDescriptor
        self.address = address
    }

    /// Create a new ISO socket bound to the specified address.
    public init(address: ISOSocketAddress) throws(Errno) {
        self.fileDescriptor = try .iso(address, [.closeOnExec, .nonBlocking])
        self.address = address
    }

    /// Creates a client socket connected to the specified remote device.
    ///
    /// - Note: The quality of service must be configured before connecting
    ///   when using non-default stream parameters.
    public static func client(
        address localAddress: ISOSocketAddress,
        destination destinationAddress: ISOSocketAddress,
        qualityOfService: BluetoothSocketOption.ISOQualityOfService? = nil
    ) throws(Errno) -> Self {
        let fileDescriptor = try SocketDescriptor.iso(localAddress, [.closeOnExec, .nonBlocking])

        // configure stream parameters before connecting
        if let qualityOfService {
            do {
                try fileDescriptor.setSocketOption(qualityOfService)
            } catch {
                try? fileDescriptor.close()
                throw error
            }
        }

        // Start async connect - for non-blocking sockets this returns EINPROGRESS
        do {
            try fileDescriptor.connect(to: destinationAddress)
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

        return Self.init(fileDescriptor: fileDescriptor, address: localAddress)
    }

    /// Creates a server socket listening on the specified address.
    public static func server(
        address: ISOSocketAddress,
        backlog: Int = Socket.maxBacklog
    ) throws(Errno) -> Self {
        let fileDescriptor = try SocketDescriptor.iso(address, [.closeOnExec, .nonBlocking])
        try fileDescriptor.closeIfThrows { () throws(Errno) -> () in
            try fileDescriptor.listen(backlog: backlog)
        }
        return Self.init(fileDescriptor: fileDescriptor, address: address)
    }

    // MARK: - Methods

    /// Close socket.
    public func close() {
        try? fileDescriptor.close()
    }

    /// Attempt to accept an incoming connection.
    public func accept() throws(Errno) -> Self {
        let (fileDescriptor, address) = try self.fileDescriptor.accept(ISOSocketAddress.self)
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

    /// The quality of service of the socket.
    public var qualityOfService: BluetoothSocketOption.ISOQualityOfService {
        get throws(Errno) {
            try fileDescriptor.getSocketOption(BluetoothSocketOption.ISOQualityOfService.self)
        }
    }

    /// Set the quality of service of the socket.
    ///
    /// Must be configured before the connection is established.
    public func setQualityOfService(_ qualityOfService: BluetoothSocketOption.ISOQualityOfService) throws(Errno) {
        try fileDescriptor.setSocketOption(qualityOfService)
    }
}
