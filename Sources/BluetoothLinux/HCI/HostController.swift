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
    internal let fileDescriptor: FileDescriptor
    
    // MARK: - Initizalization
    
    /// Attempt to initialize an Bluetooth controller
    public init(id: ID) throws {
        let fileDescriptor = try FileDescriptor.bluetooth(.hci)
        let address = HCISocketAddress(
            device: id,
            channel: .raw
        )
        do {
            try fileDescriptor.bind(address)
        } catch {
            try? fileDescriptor.close()
            throw error
        }
        self.id = id
        self.fileDescriptor = fileDescriptor
    }
    
    /// Initializes the Bluetooth controller with the specified address.
    public init(address: BluetoothAddress) throws {
        #warning("HCIGetRoute()")
        fatalError()
        /*
        guard let deviceIdentifier = try HCIGetRoute(address, socket)
            else { throw Error.adapterNotFound }
        let address = HCISocketAddress(
            device: id,
            channel: .raw
        )
        do {
            try fileDescriptor.bind(address)
        } catch {
            try? fileDescriptor.close()
            throw error
        }
        self.id = id
        self.fileDescriptor = fileDescriptor
        */
    }
}


public extension HostController {
    
    private static func requestControllers() throws -> [HostController] {
        let fileDescriptor = try FileDescriptor.bluetooth(.hci, flags: [.closeOnExec])
        return try fileDescriptor.closeAfter {
            try fileDescriptor.deviceList()
                .lazy
                .sorted { $0.id.rawValue < $1.id.rawValue }
                .compactMap { try? HostController(id: $0.id) }
        }
    }
    
    static var controllers: [HostController] {
        return (try? requestControllers()) ?? []
    }
    
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
/*
public extension HostController {
    
    /// Open and initialize HCI device.
    func enable() throws {
        try internalSocket.enable(identifier)
    }
    
    /// Disable the HCI device.
    func disable() throws {
        try internalSocket.disable(identifier)
    }
    
    /// Get device information.
    func deviceInformation() throws -> HCIDeviceInformation {
        return try internalSocket.deviceInformation(identifier)
    }
}
*/
// MARK: - Supporting Types

public extension HostController {
    
    typealias Error = BluetoothHostControllerError
}

public extension HostController {
    
    @frozen
    struct ID: RawRepresentable, Equatable, Hashable, Codable {
        
        public let rawValue: UInt16
        
        public init(rawValue: UInt16) {
            self.rawValue = rawValue
        }
    }
}

public extension HostController.ID {
    
    static var none: HostController.ID {
        return .init(rawValue: 0xffff)
    }
}
