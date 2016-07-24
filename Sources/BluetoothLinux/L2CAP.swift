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

import SwiftFoundation
import Bluetooth

/// L2CAP Bluetooth socket
public final class L2CAPSocket {

    // MARK: - Properties

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

    /// Create a new L2CAP server on the adapter with the specified identifier.
    public init(adapterAddress: Address, protocolServiceMultiplexer: UInt16 = 0, channelIdentifier: UInt16 = 0, addressType: AddressType = AddressType(), securityLevel: SecurityLevel = SecurityLevel()) throws {
        
        // set properties
        self.securityLevel = securityLevel

        // get address

        let address = adapterAddress ?? Address(bytes: (0, 0, 0, 0, 0, 0)) // BDADDR_ANY

        // set address

        var localAddress = sockaddr_l2()
        
        memset(&localAddress, 0, sizeof(sockaddr_l2.self))
        
        localAddress.l2_family = sa_family_t(AF_BLUETOOTH)
        localAddress.l2_bdaddr = address
        localAddress.l2_psm = protocolServiceMultiplexer.littleEndian
        localAddress.l2_cid = channelIdentifier.littleEndian
        localAddress.l2_bdaddr_type = addressType.rawValue

        self.internalAddress = localAddress

        // allocate socket
        self.internalSocket = socket(AF_BLUETOOTH, SOCK_SEQPACKET, BTPROTO_L2CAP)

        // error creating socket
        guard internalSocket >= 0 else { throw POSIXError.fromErrno! }

        let socketLength = socklen_t(sizeof(sockaddr_l2.self))

        // bind socket to port and address
        guard withUnsafePointer(&localAddress, { bind(internalSocket, UnsafePointer<sockaddr>($0), socketLength) }) == 0
            else { close(internalSocket); throw POSIXError.fromErrno! }
        
        // set security level
        var security = bt_security()
        security.level = securityLevel.rawValue
        
        guard setsockopt(internalSocket, SOL_BLUETOOTH, BT_SECURITY, &security, socklen_t(sizeof(bt_security.self))) == 0
            else { close(internalSocket); throw POSIXError.fromErrno! }
        
        // put socket into listening mode
        guard listen(internalSocket, 10) == 0
            else { close(internalSocket); throw POSIXError.fromErrno! }
    }

    /// For new incoming connections for server.
    internal init(clientSocket: CInt, remoteAddress: sockaddr_l2, securityLevel: SecurityLevel) {

        self.internalSocket = clientSocket
        self.internalAddress = remoteAddress
        self.securityLevel = securityLevel
    }

    // MARK: - Methods
    
    /// Attempts to change the socket's security level.
    public func setSecurityLevel(_ securityLevel: SecurityLevel) throws {
        
        // set security level
        var security = bt_security()
        security.level = securityLevel.rawValue
        
        guard setsockopt(internalSocket, SOL_BLUETOOTH, BT_SECURITY, &security, socklen_t(sizeof(bt_security.self))) == 0
            else { throw POSIXError.fromErrno! }
    }

    /// Blocks the caller until a new connection is recieved.
    public func waitForConnection() throws -> L2CAPSocket {

        var remoteAddress = sockaddr_l2()

        var socketLength = socklen_t(sizeof(sockaddr_l2.self))
        
        // accept new client
        let client = withUnsafeMutablePointer(&remoteAddress, { accept(internalSocket, UnsafeMutablePointer<sockaddr>($0), &socketLength) })

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
        
        var buffer = data.bytes
        
        let actualByteCount = write(internalSocket, &buffer, buffer.count)
        
        guard actualByteCount >= 0
            else { throw POSIXError.fromErrno! }
        
        guard actualByteCount == buffer.count
            else { throw L2CAPSocketError.SentLessBytes(actualByteCount) }
    }
}

// MARK: - Supporting Types
    
public extension L2CAPSocket {
    
    public typealias Error = L2CAPSocket
}

public enum L2CAPSocketError: Error {
    
    /// Sent less bytes than expected.
    case SentLessBytes(Int)
}

// MARK: - Internal Supporting Types

let AF_BLUETOOTH: CInt = 31

let BTPROTO_L2CAP: CInt = 0

let SOL_BLUETOOTH: CInt = 274

let BT_SECURITY: CInt = 4

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

