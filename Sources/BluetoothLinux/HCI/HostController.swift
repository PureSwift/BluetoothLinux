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
import Socket

/// Manages connection / communication to the underlying Bluetooth hardware.
public final class HostController: BluetoothHostControllerInterface {
        
    // MARK: - Properties
    
    /// The device identifier of the Bluetooth controller.
    public let id: ID
    
    /// Internal file descriptor for HCI socket
    @usableFromInline
    internal let socket: Socket
    
    // MARK: - Initizalization
    
    deinit {
        socket.close()
    }
    
    /// Attempt to initialize an Bluetooth controller
    public init(id: ID) async throws {
        let address = HCISocketAddress(
            device: id,
            channel: .raw
        )
        let fileDescriptor = try FileDescriptor.hci(address, flags: [.closeOnExec, .nonBlocking])
        self.id = id
        self.socket = await Socket(fileDescriptor: fileDescriptor)
    }
    
    /// Initializes the Bluetooth controller with the specified address.
    public convenience init(address: BluetoothAddress) async throws {
        // open socket to query devices with ioctl()`
        let fileDescriptor = try FileDescriptor.bluetooth(.hci, flags: [.closeOnExec])
        guard let deviceInfo = try fileDescriptor.closeAfter({
            try fileDescriptor.deviceList().first(where: {
                try fileDescriptor.deviceInformation(for: $0.id).address == address
            })
        }) else { throw Errno.noSuchAddressOrDevice }
        // initialize with new file descriptor
        try await self.init(id: deviceInfo.id)
    }
}

internal extension HostController {
    
    static private(set) var cachedControllers = [ID: HostController]()
        
    @usableFromInline
    static func loadDevices() throws -> HostControllerIO.DeviceList {
        let fileDescriptor = try FileDescriptor.bluetooth(.hci, flags: [.closeOnExec])
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
