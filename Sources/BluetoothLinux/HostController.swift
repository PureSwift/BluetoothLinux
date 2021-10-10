//
//  HostController.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 12/6/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

#if os(Linux)
import Glibc
#elseif canImport(Darwin)
import Darwin.C
#endif

import Foundation
import CSwiftBluetoothLinux
import BluetoothHCI


/// Manages connection / communication to the underlying Bluetooth hardware.
public final class HostController: BluetoothHostControllerInterface {
    
    public typealias Identifier = UInt16

    // MARK: - Properties
    
    /// The device identifier of the Bluetooth controller.
    public let identifier: Identifier
    
    internal let internalSocket: Socket
    
    // MARK: - Initizalization
    
    /// Attempt to initialize an Bluetooth controller
    public init(identifier: Identifier) throws {
        
        self.identifier = identifier
        self.internalSocket = try Socket(device: identifier)
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

// MARK: - Supporting Types

internal extension HostController {
    
    final class Socket {
        
        internal let fileDescriptor: CInt
        
        deinit {
            close(fileDescriptor)
        }
        
        init() throws {
            let fileDescriptor = socket(AF_BLUETOOTH, SOCK_RAW | SOCK_CLOEXEC, BluetoothSocketProtocol.hci.rawValue)
            guard fileDescriptor >= 0 else { throw POSIXError.fromErrno() }
            self.fileDescriptor = fileDescriptor
        }
        
        convenience init(device: HostController.Identifier) throws {
            try self.init()
            try bind(device)
        }
    }
}

internal extension HostController.Socket {
    
    func bind(_ identifier: HostController.Identifier) throws {
        
        // Bind socket to the HCI device
        var address = HCISocketAddress()
        address.family = sa_family_t(AF_BLUETOOTH)
        address.device = identifier
        try BluetoothLinux.bind(fileDescriptor, &address)
    }
    
    /// Open and initialize HCI device.
    func enable(_ identifier: HostController.Identifier) throws {
        
        guard IOControl(fileDescriptor, HCI.IOCTL.DeviceUp, CInt(identifier)) >= 0
            else { throw POSIXError.fromErrno() }
    }
    
    /// Close the HCI device.
    func disable(_ identifier: HostController.Identifier) throws {
        
        guard IOControl(fileDescriptor, HCI.IOCTL.DeviceDown, CInt(identifier)) >= 0
            else { throw POSIXError.fromErrno() }
    }
    
    /// Get device information.
    func deviceInformation(_ identifier: HostController.Identifier) throws -> HCIDeviceInformation {
        
        var deviceInfo = HCIDeviceInformation()
        deviceInfo.identifier = identifier
        
        guard withUnsafeMutablePointer(to: &deviceInfo, {
            IOControl(fileDescriptor, HCI.IOCTL.GetDeviceInfo, UnsafeMutableRawPointer($0)) == 0 })
            else { throw POSIXError.fromErrno() }
        
        return deviceInfo
    }
    
    /// List all HCI devices.
    func deviceList() throws -> HCIDeviceList {
        
        // allocate HCI device list buffer
        var deviceList = HCIDeviceList()
        deviceList.numberOfDevices = UInt16(HCI.maximumDeviceCount)
        
        // request device list
        guard withUnsafeMutablePointer(to: &deviceList, {
            IOControl(fileDescriptor, HCI.IOCTL.GetDeviceList, $0) >= 0 })
            else { throw POSIXError.fromErrno() }
        
        return deviceList
    }
}

// MARK: - Errors

public extension HostController {
    
    typealias Error = BluetoothHostControllerError
}

// MARK: - HCI Functions

internal func HCIGetRoute(_ address: BluetoothAddress? = nil, _ socket: HostController.Socket) throws -> UInt16? {
    
    let list = try socket.deviceList()
    let device: HCIDeviceListItem?
    if let address = address {
        device = try list.first {
            try socket.deviceInformation($0.identifier).address == address // filter by address
        }
    } else {
        device = list.first
    }
    return device?.identifier
}

internal func bind(_ fileDescriptor: CInt, _ address: inout HCISocketAddress) throws {
    
    let didBind = withUnsafeMutablePointer(to: &address) {
        $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
            bind(fileDescriptor, $0, socklen_t(MemoryLayout<HCISocketAddress>.size)) >= 0
        }
    }
    guard didBind else { throw POSIXError.fromErrno() }
}

// MARK: - Linux Support

#if os(Linux)

    let SOCK_RAW = CInt(Glibc.SOCK_RAW.rawValue)

    let SOCK_CLOEXEC = CInt(Glibc.SOCK_CLOEXEC.rawValue)
    
    typealias sa_family_t = Glibc.sa_family_t

#endif

// MARK: - Darwin Stubs

#if os(macOS) || os(iOS)
var SOCK_CLOEXEC: CInt { stub() }
#endif
