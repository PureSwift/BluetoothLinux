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

/// L2CAP Bluetooth Server socket
public final class L2CAPServer {
    
    // MARK: - Properties
    
    // MARK: - Internal Properties
    
    internal let internalSocket: CInt
    
    // MARK: - Initialization
    
    deinit {
        
        close(internalSocket)
    }
    
    /// Create a new L2CAP server on the adapter with the specified address.
    public init(address: Address? = nil, port: CUnsignedShort = 0x1001) throws {
        
        // allocate socket
        self.internalSocket = socket(AF_BLUETOOTH, SOCK_SEQPACKET, BTPROTO_L2CAP)
        
        // error creating socket
        guard internalSocket == 0 else { throw POSIXError.fromErrorNumber! }
        
        
        var localAddress = sockaddr_l2()
        localAddress.l2_family = sa_family_t(AF_BLUETOOTH)
        localAddress.l2_psm = port
        localAddress.l2_bdaddr = address ?? Address(byteValue: (0, 0, 0, 0, 0, 0)) // BDADDR_ANY
        
        let socketLength = socklen_t(sizeof(sockaddr_l2))
        
        // bind socket to port and address
        guard withUnsafePointer(&localAddress, { bind(internalSocket, UnsafePointer<sockaddr>($0), socketLength) }) == 0
            else { close(internalSocket); throw POSIXError.fromErrorNumber! }
        
        
        
    }
}


// MARK: - Darwin Stubs

#if os(OSX) || os(iOS)
    
    let AF_BLUETOOTH: CInt = 31
    
    let BTPROTO_L2CAP: CInt = 0
    
    /// L2CAP socket address
    struct sockaddr_l2 {
        var l2_family: sa_family_t
        var l2_psm: CUnsignedShort
        var l2_bdaddr: bdaddr_t
        var l2_cid: CUnsignedShort
        var l2_bdaddr_type: UInt8
        init() { stub() }
    }
    
    

#endif
