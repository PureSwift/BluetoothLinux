//
//  HostController.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 12/6/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

#if os(Linux)
    import Glibc
#elseif os(macOS) || os(iOS)
    import Darwin.C
#endif

import CSwiftBluetoothLinux
import Bluetooth
import Foundation

/// Manages connection / communication to the underlying Bluetooth hardware.
public final class HostController: BluetoothHostControllerInterface {
    
    public typealias Identifier = UInt16

    // MARK: - Properties
    
    /// The device identifier of the Bluetooth controller.
    public let identifier: Identifier
    
    internal let internalSocket: Socket
    
    // MARK: - Initizalization
    
    /// Attempt to initialize an controller controller
    public init(identifier: Identifier) throws {
        
        self.identifier = identifier
        self.internalSocket = try Socket(device: identifier)
    }
    
    /// Initializes the Bluetooth controller with the specified address.
    public init(address: BluetoothAddress) throws {
        
        guard let deviceIdentifier = try HCIGetRoute(address)
            else { throw Error.adapterNotFound }
        
        self.identifier = deviceIdentifier
        self.internalSocket = try Socket(device: deviceIdentifier)
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
        
        guard let socket = try? HostController.Socket()
            else { return nil }
        
        #if swift(>=5.0)
        guard let deviceIdentifier = try? HCIGetRoute(nil, socket)
            else { return nil }
        #else
        guard let result = try? HCIGetRoute(nil, socket),
            let deviceIdentifier = result
            else { return nil }
        #endif
        
        return try? HostController(identifier: deviceIdentifier)
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
            
            let fileDescriptor = socket(AF_BLUETOOTH, SOCK_RAW | SOCK_CLOEXEC, BluetoothProtocol.hci.rawValue)
            guard fileDescriptor >= 0 else { throw POSIXError.fromErrno() }
            self.fileDescriptor = fileDescriptor
        }
        
        convenience init(device: HostController.Identifier) throws {
            
            try self.init()
            
            // Bind socket to the HCI device
            var address = HCISocketAddress()
            address.family = sa_family_t(AF_BLUETOOTH)
            address.deviceIdentifier = device
            
            let didBind = withUnsafeMutablePointer(to: &address) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    bind(fileDescriptor, $0, socklen_t(MemoryLayout<HCISocketAddress>.size)) >= 0
                }
            }
            guard didBind else { throw POSIXError.fromErrno() }
        }
    }
}

internal extension HostController.Socket {
    
    /// Open and initialize HCI device.
    func enable(_ identifier: HostController.Identifier) throws {
        
        guard IOControl(fileDescriptor, HCI.IOCTL.DeviceUp, CInt(identifier)) >= 0
            else { throw POSIXError.fromErrno() }
    }
    
    /// Get device information.
    func deviceInformation(_ identifier: HostController.Identifier) throws -> HCIDeviceInformation {
        
        var deviceInfo = HCIDeviceInformation()
        deviceInfo.identifier = identifier
        
        guard withUnsafeMutablePointer(to: &deviceInfo, {
            IOControl(fileDescriptor, HCI.IOCTL.GetDeviceInfo, UnsafeMutableRawPointer($0)) }) == 0
            else { throw POSIXError.fromErrno() }
        
        return deviceInfo
    }
    
    func deviceList() throws -> HCIDeviceList {
        
        // allocate HCI device list buffer
        var deviceList = HCIDeviceList()
        deviceList.numberOfDevices = UInt16(HCI.maximumDeviceCount)
        
        // request device list
        let ioctlValue = withUnsafeMutablePointer(to: &deviceList) {
            IOControl(fileDescriptor, HCI.IOCTL.GetDeviceList, $0)
        }
        guard ioctlValue >= 0 else { throw POSIXError.fromErrno() }
        
        return deviceList
    }
}

// MARK: - Errors

public extension HostController {
    
    typealias Error = BluetoothHostControllerError
}

// MARK: - HCI Functions

internal func HCIGetRoute(_ address: BluetoothAddress? = nil) throws -> UInt16? {
    
    let socket = try HostController.Socket()
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
