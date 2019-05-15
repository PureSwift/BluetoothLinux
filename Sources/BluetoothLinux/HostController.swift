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
        
        return try HCIRequestDeviceList { (_, list) in
            return list
                .sorted { $0.identifier < $1.identifier }
                .compactMap { try? HostController(identifier: $0.identifier) }
        }
    }
    
    static var controllers: [HostController] {
        
        return (try? requestControllers()) ?? []
    }
    
    static var `default`: HostController? {
        
        #if swift(>=5.0)
        guard let deviceIdentifier = try? HCIGetRoute(nil)
            else { return nil }
        #else
        guard let result = try? HCIGetRoute(nil),
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
}

// MARK: - Errors

public extension HostController {
    
    typealias Error = BluetoothHostControllerError
}

// MARK: - Internal HCI Functions

internal func HCIRequestDeviceList <T> (_ response: (_ hciSocket: CInt, _ list: inout HCIDeviceList) throws -> T) throws -> T {
    
    // open HCI socket
    let hciSocket = try HostController.Socket()
    
    // allocate HCI device list buffer
    var deviceList = HCIDeviceList()
    deviceList.numberOfDevices = UInt16(HCI.maximumDeviceCount)
    
    // request device list
    let ioctlValue = withUnsafeMutablePointer(to: &deviceList) {
        IOControl(hciSocket.fileDescriptor, HCI.IOCTL.GetDeviceList, $0)
    }
    guard ioctlValue >= 0 else { throw POSIXError.fromErrno() }
    
    return try response(hciSocket.fileDescriptor, &deviceList)
}

/// Iterate availible HCI devices until the handler returns false.
internal func HCIDevicesIterate(_ iterator: (_ socket: CInt, _ deviceRequest: HCIDeviceListItem) throws -> (Bool)) throws {
    
    try HCIRequestDeviceList { (socket, list) in
        
        for item in list {
            
            if try iterator(socket, item) == false {
                
                break
            }
        }
    }
}

internal func HCIIdentifierOfDevice(_ flagFilter: [HCIDeviceFlag] = [], _ predicate: (_ deviceDescriptor: CInt, _ deviceIdentifier: UInt16) throws -> Bool) throws -> UInt16? {
    
    var result: UInt16?
    
    try HCIDevicesIterate { (hciSocket, device) in
        
        for flag in flagFilter {
            guard HCITestBit(flag, device.options)
                else { return true }
        }
        
        let deviceIdentifier = device.identifier
        
        if try predicate(hciSocket, deviceIdentifier) {
            result = deviceIdentifier
            return false
        } else {
            
            return true
        }
    }
    
    return result
}

internal func HCIGetRoute(_ address: BluetoothAddress? = nil) throws -> UInt16? {

    return try HCIIdentifierOfDevice { (dd, deviceIdentifier) in

        guard let address = address else { return true }

        var deviceInfo = HCIDeviceInformation()
        deviceInfo.identifier = UInt16(deviceIdentifier)
        
        guard withUnsafeMutablePointer(to: &deviceInfo, {
            IOControl(CInt(dd), HCI.IOCTL.GetDeviceInfo, UnsafeMutableRawPointer($0)) }) == 0
            else { throw POSIXError.fromErrno() }

        return deviceInfo.address == address
    }
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
