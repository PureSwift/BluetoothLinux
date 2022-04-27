//
//  FileDescriptor.swift
//  
//
//  Created by Alsey Coleman Miller on 16/10/21.
//

import Foundation
import Bluetooth
import BluetoothHCI
import SystemPackage
import Socket

internal extension SocketDescriptor {
    
    @usableFromInline
    static func bluetooth(
        _ socketProtocol: BluetoothSocketProtocol,
        flags: SocketFlags = [.closeOnExec]
    ) throws -> SocketDescriptor {
        return try self.init(
            socketProtocol,
            flags: flags
        )
    }
    
    @usableFromInline
    static func bluetooth<Address: BluetoothSocketAddress>(
        _ socketProtocol: BluetoothSocketProtocol,
        bind address: Address,
        flags: SocketFlags = [.closeOnExec]
    ) throws -> SocketDescriptor {
        return try self.init(socketProtocol, bind: address, flags: flags)
    }
    
    @usableFromInline
    func setNonblocking(retryOnInterrupt: Bool = true) throws {
        var flags = try getStatus(retryOnInterrupt: retryOnInterrupt)
        flags.insert(.nonBlocking)
        try setStatus(flags, retryOnInterrupt: retryOnInterrupt)
    }
}
