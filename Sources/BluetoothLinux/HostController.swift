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
    
    /// The Bluetooth Address of the controller.
    public let address: Address
    
    // MARK: - Internal Properties

    internal let internalSocket: CInt

    // MARK: - Initizalization

    deinit {

        close(internalSocket)
    }
    
    /// Attempt to initialize an controller controller
    public init(identifier: Identifier) throws {
        
        self.identifier = identifier
        self.address = try Address(deviceIdentifier: identifier)
        self.internalSocket = try HCIOpenDevice(identifier)
    }
    
    /// Initializes the Bluetooth controller with the specified address.
    public init(address: Address) throws {
        
        guard let deviceIdentifier = try HCIGetRoute(address)
            else { throw Error.adapterNotFound }
        
        self.identifier = deviceIdentifier
        self.address = address
        self.internalSocket = try HCIOpenDevice(deviceIdentifier)
    }
}

public extension HostController {
    
    private static func requestControllers() throws -> [HostController] {
        
        return try HCIRequestDeviceList { (_, list) in
            
            list.sorted(by: { $0.identifier < $1.identifier })
                .filter { HCITestBit(.up, $0.options) && $0.identifier >= 0 }
                .compactMap { try? HostController(identifier: $0.identifier) }
        }
    }
    
    public static var controllers: [HostController] {
        
        return (try? requestControllers()) ?? []
    }
    
    public static var `default`: HostController? {
        
        guard let result = try? HCIGetRoute(nil),
            let deviceIdentifier = result,
            let controller = try? HostController(identifier: deviceIdentifier)
            else { return nil }
        
        return controller
    }
}

// MARK: - Address Extensions

public extension Address {
    
    /// Extracts the Bluetooth address from the device ID.
    ///
    /// Attempts to get the address from the underlying Bluetooth hardware.
    ///
    /// Fails if the Bluetooth HostController was disconnected or hardware failure.
    public init(deviceIdentifier: HostController.Identifier) throws {
        
        self = try HCIDeviceAddress(deviceIdentifier)
    }
}

// MARK: - Errors

public extension HostController {
    
    public typealias Error = BluetoothHostControllerError
}

// MARK: - Internal HCI Functions

internal func HCIOpenDevice(_ deviceIdentifier: UInt16) throws -> CInt {
    
    // Create HCI socket
    let hciSocket = socket(AF_BLUETOOTH, SOCK_RAW | SOCK_CLOEXEC, BluetoothProtocol.hci.rawValue)
    
    guard hciSocket >= 0 else { throw POSIXError.fromErrno! }
    
    // Bind socket to the HCI device
    var address = HCISocketAddress()
    address.family = sa_family_t(AF_BLUETOOTH)
    address.deviceIdentifier = deviceIdentifier
    
    let didBind = withUnsafeMutablePointer(to: &address) {
        $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
            bind(hciSocket, $0, socklen_t(MemoryLayout<HCISocketAddress>.size)) >= 0
        }
    }
    
    guard didBind else {
        close(hciSocket)
        throw POSIXError.fromErrno!
    }
    
    return hciSocket
}

internal func HCIRequestDeviceList <T> (_ response: (_ hciSocket: CInt, _ list: inout HCIDeviceList) throws -> T) throws -> T {
    
    // open HCI socket
    let hciSocket = socket(AF_BLUETOOTH, SOCK_RAW | SOCK_CLOEXEC, BluetoothProtocol.hci.rawValue)
    
    guard hciSocket >= 0 else { throw POSIXError.fromErrno! }
    
    defer { close(hciSocket) }
    
    // allocate HCI device list buffer
    var deviceList = HCIDeviceList()
    deviceList.numberOfDevices = UInt16(HCI.maximumDeviceCount)
    
    // request device list
    let ioctlValue = withUnsafeMutablePointer(to: &deviceList) {
        IOControl(hciSocket, HCI.IOCTL.GetDeviceList, $0)
    }
    
    guard ioctlValue >= 0 else { throw POSIXError.fromErrno! }
    
    return try response(hciSocket, &deviceList)
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

internal func HCIIdentifierOfDevice(_ flagFilter: HCIDeviceFlag = HCIDeviceFlag(), _ predicate: (_ deviceDescriptor: CInt, _ deviceIdentifier: UInt16) throws -> Bool) throws -> UInt16? {
    
    var result: UInt16?
    
    try HCIDevicesIterate { (hciSocket, device) in
        
        guard HCITestBit(flagFilter, device.options) else { return true }
        
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

internal func HCIGetRoute(_ address: Address? = nil) throws -> UInt16? {

    return try HCIIdentifierOfDevice { (dd, deviceIdentifier) in

        guard let address = address else { return true }

        var deviceInfo = HCIDeviceInformation()

        deviceInfo.identifier = UInt16(deviceIdentifier)

        guard withUnsafeMutablePointer(to: &deviceInfo, {
            IOControl(CInt(dd), HCI.IOCTL.GetDeviceInfo, UnsafeMutableRawPointer($0)) }) == 0
            else { throw POSIXError.fromErrno! }

        return deviceInfo.address == address
    }
}

internal func HCIDeviceInfo(_ deviceIdentifier: UInt16) throws -> HCIDeviceInformation {
    
    // open HCI socket
    
    let hciSocket = socket(AF_BLUETOOTH, SOCK_RAW | SOCK_CLOEXEC, BluetoothProtocol.hci.rawValue)
    
    guard hciSocket >= 0 else { throw POSIXError.fromErrno! }
    
    defer { close(hciSocket) }
    
    var deviceInfo = HCIDeviceInformation()
    deviceInfo.identifier = deviceIdentifier
    
    guard withUnsafeMutablePointer(to: &deviceInfo, {
        IOControl(hciSocket, HCI.IOCTL.GetDeviceInfo, UnsafeMutableRawPointer($0)) }) == 0
        else { throw POSIXError.fromErrno! }
    
    return deviceInfo
}

internal func HCIDeviceAddress(_ deviceIdentifier: UInt16) throws -> Address {
    
    let deviceInfo = try HCIDeviceInfo(deviceIdentifier)
    
    guard HCITestBit(HCI.DeviceFlag.up, deviceInfo.flags)
        else { throw POSIXError(code: .ENETDOWN) }
    
    return deviceInfo.address
}

@inline (__always)
internal func HCITestBit(_ flag: CInt,  _ options: UInt32) -> Bool {

    return (options + (UInt32(bitPattern: flag) >> 5)) & (1 << (UInt32(bitPattern: flag) & 31)) != 0
}

@inline (__always)
internal func HCITestBit(_ flag: HCI.DeviceFlag, _ options: UInt32) -> Bool {
    
    return HCITestBit(flag.rawValue, options)
}

// MARK: - Linux Support

#if os(Linux)

    let SOCK_RAW = CInt(Glibc.SOCK_RAW.rawValue)

    let SOCK_CLOEXEC = CInt(Glibc.SOCK_CLOEXEC.rawValue)
    
    typealias sa_family_t = Glibc.sa_family_t

#endif

// MARK: - Darwin Stubs

#if os(OSX) || os(iOS)

    var SOCK_CLOEXEC: CInt { stub() }
    
#endif
