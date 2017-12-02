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

/// L2CAP Bluetooth socket
public final class L2CAPSocket {

    // MARK: - Properties
    
    /// The socket's security level.
    public private(set) var securityLevel: SecurityLevel

    // MARK: - Internal Properties
    
    /// Internal socket file descriptor
    internal let internalSocket: CInt
    
    /// Internal L2CAP Socket address
    internal let internalAddress: sockaddr_l2
    
    /// Whether the socket object "owns" the socket file descriptor
    /// and should close it upon deallocation.
    internal let isSocketOwner: Bool
    
    // MARK: - Initialization

    deinit {

        if isSocketOwner { close(internalSocket) }
    }

    /// Create a new L2CAP server on the adapter with the specified identifier.
    public init(adapterAddress: Address,
                protocolServiceMultiplexer: UInt16 = 0,
                channelIdentifier: UInt16 = 0,
                addressType: AddressType = AddressType(),
                securityLevel: SecurityLevel = SecurityLevel()) throws {
        
        // set properties
        self.securityLevel = securityLevel

        // set address

        var localAddress = sockaddr_l2()
        
        memset(&localAddress, 0, MemoryLayout<sockaddr_l2>.size)
        
        localAddress.l2_family = sa_family_t(AF_BLUETOOTH)
        localAddress.l2_bdaddr = adapterAddress
        localAddress.l2_psm = protocolServiceMultiplexer.littleEndian
        localAddress.l2_cid = channelIdentifier.littleEndian
        localAddress.l2_bdaddr_type = addressType.rawValue

        self.internalAddress = localAddress

        // allocate socket
        let internalSocket = socket(AF_BLUETOOTH, SOCK_SEQPACKET, BluetoothProtocol.L2CAP.rawValue)
        self.internalSocket = internalSocket
        self.isSocketOwner = true

        // error creating socket
        guard internalSocket >= 0 else { throw POSIXError.fromErrno! }

        let socketLength = socklen_t(MemoryLayout<sockaddr_l2>.size)

        // bind socket to port and address
        guard withUnsafeMutablePointer(to: &localAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1, {
                bind(internalSocket, $0, socketLength) == 0
            })
        }) else { close(internalSocket); throw POSIXError.fromErrno! }
        
        // set security level
        var security = bt_security()
        security.level = securityLevel.rawValue
        
        guard setsockopt(internalSocket, SOL_BLUETOOTH, BT_SECURITY, &security, socklen_t(MemoryLayout<bt_security>.size)) == 0
            else { close(internalSocket); throw POSIXError.fromErrno! }
        
        // put socket into listening mode
        guard listen(internalSocket, 10) == 0
            else { close(internalSocket); throw POSIXError.fromErrno! }
    }

    /// For new incoming connections for server.
    internal init(clientSocket: CInt,
                  remoteAddress: sockaddr_l2,
                  securityLevel: SecurityLevel) {

        self.internalSocket = clientSocket
        self.internalAddress = remoteAddress
        self.securityLevel = securityLevel
        self.isSocketOwner = true
    }
    /*
    /// Create L2CAP socket from file descriptor provided by external API like HCI controller.
    public init?(fileDescriptor: CInt,
                 isSocketOwner: Bool = true) throws {
        
        guard try L2CAPSocket.validate(fileDescriptor: fileDescriptor)
            else { return nil }
        
        self.internalSocket = fileDescriptor
        self.isSocketOwner = isSocketOwner
        
    }*/
    
    // MARK: - Accessors
    
    /// Bluetooth address
    public var address: Address {
        
        return internalAddress.l2_bdaddr
    }
    
    public var addressType: AddressType {
        
        return AddressType(rawValue: internalAddress.l2_bdaddr_type)!
    }
    
    /// Protocol/Service Multiplexer (PSM)
    public var protocolServiceMultiplexer: UInt16 {
        
        return internalAddress.l2_psm.currentEndian
    }
    
    /// Channel Identifier (CID)
    ///
    /// L2CAP channel endpoints are identified to their clients by a Channel Identifier (CID).
    /// This is assigned by L2CAP, and each L2CAP channel endpoint on any device has a different CID.
    public var channelIdentifier: UInt16 {
        
        return internalAddress.l2_cid.currentEndian
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
        
        //. socket doman and protocol
        guard try value(for: SO_DOMAIN) == AF_BLUETOOTH,
            try value(for: SO_PROTOCOL) == BluetoothProtocol.L2CAP.rawValue
            else { return false }
        
        return true
    }

    // MARK: - Methods
    
    /// Attempts to change the socket's security level.
    public func setSecurityLevel(_ securityLevel: SecurityLevel) throws {
        
        // set security level
        var security = bt_security()
        security.level = securityLevel.rawValue
        
        guard setsockopt(internalSocket, SOL_BLUETOOTH, BT_SECURITY, &security, socklen_t(MemoryLayout<bt_security>.size)) == 0
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

        return L2CAPSocket(clientSocket: client, remoteAddress: remoteAddress, securityLevel: securityLevel)
    }

    /// Reads from the socket.
    public func recieve(_ bufferSize: Int = 1024) throws -> Data {

        var buffer = [UInt8](repeating: 0, count: bufferSize)

        let actualByteCount = read(internalSocket, &buffer, bufferSize)

        guard actualByteCount >= 0 else { throw POSIXError.fromErrno! }

        let actualBytes = Array(buffer.prefix(actualByteCount))

        return Data(bytes: actualBytes)
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
    
    public typealias Error = L2CAPSocket
}

public enum L2CAPSocketError: Error {
    
    /// Sent less bytes than expected.
    case sentLessBytes(Int)
    
    /// The provided file descriptor was invalid
    case invalidFileDescriptor(CInt)
    
    case connectionError()
}

public extension L2CAPSocket {
    
    /// L2CAP Socket Options
    public struct Options {
        
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
    
    public enum ConnectionResult: UInt16 {
        
        case success    = 0x0000
        case pending    = 0x0001
        case badPSM     = 0x0002
        case secBlock   = 0x0003
        case noMemory   = 0x0004
    }
    
    public enum ConnectionStatus: UInt16 {
        
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
    var l2_bdaddr: Address = Address()
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
    
    public let SOCK_SEQPACKET: CInt = 5
    
#endif

// MARK: - OS X support

#if os(macOS)
    
let SO_PROTOCOL: CInt = 38
    
let SO_DOMAIN: CInt = 39
    
#endif
