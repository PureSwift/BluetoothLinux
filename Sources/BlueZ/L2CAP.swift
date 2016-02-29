//
//  L2CAP.swift
//  BlueZ
//
//  Created by Alsey Coleman Miller on 2/28/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

#if os(Linux)
    import CBlueZ
    import Glibc
#elseif os(OSX) || os(iOS)
    import Darwin.C
#endif

import SwiftFoundation

/// L2CAP Bluetooth socket
public final class L2CAPSocket {

    // MARK: - Properties

    public lazy var address: Address = self.internalAddress.l2_bdaddr

    public lazy var addressType: AddressType = AddressType(rawValue: self.internalAddress.l2_bdaddr_type)!

    public lazy var port: UInt16 = self.internalAddress.l2_psm.currentEndian

    public lazy var channelIdentifier: UInt16 = self.internalAddress.l2_cid.currentEndian

    // MARK: - Internal Properties

    internal let internalSocket: CInt

    internal let internalAddress: sockaddr_l2

    // MARK: - Initialization

    deinit {

        close(internalSocket)
    }

    /// Create a new L2CAP server on the adapter with the specified identifier.
    public init(deviceIdentifier: CInt? = nil, port: UInt16 = 0, channelIdentifier: UInt16 = 0, addressType: AddressType = AddressType(), securityLevel: SecurityLevel = SecurityLevel()) throws {

        // get address

        let address: Address

        if let identifier = deviceIdentifier {

            do { address = try Address(deviceIdentifier: identifier) }

            catch {
                
                // must set values to satisfy compiler
                address = Address()
                self.internalSocket = 0
                self.internalAddress = sockaddr_l2()

                throw error
            }
            
        } else {

            address = Address(byteValue: (0, 0, 0, 0, 0, 0)) // BDADDR_ANY
        }

        // set address

        var localAddress = sockaddr_l2()
        
        memset(&localAddress, 0, sizeof(sockaddr_l2))
        
        localAddress.l2_family = sa_family_t(AF_BLUETOOTH)
        localAddress.l2_bdaddr = address
        localAddress.l2_psm = port.littleEndian
        localAddress.l2_cid = channelIdentifier.littleEndian
        localAddress.l2_bdaddr_type = addressType.rawValue

        self.internalAddress = localAddress

        // allocate socket
        self.internalSocket = socket(AF_BLUETOOTH, SOCK_SEQPACKET, BTPROTO_L2CAP)

        // error creating socket
        guard internalSocket >= 0 else { throw POSIXError.fromErrorNumber! }

        let socketLength = socklen_t(sizeof(sockaddr_l2))

        // bind socket to port and address
        guard withUnsafePointer(&localAddress, { bind(internalSocket, UnsafePointer<sockaddr>($0), socketLength) }) == 0
            else { close(internalSocket); throw POSIXError.fromErrorNumber! }
        
        // set security level
        var security = bt_security()
        security.level = securityLevel.rawValue
        
        guard setsockopt(internalSocket, SOL_BLUETOOTH, BT_SECURITY, &security, socklen_t(sizeof(bt_security))) == 0
            else { close(internalSocket); throw POSIXError.fromErrorNumber! }
        
        // put socket into listening mode
        guard listen(internalSocket, 10) == 0
            else { close(internalSocket); throw POSIXError.fromErrorNumber! }
    }

    /// For already opened client socket.
    internal init(clientSocket: CInt, remoteAddress: sockaddr_l2) {

        self.internalSocket = clientSocket
        self.internalAddress = remoteAddress
    }

    // MARK: - Methods

    /// Blocks the caller until a new connection is recieved.
    public func waitForConnection() throws -> L2CAPSocket {

        var remoteAddress = sockaddr_l2()

        var socketLength = socklen_t(sizeof(sockaddr_l2))
        
        // accept new client
        let client = withUnsafeMutablePointer(&remoteAddress, { accept(internalSocket, UnsafeMutablePointer<sockaddr>($0), &socketLength) })

        // error accepting new connection
        guard client == 0 else { throw POSIXError.fromErrorNumber! }

        return L2CAPSocket(clientSocket: client, remoteAddress: remoteAddress)
    }

    /// Reads from the socket.
    public func recieve(bufferSize: Int = 1024) throws -> Data {

        var buffer = [UInt8](count: bufferSize, repeatedValue: 0)

        let actualByteCount = read(internalSocket, &buffer, bufferSize)

        guard actualByteCount >= 0 else { throw POSIXError.fromErrorNumber! }

        let actualBytes =  Array(buffer.prefix(actualByteCount))

        return Data(byteValue: actualBytes)
    }

    /// Write to the socket.
    public func send(data: Data) throws {

        fatalError("Not implemented")
    }
}

// MARK: - Additional Constants

public let ATT_CID: CInt = 4

public let ATT_PSM: CInt = 31

// MARK: - Linux Support

#if os(Linux)

    public let SOCK_SEQPACKET: CInt = 5

#endif

// MARK: - Darwin Stubs

#if os(OSX) || os(iOS)

    let AF_BLUETOOTH: CInt = 31

    let BTPROTO_L2CAP: CInt = 0
    
    let SOL_BLUETOOTH: CInt = 274
    
    let BT_SECURITY: CInt = 4
    
    /// L2CAP socket address
    struct sockaddr_l2 {
        var l2_family: sa_family_t
        var l2_psm: CUnsignedShort
        var l2_bdaddr: bdaddr_t
        var l2_cid: CUnsignedShort
        var l2_bdaddr_type: UInt8
        init() { stub() }
    }
    
    /// Bluetooth security level
    struct bt_security {
        var level: UInt8
        var key_size: UInt8
        init() { stub() }
    }

#endif
