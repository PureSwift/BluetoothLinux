//
//  PeripheralTest.swift
//  BlueZ
//
//  Created by Alsey Coleman Miller on 2/28/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

#if os(Linux)
    import BlueZ
    import CBlueZ
    import Glibc
#elseif os(OSX) || os(iOS)
    import Darwin.C
#endif

import SwiftFoundation

func PeripheralTest(adapter: Adapter) {

    do {

        let ATT_CID: UInt16 = 4

        let ATT_PSM: UInt16 = 31
        
        let server = try L2CAPSocket(deviceIdentifier: adapter.identifier, channelIdentifier: ATT_CID, addressType: .LowEnergyPublic, securityLevel: .Low)

        print("Created L2CAP server")
        
        let newConnection = try server.waitForConnection()
        
        print("New \(newConnection.addressType) connection from \(newConnection.address)")
        
        let readData = try newConnection.recieve()
        
        print("Recieved data: \(String(UTF8Data: readData) ?? "<\(readData.byteValue.count) bytes>"))")
    }

    catch { Error("Error: \(error)") }
}

/*
func PeripheralTest(adapter: Adapter) {
    
    do {
        
        let port: UInt16 = 0x1001
        
        let address = try Address(deviceIdentifier: adapter.identifier)
        
        var localAddress = sockaddr_l2()
        localAddress.l2_family = sa_family_t(AF_BLUETOOTH)
        localAddress.l2_bdaddr = address
        localAddress.l2_psm = port.littleEndian
        
        // allocate socket
        let internalSocket = socket(AF_BLUETOOTH, SOCK_SEQPACKET, BTPROTO_L2CAP)
        
        // error creating socket
        guard internalSocket >= 0 else { throw POSIXError.fromErrorNumber! }
        
        var socketLength = socklen_t(sizeof(sockaddr_l2))
        
        // bind socket to port and address
        guard withUnsafePointer(&localAddress, { bind(internalSocket, UnsafePointer<sockaddr>($0), socketLength) }) == 0
            else { close(internalSocket); throw POSIXError.fromErrorNumber! }
        
        // put socket into listening mode
        guard listen(internalSocket, 10) == 0
            else { close(internalSocket); throw POSIXError.fromErrorNumber! }
        
        print("Created L2CAP server")
        
        ///
        
        var remoteAddressPointer = UnsafeMutablePointer<sockaddr_l2>.alloc(1)
        
        defer { remoteAddressPointer.dealloc(1) }
        
        // accept new client
        let client = accept(internalSocket, UnsafeMutablePointer<sockaddr>(remoteAddressPointer), &socketLength)
        
        // error accepting new connection
        guard client == 0 else { throw POSIXError.fromErrorNumber! }
        
        print("New connection from \(remoteAddressPointer.memory.l2_bdaddr)")
        
        ///
        
        let bufferSize = 1024
        
        var buffer = [UInt8](count: bufferSize, repeatedValue: 0)
        
        let actualByteCount = read(internalSocket, &buffer, bufferSize)
        
        guard actualByteCount >= 0 else { throw POSIXError.fromErrorNumber! }
        
        let actualBytes =  Array(buffer.prefix(actualByteCount))
        
        let readData = Data(byteValue: actualBytes)
        
        print("Recieved data: \(String(UTF8Data: readData) ?? "<\(readData.byteValue.count) bytes>"))")
        
        close(internalSocket)
        
        close(client)
    }
        
    catch { Error("Error: \(error)") }
}
*/

