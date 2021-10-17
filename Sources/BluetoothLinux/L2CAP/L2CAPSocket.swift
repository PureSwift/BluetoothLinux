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
public final class L2CAPSocket { //: L2CAPSocketProtocol {
    
    // MARK: - Properties
    
    /// The socket's security level.
    public private(set) var securityLevel: SecurityLevel

    // MARK: - Internal Properties
    
    /// Internal socket file descriptor
    internal let fileDesciptor: FileDescriptor
    
    /// Internal L2CAP Socket address
    public let address: L2CAPSocketAddress
    
    // MARK: - Initialization

    deinit {
        close(internalSocket)
    }
    
    /// Create a new L2CAP socket on the HostController with the specified identifier.
    public init(controllerAddress: BluetoothAddress,
                protocolServiceMultiplexer: ProtocolServiceMultiplexer? = nil,
                channelIdentifier: ChannelIdentifier = .att,
                addressType: AddressType? = .lowEnergyPublic,
                securityLevel: SecurityLevel = .low) throws {
        
        let (internalSocket, internalAddress) = try L2CAPSocket.createSocket(
            controllerAddress: controllerAddress,
            protocolServiceMultiplexer: UInt16(protocolServiceMultiplexer?.rawValue ?? 0),
            channelIdentifier: channelIdentifier.rawValue,
            addressType: addressType)
        
        // store values
        self.internalSocket = internalSocket
        self.internalAddress = internalAddress
        self.securityLevel = .sdp
        
        // configure socket
        try self.setSecurityLevel(securityLevel)
    }
    
    /// For new incoming connections for server.
    internal init(clientSocket: CInt,
                  remoteAddress: sockaddr_l2,
                  securityLevel: SecurityLevel) {
        
        self.internalSocket = clientSocket
        self.internalAddress = remoteAddress
        self.securityLevel = securityLevel
    }
    
    /// Creates a server socket for an L2CAP connection.
    public static func lowEnergyServer(controllerAddress: BluetoothAddress = .zero,
                                       isRandom: Bool = false,
                                       securityLevel: SecurityLevel = .low) throws -> L2CAPSocket {
        
        let socket = try L2CAPSocket(controllerAddress: controllerAddress,
                                     protocolServiceMultiplexer: nil,
                                     channelIdentifier: .att,
                                     addressType: isRandom ? .lowEnergyRandom : .lowEnergyPublic,
                                     securityLevel: securityLevel)
        
        try socket.startListening()
        return socket
    }
    
    /// Creates a client socket for an L2CAP connection.
    public static func lowEnergyClient(controllerAddress: BluetoothAddress = .zero,
                                       destination: (address: BluetoothAddress, type: AddressType),
                                       securityLevel: SecurityLevel = .low) throws -> L2CAPSocket {
        
        let socket = try L2CAPSocket(controllerAddress: controllerAddress,
                                     protocolServiceMultiplexer: nil,
                                     channelIdentifier: .att,
                                     addressType: nil,
                                     securityLevel: securityLevel)
        
        try socket.openConnection(to: destination.address, type: destination.type)
        return socket
    }
    
    // MARK: - Static Methods
    
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
    }
    
    /// Create the underlying socket for the L2CAP.
    @inline(__always)
    private static func createSocket(controllerAddress: BluetoothAddress,
                                     protocolServiceMultiplexer: UInt16,
                                     channelIdentifier: UInt16,
                                     addressType: AddressType?) throws -> (CInt, sockaddr_l2) {
        
        // open socket
        let internalSocket = socket(AF_BLUETOOTH,
                                    SOCK_SEQPACKET,
                                    BluetoothSocketProtocol.l2cap.rawValue)
        
        // error creating socket
        guard internalSocket >= 0
            else { throw POSIXError.fromErrno() }
        
        // set source address
        var localAddress = sockaddr_l2()
        memset(&localAddress, 0, MemoryLayout<sockaddr_l2>.size)
        localAddress.l2_family = sa_family_t(AF_BLUETOOTH)
        localAddress.l2_bdaddr = controllerAddress.littleEndian
        localAddress.l2_psm = protocolServiceMultiplexer.littleEndian
        localAddress.l2_cid = channelIdentifier.littleEndian
        localAddress.l2_bdaddr_type = addressType?.rawValue ?? 0
        
        // bind socket to port and address
        guard withUnsafeMutablePointer(to: &localAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1, {
                bind(internalSocket, $0, socklen_t(MemoryLayout<sockaddr_l2>.size)) == 0
            })
        }) else { close(internalSocket); throw POSIXError.fromErrno() }
        
        return (internalSocket, localAddress)
    }
    
    // MARK: - Accessors
    
    /// Bluetooth address
    public var address: BluetoothAddress {
        return BluetoothAddress(littleEndian: internalAddress.l2_bdaddr)
    }
    
    public var addressType: AddressType {
        return AddressType(rawValue: internalAddress.l2_bdaddr_type)!
    }
    
    /// Protocol/Service Multiplexer (PSM)
    public var protocolServiceMultiplexer: UInt16 {
        return UInt16(littleEndian: internalAddress.l2_psm)
    }
    
    /// Channel Identifier (CID)
    ///
    /// L2CAP channel endpoints are identified to their clients by a Channel Identifier (CID).
    /// This is assigned by L2CAP, and each L2CAP channel endpoint on any device has a different CID.
    public var channelIdentifier: ChannelIdentifier {
        
        return ChannelIdentifier(rawValue: UInt16(littleEndian: internalAddress.l2_cid))
    }

    // MARK: - Methods
    
    /// Attempts to change the socket's security level.
    public func setSecurityLevel(_ securityLevel: SecurityLevel) throws {
        
        // set security level
        var security = bt_security()
        security.level = securityLevel.rawValue
        
        guard setsockopt(internalSocket, SOL_BLUETOOTH, BT_SECURITY, &security, socklen_t(MemoryLayout<bt_security>.size)) == 0
            else { throw POSIXError.fromErrno() }
        
        self.securityLevel = securityLevel
    }
    
    /// Put socket into listening mode.
    public func startListening(queueLimit: Int = 10) throws {
        
        // put socket into listening mode
        guard listen(internalSocket, Int32(queueLimit)) == 0
            else { throw POSIXError.fromErrno() }
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
    
    /// Connect to another L2CAP server.
    public func openConnection(to address: BluetoothAddress,
                               type addressType: AddressType = .lowEnergyPublic) throws {
        
        // Set up destination address
        var destinationAddress = sockaddr_l2()
        memset(&destinationAddress, 0, MemoryLayout<sockaddr_l2>.size)
        destinationAddress.l2_family = sa_family_t(AF_BLUETOOTH)
        destinationAddress.l2_bdaddr = address.littleEndian
        destinationAddress.l2_psm = internalAddress.l2_psm
        destinationAddress.l2_cid = internalAddress.l2_cid
        destinationAddress.l2_bdaddr_type = addressType.rawValue
        
        guard withUnsafeMutablePointer(to: &destinationAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1, {
                connect(internalSocket, $0, socklen_t(MemoryLayout<sockaddr_l2>.size)) == 0
            })
        }) else { throw POSIXError.fromErrno() }
        
        // make socket non-blocking
        try setNonblocking()
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
