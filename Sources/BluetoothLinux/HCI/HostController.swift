//
//  HostController.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 12/6/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

import Foundation
@_implementationOnly import CBluetoothLinux
import BluetoothHCI
import SystemPackage
import Socket

/// Manages connection / communication to the underlying Bluetooth hardware.
public final class HostController: BluetoothHostControllerInterface {
        
    // MARK: - Properties
    
    /// The device identifier of the Bluetooth controller.
    public let id: ID
    
    /// HCI device name.
    public let name: String
    
    /// Bluetooth device address.
    public let address: BluetoothAddress
    
    /// Internal file descriptor for HCI socket
    @usableFromInline
    internal let socket: Socket
    
    // MARK: - Initizalization
    
    deinit {
        Task(priority: .high) {
            await socket.close()
        }
    }
    
    /// Initialize and open socket.
    private init(
        id: ID,
        name: String,
        address: BluetoothAddress
    ) async throws {
        let socketAddress = HCISocketAddress(
            device: id,
            channel: .raw
        )
        let fileDescriptor = try SocketDescriptor.hci(socketAddress, flags: [.closeOnExec, .nonBlocking])
        self.id = id
        self.name = name
        self.address = address
        self.socket = await Socket(fileDescriptor: fileDescriptor)
    }
    
    /// Attempt to initialize an Bluetooth controller
    public convenience init(id: ID) async throws {
        let deviceInfo = try Self.deviceInformation(for: id)
        try await self.init(id: id, name: deviceInfo.name, address: deviceInfo.address)
    }
    
    /// Initializes the Bluetooth controller with the specified address.
    public convenience init(address: BluetoothAddress) async throws {
        // open socket to query devices with ioctl()`
        let fileDescriptor = try SocketDescriptor.bluetooth(.hci, flags: [.closeOnExec])
        let deviceInfo = try fileDescriptor.closeAfter { () throws -> HostControllerIO.DeviceInformation in
            let deviceList = try fileDescriptor.deviceList()
            for device in deviceList {
                let deviceInfo = try fileDescriptor.deviceInformation(for: device.id)
                guard deviceInfo.address == address else {
                    continue
                }
                return deviceInfo
            }
            throw Errno.noSuchAddressOrDevice
        }
        // initialize with new file descriptor
        try await self.init(id: deviceInfo.id, name: deviceInfo.name, address: deviceInfo.address)
    }
}

internal extension HostController {
    
    static private(set) var cachedControllers = [ID: HostController]()
        
    @usableFromInline
    static func loadDevices() throws -> HostControllerIO.DeviceList {
        let fileDescriptor = try SocketDescriptor.bluetooth(.hci, flags: [.closeOnExec])
        defer { try? fileDescriptor.close() }
        return try fileDescriptor.deviceList()
    }
    
    @discardableResult
    static func reloadControllers() async throws -> [HostController] {
        let cachedDevices = cachedControllers.keys
        // load current devices
        let devices = try loadDevices()
            .lazy
            .map { $0.id }
        // initialize new controllers
        let newDevices = devices
            .filter { cachedDevices.contains($0) == false }
        for id in newDevices {
            do {
                let hostController = try await HostController(id: id)
                cachedControllers[id] = hostController
            }
            catch {
                assertionFailure("Unable to load Bluetooth HCI device \(id.rawValue). \(error)")
                continue
            }
        }
        // remove invalid controllers
        let oldDevices = cachedDevices
            .filter { devices.contains($0) == false }
        for id in oldDevices {
            cachedControllers[id] = nil
        }
        // return sorted array
        return cachedControllers
            .values
            .sorted { $0.id.rawValue < $1.id.rawValue }
    }
}

public extension HostController {
    
    static var controllers: [HostController] {
        get async {
            do {
                return try await reloadControllers()
            }
            catch {
                assertionFailure("Unable to fetch Bluetooth HCI devices. \(error)")
                return []
            }
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
