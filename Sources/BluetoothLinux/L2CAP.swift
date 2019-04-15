//
//  L2CAP.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 2/28/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

#if os(Linux)
    import Glibc
#elseif os(OSX) || os(iOS)
    import Darwin.C
#endif

import Foundation
import Bluetooth
import CSwiftBluetoothLinux

/// L2CAP Bluetooth socket
public final class L2CAPSocket: L2CAPSocketProtocol {
    
    // MARK: - Properties
    
    /// The socket's security level.
    public private(set) var securityLevel: SecurityLevel

    // MARK: - Internal Properties
    
    /// Internal socket file descriptor
    internal let internalSocket: CInt
    
    /// Internal L2CAP Socket address
    internal let internalAddress: sockaddr_l2
    
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
                else { throw POSIXError.fromErrno! }
            
            return optionValue
        }
        
        //. socket domain and protocol
        guard try value(for: SO_DOMAIN) == AF_BLUETOOTH,
            try value(for: SO_PROTOCOL) == BluetoothProtocol.l2cap.rawValue
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
                                    BluetoothProtocol.l2cap.rawValue)
        
        // error creating socket
        guard internalSocket >= 0
            else { throw POSIXError.fromErrno! }
        
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
        }) else { close(internalSocket); throw POSIXError.fromErrno! }
        
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
            else { throw POSIXError.fromErrno! }
        
        self.securityLevel = securityLevel
    }
    
    /// Put socket into listening mode.
    public func startListening(queueLimit: Int = 10) throws {
        
        // put socket into listening mode
        guard listen(internalSocket, Int32(queueLimit)) == 0
            else { throw POSIXError.fromErrno! }
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
        guard client >= 0 else { throw POSIXError.fromErrno! }

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
        }) else { throw POSIXError.fromErrno! }
        
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
            if let error = POSIXError.fromErrno {
                throw error
            } else {
                return nil
            }
        }

        let actualBytes = Array(buffer.prefix(actualByteCount))

        return Data(actualBytes)
    }
    
    private func canRead() throws -> Bool {
        
        var readSockets = FileDescriptorSet()
        readSockets.zero()
        readSockets.add(internalSocket)
        
        var time = timeval()
        
        let fdCount = select(internalSocket + 1, &readSockets, nil, nil, &time)
        
        guard fdCount != -1
            else { throw POSIXError.fromErrno! }
                
        return fdCount > 0
    }
    
    private func setNonblocking() throws {
        
        var flags = fcntl(internalSocket, F_GETFL, 0)
        
        guard flags != -1
            else { throw POSIXError.fromErrno! }
        
        flags = fcntl(internalSocket, F_SETFL, flags | O_NONBLOCK);
        
        guard flags != -1
            else { throw POSIXError.fromErrno! }
    }
    
    /// Write to the socket.
    public func send(_ data: Data) throws {
        
        var buffer = Array(data)
        
        let actualByteCount = write(internalSocket, &buffer, buffer.count)
        
        guard actualByteCount >= 0
            else { throw POSIXError.fromErrno! }
        
        guard actualByteCount == buffer.count
            else { throw L2CAPSocketError.sentLessBytes(actualByteCount) }
    }
    
    /// Attempt to get L2CAP socket options.
    public func requestSocketOptions() throws -> Options {
        
        var optionValue = Options()
        var optionLength = socklen_t(MemoryLayout<Options>.size)
        
        guard getsockopt(internalSocket, SOL_L2CAP, L2CAP_OPTIONS, &optionValue, &optionLength) == 0
            else { throw POSIXError.fromErrno! }
        
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
    
    /// L2CAP Socket Options
    struct Options {
        
        public var outputMaximumTransmissionUnit: UInt16 // omtu
        public var inputMaximumTransmissionUnit: UInt16 // imtu
        public var flushTo: UInt16 // flush_to
        public var mode: UInt8
        public var fcs: UInt8
        public var maxTX: UInt8 // max_tx
        public var txwinSize: UInt8 // txwin_size
        
        fileprivate init() {
            
            self.outputMaximumTransmissionUnit = 0
            self.inputMaximumTransmissionUnit = 0
            self.flushTo = 0
            self.mode = 0
            self.fcs = 0
            self.maxTX = 0
            self.txwinSize = 0
        }
    }
    
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

// MARK: - Internal Supporting Types

let AF_BLUETOOTH: CInt = 31

//let BTPROTO_L2CAP: CInt = 0 // BluetoothProtocol.L2CAP

let SOL_BLUETOOTH: CInt = 274

let BT_SECURITY: CInt = 4

let BT_FLUSHABLE: CInt = 8

let SOL_L2CAP: CInt	= 6

let L2CAP_OPTIONS: CInt = 0x01

/// L2CAP socket address (not packed)
struct sockaddr_l2 {
    var l2_family: sa_family_t = 0
    var l2_psm: CUnsignedShort = 0
    var l2_bdaddr: BluetoothAddress = .zero
    var l2_cid: CUnsignedShort = 0
    var l2_bdaddr_type: UInt8 = 0
    init() { }
}

/// Bluetooth security level (not packed)
struct bt_security {
    var level: UInt8 = 0
    var key_size: UInt8 = 0
    init() { }
}

// MARK: - Linux Support

#if os(Linux)
    
let SOCK_SEQPACKET: CInt = CInt(Glibc.SOCK_SEQPACKET.rawValue)

#endif

// MARK: - OS X support

#if os(macOS)
    
let SO_PROTOCOL: CInt = 38
    
let SO_DOMAIN: CInt = 39

#endif
