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
        let address = HCISocketAddress(device: id)
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
        
        let socket = try Socket()
        guard let deviceIdentifier = try HCIGetRoute(address, socket)
            else { throw Error.adapterNotFound }
        try socket.bind(deviceIdentifier)
        self.identifier = deviceIdentifier
        self.internalSocket = socket
    }
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

public extension HostController {
    
    private static func requestControllers() throws -> [HostController] {
        
        let socket = try HostController.Socket()
        return try socket.deviceList()
            .sorted { $0.identifier < $1.identifier }
            .compactMap { try? HostController(identifier: $0.identifier) }
    }
    
    static var controllers: [HostController] {
        
        return (try? requestControllers()) ?? []
    }
    
    static var `default`: HostController? {
        
        guard let socket = try? HostController.Socket(),
            let list = try? socket.deviceList(),
            let device = list.first
            else { return nil }
        
        return try? HostController(identifier: device.identifier)
    }
}

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

// MARK: - Errors

public extension HostController {
    
    typealias Error = BluetoothHostControllerError
}
