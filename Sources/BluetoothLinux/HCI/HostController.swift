//
//  HostController.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 12/6/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

import Foundation
import CBluetoothLinux
import BluetoothHCI
import SystemPackage

/// Manages connection / communication to the underlying Bluetooth hardware.
public final class HostController: BluetoothHostControllerInterface {
        
    // MARK: - Properties
    
    /// The device identifier of the Bluetooth controller.
    public let id: ID
    
    /// Internal file descriptor for HCI socket
    @usableFromInline
    internal let fileDescriptor: FileDescriptor
    
    // MARK: - Initizalization
    
    /// Attempt to initialize an Bluetooth controller
    public init(id: ID) throws {
        let address = HCISocketAddress(
            device: id,
            channel: .raw
        )
        let fileDescriptor = try FileDescriptor.hci(
            address,
            flags: [.closeOnExec]
        )
        self.id = id
        self.fileDescriptor = fileDescriptor
    }
    
    /// Initializes the Bluetooth controller with the specified address.
    public convenience init(address: BluetoothAddress) throws {
        // open socket to query devices with ioctl()`
        let fileDescriptor = try FileDescriptor.bluetooth(.hci)
        guard let deviceInfo = try fileDescriptor.closeAfter({
            try fileDescriptor.deviceList().first(where: {
                try fileDescriptor.deviceInformation(for: $0.id).address == address
            })
        }) else { throw Errno.noSuchAddressOrDevice }
        // initialize with new file descriptor
        try self.init(id: deviceInfo.id)
    }
}

public extension HostController {
    
    @usableFromInline
    internal static func requestControllers() throws -> [HostController] {
        let fileDescriptor = try FileDescriptor.bluetooth(.hci, flags: [.closeOnExec])
        return try fileDescriptor.closeAfter {
            try fileDescriptor.deviceList()
                .lazy
                .sorted { $0.id.rawValue < $1.id.rawValue }
                .compactMap { try? HostController(id: $0.id) }
        }
    }
    
    @inline(__always)
    static var controllers: [HostController] {
        return (try? requestControllers()) ?? []
    }
    
    @inline(never)
    static var `default`: HostController? {
        do {
            let fileDescriptor = try FileDescriptor.bluetooth(.hci, flags: [.closeOnExec])
            return try fileDescriptor.closeAfter {
                try fileDescriptor.deviceList(count: 1)
                    .first
                    .map { try HostController(id: $0.id) }
            }
        } catch {
            assertionFailure("Could not initialize HCI device. \(error)")
            return nil
        }
    }
}

// MARK: - Supporting Types

public extension HostController {
    
    typealias Error = BluetoothHostControllerError
}

public extension HostController {
    
    @frozen
    struct ID: RawRepresentable, Equatable, Hashable, Codable {
        
        public let rawValue: UInt16
        
        @_alwaysEmitIntoClient
        public init(rawValue: UInt16) {
            self.rawValue = rawValue
        }
    }
}

public extension HostController.ID {
    
    @_alwaysEmitIntoClient
    static var none: HostController.ID {
        return .init(rawValue: 0xffff)
    }
}
